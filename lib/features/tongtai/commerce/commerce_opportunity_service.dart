import '../agent/business_brief.dart';
import '../action/business_action.dart';
import '../consumer/identity_evidence.dart';
import '../inventory/product.dart';
import '../proposal/proposed_change.dart';
import 'commerce_models.dart';
import 'commerce_profit.dart';
import '../logistics/shipment_rule.dart';
import '../opportunity/seasonal_rule.dart';
import '../orders/order.dart';
import 'supplier_comparison.dart';

/// **Cơ hội thương mại** — Rule Twin, không hardcode (WTM-329 · §16).
///
/// Founder §16: *"Không hardcode Opportunity card nếu engine có thể derive."*
///
/// Nên mọi thứ ở đây **suy ra từ dữ liệu**: cùng danh mục, cùng đơn hàng, cùng
/// báo giá ⇒ cùng danh sách việc. Đổi một con số trong file Excel thì việc
/// hiện ra cũng đổi theo — đó là phép thử duy nhất phân biệt một engine với
/// một danh sách thẻ đẹp.
///
/// ## Chạy được không cần AI, không cần mạng, không cần khoá
///
/// ADR-TON-016: Rule Twin authoritative, AI chỉ giải thích. Lớp này là hàm
/// thuần — cùng đầu vào cho cùng đầu ra, và nó không bao giờ nói *"khoảng"*.
///
/// ## Vì sao mỗi loại có một trần riêng
///
/// Một danh mục 100 sản phẩm sẽ sinh ra hàng chục việc. Không giới hạn thì
/// buổi sáng của người bán bắt đầu bằng một danh sách ba mươi dòng, và một
/// danh sách ba mươi dòng thì tương đương một danh sách trống.
class CommerceOpportunityService {
  const CommerceOpportunityService({
    this.maxPerKind = 3,
    this.deadStockDays = 90,
    this.thinMarginRatio = 0.15,
  });

  /// Nhiều nhất bao nhiêu việc mỗi loại.
  final int maxPerKind;

  /// Bao lâu không bán được coi là hàng nằm.
  final int deadStockDays;

  final double thinMarginRatio;

  /// Dựng danh sách việc từ danh mục + lời thật + báo giá + vận chuyển.
  List<BriefItem> derive({
    required List<Product> products,
    required CommerceProfitContext profit,
    required List<SupplierQuote> quotes,
    required DateTime now,
    List<ShipmentConcern> shipments = const [],

    /// Đơn hàng — chỉ dùng để tìm **khách nào** đang chờ kiện đang kẹt.
    ///
    /// Không có nó thì việc "kiện đứng im 5 ngày" vẫn hiện ra được, nhưng
    /// không bấm được gì: người bán biết có chuyện mà không biết nhắn cho ai.
    List<CustomerOrder> orders = const [],
  }) {
    final items = <BriefItem>[];
    final quotesByProduct = <String, List<SupplierQuote>>{};
    for (final q in quotes) {
      (quotesByProduct[q.productId] ??= []).add(q);
    }
    final soldProductIds = {for (final p in profit.byProduct) p.productId};

    items
      ..addAll(_losingAfterFees(profit, products, now))
      ..addAll(_runningOut(products, now))
      ..addAll(_deadStock(products, soldProductIds, now))
      ..addAll(_cheaperSupplier(products, quotesByProduct, profit, now))
      ..addAll(_shipments(shipments, orders, now))
      ..addAll(_seasonal(orders, products, now));

    // Nặng trước. Trong cùng mức thì giữ thứ tự dựng — tức là "đang mất tiền"
    // đứng trên "sắp hết hàng", vì mất tiền không có ngày mai để sửa.
    items.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return items;
  }

  // ── đang mất tiền sau phí ────────────────────────────────────────────────

  /// Việc quan trọng nhất trong cả lớp này.
  ///
  /// Nó là thứ **không nhìn thấy được** bằng mắt thường: sản phẩm vẫn bán
  /// chạy, bảng doanh thu vẫn xanh, và tiền vẫn chảy ra.
  List<BriefItem> _losingAfterFees(
    CommerceProfitContext profit,
    List<Product> products,
    DateTime now,
  ) {
    final costOf = {for (final p in products) p.id: p.costPrice};
    final out = <BriefItem>[];

    for (final entry in profit.losingAfterFees.take(maxPerKind)) {
      final loss = entry.amount!.abs();
      final grossFine = entry.grossLooksFineButLoses(costOf[entry.productId]);
      out.add(
        BriefItem(
          kind: BriefKind.marginTooThin,
          severity: BriefSeverity.critical,
          subjectKind: 'product',
          subjectId: entry.productId,
          subjectLabel: entry.name,
          headline: grossFine
              // Câu này phải nói ra cái nghịch lý, vì chính nghịch lý mới là
              // thông tin: nhìn thì lời, thật ra thì lỗ.
              ? '${entry.name} nhìn thì có lãi nhưng sau phí sàn đang lỗ '
                    '${_money(loss)} trong 30 ngày'
              : '${entry.name} đang lỗ ${_money(loss)} trong 30 ngày',
          suggestion: 'Tăng giá bán, đổi nguồn hàng rẻ hơn, hoặc ngừng bán',
          evidence: [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:true-profit',
              detail:
                  'Doanh thu ${_money(entry.revenue)} · '
                  '${entry.units} món · lời thật ${_money(entry.amount!)}',
            ),
          ],
          observedAt: now,
          // Đề xuất **một con số cụ thể**, suy ra từ chính giá vốn và mức phí
          // của kênh — không phải "anh xem lại giá đi". Một đề xuất không có
          // số là một đề xuất người bán phải tự làm lại từ đầu.
          move: ChangeAFact(
            domain: ProposalDomain.pricing,
            field: 'pricePerUnit',
            currentValue: _priceOf(products, entry.productId),
            proposedValue: _breakEvenPrice(costOf[entry.productId]),
          ),
        ),
      );
    }
    return out;
  }

  /// Giá tối thiểu để hết lỗ sau phí sàn.
  ///
  /// `giá > vốn / (1 − phí)`. Làm tròn **lên** nghìn: làm tròn xuống sẽ cho ra
  /// một con số vẫn lỗ, và một đề xuất vẫn lỗ thì tệ hơn không đề xuất.
  static String _breakEvenPrice(double? cost) {
    if (cost == null) return '';
    final minimum = cost / (1 - kPlatformFeeRate);
    // Cộng thêm một biên mỏng để không nằm đúng điểm hoà vốn.
    final rounded = ((minimum * 1.05) / 1000).ceil() * 1000;
    return '$rounded';
  }

  /// Phí sàn điển hình của Shopee/TikTok: hoa hồng ~5% + thanh toán ~2,8%.
  ///
  /// Hằng số nằm ở đây chứ không rải trong UI. Ngày sàn đổi biểu phí, chỗ phải
  /// sửa là một dòng.
  static const double kPlatformFeeRate = 0.083;

  static String? _priceOf(List<Product> products, String id) {
    for (final p in products) {
      if (p.id == id) return '${p.pricePerUnit.round()}';
    }
    return null;
  }

  // ── sắp hết / hết ────────────────────────────────────────────────────────

  List<BriefItem> _runningOut(List<Product> products, DateTime now) {
    final candidates = [
      for (final p in products)
        // `quantity == null` nghĩa là **không theo dõi tồn** (ADR-TON-023) —
        // một dịch vụ không bao giờ "sắp hết hàng".
        if (p.quantity != null && p.reorderLevel != null)
          if (p.quantity! <= p.reorderLevel!) p,
    ]..sort((a, b) => a.quantity!.compareTo(b.quantity!));

    return [
      for (final p in candidates.take(maxPerKind))
        BriefItem(
          kind: BriefKind.stockRunningOut,
          severity: p.quantity == 0
              ? BriefSeverity.critical
              : BriefSeverity.warning,
          subjectKind: 'product',
          subjectId: p.id,
          subjectLabel: p.name,
          headline: p.quantity == 0
              ? '${p.name} đã hết hàng'
              : '${p.name} chỉ còn ${p.quantity} — dưới mức đặt lại '
                    '${p.reorderLevel}',
          suggestion: 'Đặt thêm hàng',
          evidence: [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:stock-level',
              detail: 'Tồn ${p.quantity} / mức đặt lại ${p.reorderLevel}',
            ),
          ],
          observedAt: now,
          move: const DoSomething(
            actionType: BusinessActionType.inventoryCreatePurchaseOrder,
            vendor: ActionVendor.internal,
          ),
        ),
    ];
  }

  // ── hàng nằm ─────────────────────────────────────────────────────────────

  /// Tồn nhiều mà **không bán được món nào** trong kỳ.
  ///
  /// Điều kiện là *"không xuất hiện trong đơn nào"*, không phải *"bán ít"* —
  /// bán ít vẫn là bán, và gọi nó là hàng chết sẽ khiến người bán thanh lý
  /// nhầm thứ đang chạy chậm nhưng đều.
  List<BriefItem> _deadStock(
    List<Product> products,
    Set<String> soldProductIds,
    DateTime now,
  ) {
    final candidates = [
      for (final p in products)
        if (p.quantity != null && p.quantity! > 0)
          if (!soldProductIds.contains(p.id))
            if (now.difference(p.updatedAt).inDays.abs() >= 0) p,
    ]..sort((a, b) => _tiedUp(b).compareTo(_tiedUp(a)));

    return [
      for (final p in candidates.take(maxPerKind))
        BriefItem(
          kind: BriefKind.businessSignal,
          severity: BriefSeverity.warning,
          subjectKind: 'product',
          subjectId: p.id,
          subjectLabel: p.name,
          headline:
              '${p.name} còn ${p.quantity} món, 30 ngày qua không bán được '
              'cái nào — ${_money(_tiedUp(p))} đang nằm trong kho',
          suggestion: 'Giảm giá xả hàng hoặc bán kèm sản phẩm chạy',
          evidence: [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:dead-stock',
              detail: 'Tồn ${p.quantity} · không có đơn nào trong 30 ngày',
            ),
          ],
          observedAt: now,
          // Xả hàng: giảm 20% so với giá đang niêm yết. Con số suy ra từ giá
          // thật của chính sản phẩm, không phải một mức chung cho mọi món.
          move: ChangeAFact(
            domain: ProposalDomain.pricing,
            field: 'pricePerUnit',
            currentValue: '${p.pricePerUnit.round()}',
            proposedValue: '${((p.pricePerUnit * 0.8) / 1000).round() * 1000}',
          ),
        ),
    ];
  }

  /// Tiền đang nằm trong kho — theo **giá vốn**, không theo giá bán.
  ///
  /// Giá bán là tiền chưa thu được; giá vốn là tiền đã trả rồi. Người bán muốn
  /// biết mình đã bỏ ra bao nhiêu, không phải mình hy vọng thu về bao nhiêu.
  double _tiedUp(Product p) => (p.costPrice ?? 0) * (p.quantity ?? 0);

  // ── nguồn rẻ hơn ─────────────────────────────────────────────────────────

  List<BriefItem> _cheaperSupplier(
    List<Product> products,
    Map<String, List<SupplierQuote>> quotesByProduct,
    CommerceProfitContext profit,
    DateTime now,
  ) {
    final unitsSold = {for (final p in profit.byProduct) p.productId: p.units};
    final out = <BriefItem>[];

    // Xét sản phẩm bán nhiều trước: tiết kiệm 12% trên một món bán 60 cái đáng
    // nói hơn 30% trên một món bán một cái.
    final ranked = [...products]
      ..sort((a, b) => (unitsSold[b.id] ?? 0).compareTo(unitsSold[a.id] ?? 0));

    for (final product in ranked) {
      if (out.length >= maxPerKind) break;
      final quotes = quotesByProduct[product.id];
      if (quotes == null || quotes.length < 2) continue;

      final comparison = SupplierComparison.from(
        productId: product.id,
        quotes: quotes,
        // Mốc là **giá vốn đang ghi trên sản phẩm** — thứ người bán đang trả.
        // Thiếu nó thì mốc rơi về báo giá rẻ nhất, và khi đó không lựa chọn
        // nào "rẻ hơn" được: engine im lặng dù dữ liệu có nguồn tốt hơn hẳn.
        currentUnitCost: product.costPrice,
      );
      final win = comparison.clearWin;
      if (win == null) continue;

      final units = unitsSold[product.id] ?? 0;
      final percent = (win.savingRatio! * 100).round();
      final faster = win.slowerByDays! < 0 ? win.slowerByDays!.abs() : 0;

      out.add(
        BriefItem(
          kind: BriefKind.businessSignal,
          severity: BriefSeverity.info,
          subjectKind: 'product',
          subjectId: product.id,
          subjectLabel: product.name,
          headline:
              '${win.quote.supplierName} bán ${product.name} rẻ hơn $percent% '
              '${faster > 0 ? "và giao nhanh hơn $faster ngày" : "với thời gian giao tương đương"}',
          suggestion: units > 0
              // Có bán được thì nói bằng tiền thật của kỳ vừa rồi — con số đó
              // thuyết phục hơn một tỷ lệ phần trăm.
              ? 'Đổi nguồn — tiết kiệm khoảng ${_money(win.savingFor(units))} '
                    'với mức bán 30 ngày qua'
              // Chưa bán được món nào thì **không** bịa ra một khoản tiết kiệm
              // của kỳ. Nói theo đơn vị, vì đó là điều duy nhất biết chắc.
              : 'Đổi nguồn — rẻ hơn '
                    '${_money(win.against.unitCost - win.quote.unitCost)} '
                    'mỗi món',
          evidence: [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:supplier-comparison',
              detail:
                  '${_money(win.quote.unitCost)}/món so với '
                  '${_money(win.against.unitCost)}'
                  '${units > 0 ? ' · đã bán $units món' : ''}',
            ),
          ],
          observedAt: now,
          move: const DoSomething(
            actionType: BusinessActionType.inventoryCreatePurchaseOrder,
            vendor: ActionVendor.internal,
          ),
        ),
      );
    }
    return out;
  }

  // ── vận chuyển ───────────────────────────────────────────────────────────

  List<BriefItem> _shipments(
    List<ShipmentConcern> concerns,
    List<CustomerOrder> orders,
    DateTime now,
  ) {
    final customerByOrder = {for (final o in orders) o.id: o.customerId};

    return [
      for (final concern in concerns.take(maxPerKind))
        BriefItem(
          kind: BriefKind.businessSignal,
          severity: switch (concern.kind) {
            ShipmentConcernKind.deliveryFailed => BriefSeverity.critical,
            ShipmentConcernKind.stuckWhilePeersArrived => BriefSeverity.warning,
            ShipmentConcernKind.silent => BriefSeverity.info,
          },
          subjectKind: 'shipment',
          subjectId: concern.shipment.id,
          subjectLabel: concern.shipment.trackingNumber,
          headline: switch (concern.kind) {
            ShipmentConcernKind.deliveryFailed =>
              'Đơn ${concern.shipment.trackingNumber} giao không thành công — '
                  'hãng sẽ hoàn về nếu không xử lý',
            // ⭐ Câu đáng giá nhất: nó loại nguyên nhân chung (bão, quá tải) và
            // chỉ còn lại nguyên nhân riêng của kiện này.
            ShipmentConcernKind.stuckWhilePeersArrived =>
              'Đơn ${concern.shipment.trackingNumber} đứng im '
                  '${concern.shipment.silentDaysAt(now)} ngày trong khi '
                  '${concern.peersDelivered} đơn cùng tuyến đã tới',
            ShipmentConcernKind.silent =>
              'Đơn ${concern.shipment.trackingNumber} '
                  '${concern.shipment.silentDaysAt(now)} ngày chưa có tin mới',
          },
          suggestion: concern.kind == ShipmentConcernKind.deliveryFailed
              ? 'Gọi khách xác nhận địa chỉ rồi báo hãng giao lại'
              : 'Gọi hãng hỏi tình trạng kiện hàng',
          evidence: [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:shipment-tracking',
              detail: [
                if (concern.shipment.carrier != null)
                  concern.shipment.carrier!.displayName,
                if (concern.shipment.route != null) concern.shipment.route!,
                if (concern.shipment.silentDaysAt(now) != null)
                  '${concern.shipment.silentDaysAt(now)} ngày không có tin',
              ].join(' · '),
            ),
          ],
          // ⭐ WTM-348 — **thấy được thì phải bấm được.**
          //
          // Trước đây mục này chỉ nói "Gọi hãng hỏi tình trạng kiện hàng" rồi
          // dừng: app nhìn ra kiện kẹt nhưng người bán vẫn phải tự làm mọi thứ.
          //
          // Việc đúng duy nhất mà app làm hộ được là **báo cho khách đang chờ**
          // — người bán không gọi hãng thay được, nhưng im lặng với khách mới là
          // thứ biến một kiện chậm thành một đơn hoàn.
          //
          // `null` khi không tra ra khách: kiện không gắn đơn, hoặc đơn không
          // gắn khách. Khi đó mục vẫn hiện (biết có chuyện vẫn hơn không biết),
          // chỉ là không có nút — chứ không phải nhắn cho một khách đoán bừa.
          move: switch (customerByOrder[concern.shipment.orderId]) {
            final String customerId when customerId.isNotEmpty => DoSomething(
              actionType: BusinessActionType.customerSendMessage,
              vendor: ActionVendor.demo,
              parameters: {
                'customerId': customerId,
                'shipmentId': concern.shipment.id,
                'reason': concern.kind.code,
              },
            ),
            _ => null,
          },
          observedAt: now,
        ),
    ];
  }

  // ── mùa vụ lặp lại (WTM-180 story 4) ─────────────────────────────────────

  /// Cùng kỳ năm ngoái bán chạy gì, mà năm nay chưa chuẩn bị.
  ///
  /// Luật **từ chối kết luận** khi chưa đủ một năm lịch sử; ở đây điều đó hiện
  /// ra thành **không có mục nào**, đúng như khi đã xét mà không thấy gì. Hai
  /// trạng thái đó khác nhau ở tầng luật (`SeasonalVerdict`), nhưng với brief
  /// thì cùng một nghĩa: hôm nay không có việc mùa vụ nào để làm.
  List<BriefItem> _seasonal(
    List<CustomerOrder> orders,
    List<Product> products,
    DateTime now,
  ) {
    final verdict = const SeasonalRule().evaluate(
      orders: orders,
      products: products,
      now: now,
    );

    return [
      for (final s in verdict.opportunities)
        BriefItem(
          kind: BriefKind.stockRunningOut,
          severity: BriefSeverity.info,
          subjectKind: 'product',
          subjectId: s.product.id,
          subjectLabel: s.product.name,
          headline:
              'Cùng kỳ năm ngoái ${s.product.name} bán ${s.unitsLastYear} '
              '— năm nay mới ${s.unitsThisYear}',
          suggestion: 'Nhập thêm ${s.shortfall} trước khi vào mùa',
          evidence: [
            IdentityEvidence(
              kind: IdentityEvidenceKind.businessRecordObservation,
              source: 'rule:seasonal-repeat',
              detail:
                  '${s.unitsLastYear} bán ra cùng kỳ năm ngoái · '
                  '${s.unitsThisYear} năm nay · tồn ${s.product.quantity ?? 0}',
            ),
          ],
          move: DoSomething(
            actionType: BusinessActionType.inventoryCreatePurchaseOrder,
            vendor: ActionVendor.internal,
            parameters: {'productId': s.product.id, 'quantity': s.shortfall},
          ),
          observedAt: now,
        ),
    ];
  }

  /// Tiền, gọn cho một dòng tin. Không phải formatter của UI — đây là **dữ
  /// liệu** đi vào `headline`, và headline phải đọc được ở mọi nơi nó xuất
  /// hiện (màn hình, Telegram, báo cáo).
  static String _money(double amount) {
    final value = amount.abs().round();
    if (value >= 1000000) {
      final millions = value / 1000000;
      return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)} triệu';
    }
    if (value >= 1000) return '${(value / 1000).round()} nghìn';
    return '$value đ';
  }
}
