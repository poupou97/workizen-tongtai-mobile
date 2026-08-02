import 'package:flutter/foundation.dart';

import 'product_history.dart';

/// Stock-level health of a product, derived from on-hand quantity against its
/// reorder threshold (WTM-68 AC: color-coded in stock / low / out).
///
/// Kept as a domain enum (no colors here) so it stays UI-agnostic and
/// unit-testable; the screen maps it to a color + label.
enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get labelEn => switch (this) {
    StockStatus.inStock => 'In stock',
    StockStatus.lowStock => 'Low stock',
    StockStatus.outOfStock => 'Out of stock',
  };

  String get labelVi => switch (this) {
    StockStatus.inStock => 'Còn hàng',
    StockStatus.lowStock => 'Sắp hết hàng',
    StockStatus.outOfStock => 'Hết hàng',
  };

  /// Label for a language code ('vi' -> Vietnamese, otherwise English).
  String label(String languageCode) => languageCode == 'vi' ? labelVi : labelEn;
}

/// What kind of thing the seller sells (ADR-TON-023).
///
/// Tổng Tài is an AI Business OS for SMEs of every shape — physical, digital,
/// service and hybrid — so the model must be able to say *"this has no stock"*
/// instead of making a software product carry a quantity it does not have.
/// Dogfood found the cost of not having this: a digital product entered with
/// `quantity: 0` made Inventory shout "Hết hàng" and the Rule Engine generate
/// a **restock opportunity for a piece of software**.
enum ProductKind {
  /// Có tồn kho thật: nhập, đếm, hết hàng được.
  physical('physical'),

  /// Bán bao nhiêu lần cũng được — phần mềm, khoá học, tệp tải về.
  digital('digital'),

  /// Bán thời gian hoặc năng lực, không phải một vật.
  service('service');

  const ProductKind(this.code);

  /// Mã lưu xuống DB và `.ttbk`. **Không bao giờ là nhãn hiển thị.**
  final String code;

  /// Chỉ loại này mới có khái niệm tồn kho.
  bool get tracksStock => this == ProductKind.physical;

  /// `null`/mã lạ ⇒ `physical`: mọi dòng có trước ADR-TON-023 đều được nhập
  /// dưới mô hình chỉ-có-hàng-vật-lý, nên đó là **sự thật về chúng**, không
  /// phải một phỏng đoán.
  static ProductKind fromCode(String? code) {
    for (final k in ProductKind.values) {
      if (k.code == code) return k;
    }
    return ProductKind.physical;
  }
}

/// A product in the sourcing inventory (WTM-68).
///
/// Pure, immutable domain model — no Flutter/UI or persistence concerns — so it
/// is trivially unit-testable and reusable by the inventory service, screens and
/// (later) any Drift-backed repository.
@immutable
class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    this.kind = ProductKind.physical,
    this.quantity,
    this.reorderLevel,
    required this.updatedAt,
    this.costPrice,
    this.description = '',
    this.imagePaths = const [],
    this.history = const [],
  });

  /// Stable identifier.
  final String id;

  /// Stock-keeping unit code, e.g. "SKU-EL-001".
  final String sku;

  /// Display name, e.g. "Quạt mini cầm tay".
  final String name;

  /// Product category, e.g. "Electronics".
  final String category;

  /// On-hand quantity, in units.
  /// Loại sản phẩm (ADR-TON-023). Mặc định `physical` để mọi dòng cũ giữ đúng
  /// ý nghĩa chúng vẫn có.
  final ProductKind kind;

  /// Số lượng đang có — **`null` nghĩa là "không áp dụng cho loại này"**, KHÔNG
  /// phải "hết hàng". Cùng kỷ luật với `costPrice` (null ≠ 0, WTM-204) và
  /// `paymentStatus` (null ≠ chưa trả, WTM-211).
  final int? quantity;

  /// Price per unit, in Vietnamese đồng.
  final double pricePerUnit;

  /// Low-stock threshold, in units: at or below this (but above zero) the
  /// product is flagged [StockStatus.lowStock].
  /// Ngưỡng đặt lại — `null` khi loại sản phẩm không có tồn kho.
  final int? reorderLevel;

  /// When the product's stock/price was last updated.
  final DateTime updatedAt;

  /// Long-form product description. Supports markdown formatting (WTM-69 AC3).
  /// Defaults to empty so existing catalog data stays valid.
  final String description;

  /// Local file paths of product photos, uploaded or camera-captured
  /// (WTM-69 AC2). Empty by default.
  final List<String> imagePaths;

  /// Chronological edit history, most-recent revision first (WTM-69 AC4). Empty
  /// for a product that has never been edited.
  final List<ProductRevision> history;

  /// Copy with individual field overrides. Used by the Add/Edit form to produce
  /// an updated product (WTM-69) without mutating the original.
  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? category,
    int? quantity,
    double? pricePerUnit,
    int? reorderLevel,
    DateTime? updatedAt,
    double? costPrice,
    String? description,
    List<String>? imagePaths,
    List<ProductRevision>? history,
    ProductKind? kind,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      kind: kind ?? this.kind,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      updatedAt: updatedAt ?? this.updatedAt,
      costPrice: costPrice ?? this.costPrice,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      history: history ?? this.history,
    );
  }

  /// Stock health derived from [quantity] vs. [reorderLevel] — or **`null`
  /// when the concept does not apply** (ADR-TON-023).
  ///
  /// A digital product is never "out of stock"; returning
  /// [StockStatus.outOfStock] for one would be the app stating something
  /// untrue about the seller's business, and the alert engine would act on it.
  StockStatus? get stockStatus {
    if (!kind.tracksStock) return null;
    final onHand = quantity ?? 0;
    if (onHand <= 0) return StockStatus.outOfStock;
    if (onHand <= (reorderLevel ?? 0)) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  /// What one unit costs the seller, in đồng — or `null` when they have not
  /// entered it (WTM-204).
  ///
  /// `null`, **not 0**: zero says *"this is free stock"*, null says *"nobody
  /// has said"*, and treating the second as the first would print a 100%
  /// margin nobody computed (the ADR-TON-022 rule, applied to a field).
  ///
  /// The column (`costPerUnit`) has been in the schema since v1 — the domain
  /// simply never carried it, which is the single missing field behind four
  /// blocked capabilities: real opportunity ROI, the High Risk badge, per-
  /// product margin, and the journey's "record your cost price" step.
  final double? costPrice;

  /// Profit for one unit, or `null` when the cost price is unknown.
  ///
  /// Never a guess: `insufficient` is an answer (ADR-TON-017), a made-up
  /// margin is not. Computed here rather than stored — the schema's
  /// `profitPerUnit` column is a derived-data violation (WTM-202) and stays
  /// unread.
  double? get profitPerUnit {
    final cost = costPrice;
    return cost == null ? null : pricePerUnit - cost;
  }

  /// Total on-hand value = unit price × quantity (in đồng).
  /// Hàng này cần nhập thêm hay không — **một chủ sở hữu** cho câu hỏi đó.
  ///
  /// WTM-213 chốt `stockStatus` là chủ của khái niệm "sắp hết hàng", nhưng ba
  /// chỗ khác (prompt AI, CSV, Rule Engine) vẫn tự viết lại
  /// `quantity <= reorderLevel` bằng số học. Chúng đọc đúng hôm nay và sẽ lệch
  /// vào ngày luật đổi — đúng họ lỗi P-27. Sản phẩm không có tồn kho trả
  /// `false` một cách tự nhiên: nó không bao giờ cần nhập thêm.
  bool get needsRestock =>
      stockStatus == StockStatus.lowStock ||
      stockStatus == StockStatus.outOfStock;

  /// Tiền đang nằm trong kho. Sản phẩm không có tồn kho đóng góp **0** — đây
  /// là sự thật, không phải giá trị mặc định: một phần mềm không có đồng vốn
  /// nào nằm trong kho.
  double get stockValue => pricePerUnit * (quantity ?? 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Product($id, $sku, $name, qty=$quantity)';

  /// The same record under a different id — the sample-seeding remap hook
  /// (WTM-144/ADR-TON-014).
  Product withId(String newId) => Product(
    id: newId,
    sku: sku,
    name: name,
    category: category,
    quantity: quantity,
    pricePerUnit: pricePerUnit,
    reorderLevel: reorderLevel,
    updatedAt: updatedAt,
    costPrice: costPrice,
    description: description,
    imagePaths: imagePaths,
    history: history,
  );
}
