/// **Predictive AI Explanation layer** (WTM-158, ADR-TON-016 Decision 4).
///
/// ```
/// Capability Context → Rule Twin (AUTHORITATIVE) → AI (explains only) → Human
/// ```
///
/// The AI's entire world for a topic is exactly two blocks:
/// [CapabilityContext.promptBlock] (PII-free by construction) and a rendered
/// **Rule Twin block** carrying the twin's numbers, confidence, sufficiency,
/// reason codes and `version`. Deliberately **not** the flat business snapshot
/// (`businessContextPromptText`) — ADR-TON-016 replaced it for predictions
/// precisely because a single total cannot be extrapolated from.
///
/// | The AI may | The AI may NOT |
/// |---|---|
/// | explain the twin's numbers | change forecast/risk numbers |
/// | describe the trend, add context | query the DB / call a repository |
/// | say in words why it disagrees | mutate or execute anything |
///
/// Those are enforced **structurally**, not by asking the model nicely:
///
/// - [PredictiveAiService] holds one dependency, [TongtaiAiService]. It has no
///   repository, no `CapabilityContextProvider`, no Riverpod `Ref`, and no
///   `AiToolRuntime` (see `ai_runtime_boundary.dart`) — the caller hands it the
///   context and the twin it already computed, so there is nothing for the AI
///   layer to query or re-derive (One Data Path, ADR-TON-015).
/// - [PredictiveExplanation.ruleVersion] and
///   [PredictiveExplanation.reasonCodes] are **copied from the twin**, never
///   parsed out of model text. A hostile answer cannot alter them.
/// - `sufficiency == insufficient` short-circuits before the provider loop, so
///   a business the rule refuses to judge never spends a provider call — the
///   same zero-spend guard `BusinessAiEngine` applies with `hasData`.
library;

import 'package:flutter/foundation.dart';

import '../capability/capability_context.dart';
import '../capability/customer_capability.dart';
import '../capability/revenue_capability.dart';
import '../core/tongtai_formatters.dart';
import '../predictive/business_alerts_rule.dart';
import '../predictive/customer_risk_rule.dart';
import '../predictive/revenue_forecast_rule.dart';
import '../predictive/rule_twin.dart';
import '../predictive/weekly_review_rule.dart';
import 'business_summary.dart' show BusinessSummarySource;
import 'tongtai_ai_errors.dart';
import 'tongtai_ai_models.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';
import 'workizen_ai_router.dart'
    show kWorkizenRoutingPreference, WorkizenQueryClass;

/// Which predictive question an explanation answers.
enum PredictiveTopic {
  /// Next-month revenue, from [RevenueForecastRule].
  revenueForecast,

  /// Churn / win-back risk, from [CustomerRiskRule].
  customerRisk,

  /// What needs attention today, from [BusinessAlertsRule].
  businessAlerts,

  /// *"Tuần rồi thế nào"*, from [WeeklyReviewRule].
  weeklyReview;

  /// Vietnamese heading used inside the prompt (UI strings live in l10n).
  String get labelVi => switch (this) {
    PredictiveTopic.revenueForecast => 'Dự báo doanh thu tháng tới',
    PredictiveTopic.customerRisk => 'Rủi ro rời bỏ của khách hàng',
    PredictiveTopic.businessAlerts => 'Cảnh báo kinh doanh',
    PredictiveTopic.weeklyReview => 'Tổng kết tuần vừa qua',
  };
}

/// One explanation of one Rule Twin result.
///
/// [text] is the only field an AI provider can influence. [ruleVersion] and
/// [reasonCodes] are the twin's own, copied verbatim on **both** paths, and the
/// numbers a screen renders come from the twin — never from [text].
@immutable
class PredictiveExplanation {
  const PredictiveExplanation({
    required this.text,
    required this.topic,
    required this.source,
    required this.ruleVersion,
    required this.reasonCodes,
    required this.generatedAt,
    this.provider,
  });

  /// Prose for the seller — from a provider, or from the deterministic twin
  /// explanation when AI is off, unavailable, or refused (insufficient data).
  final String text;

  final PredictiveTopic topic;

  /// Where [text] came from. Reuses the existing enum so every AI surface in
  /// the app reports provenance the same way.
  final BusinessSummarySource source;

  /// The provider that answered when [source] is [BusinessSummarySource.ai].
  final TongtaiAiProviderKind? provider;

  /// The **twin's** formula version being explained, e.g. `revenue-forecast/1`.
  /// Copied from [RuleTwinResult.version]; the AI cannot change it.
  final String ruleVersion;

  /// The **twin's** reason codes, unchanged and in the twin's own order.
  final List<ReasonCode> reasonCodes;

  final DateTime generatedAt;

  bool get isAi => source == BusinessSummarySource.ai;
}

// ── Prompt construction ─────────────────────────────────────────────────────

/// The system prompt for every predictive explanation.
///
/// Rule 1 and rule 2 are the ADR-TON-016 contract in the model's own language:
/// explain and contextualize the rule's numbers; if you disagree, say why in
/// words — never restate a different figure. Rule 6 states the runtime boundary
/// (`ai_runtime_boundary.dart`): there are no tools to call.
const String kPredictiveAiSystemPrompt =
    'Bạn là Workizen AI, giải thích số liệu cho chủ shop SME Việt Nam. '
    'Nhiệm vụ của bạn là GIẢI THÍCH kết quả đã được tính sẵn, KHÔNG phải dự '
    'đoán lại. Trả lời tiếng Việt, ngắn gọn, thực tế, không hứa hẹn.';

/// The user message an explanation is built from: guardrails + the capability
/// block + the Rule Twin block. Pure — same inputs, byte-identical text.
///
/// Public so a contract test can assert what leaves the device: that the
/// capability block and the rule block are both present, and that no personal
/// data is (the customer-risk path carries ids, counts and bands only).
String predictiveAiPromptText({
  required CapabilityContext context,
  required String ruleBlock,
  PredictiveTopic? topic,
}) => predictiveAiPromptTextFor(
  contexts: [context],
  ruleBlock: ruleBlock,
  topic: topic,
);

/// Multi-context form of [predictiveAiPromptText] — business alerts span the
/// revenue **and** customer capabilities, so their prompt carries both blocks.
String predictiveAiPromptTextFor({
  required List<CapabilityContext> contexts,
  required String ruleBlock,
  PredictiveTopic? topic,
}) {
  final buffer = StringBuffer()
    ..writeln('# Nhiệm vụ: GIẢI THÍCH kết quả của Rule Twin')
    ..writeln(topic == null ? '' : 'Chủ đề: ${topic.labelVi}.')
    ..writeln('LUẬT BẮT BUỘC:')
    ..writeln(
      '1. Mọi con số đã được Rule Twin tính sẵn ở khối "# Rule Twin" bên '
      'dưới. Hãy GIẢI THÍCH và ĐẶT VÀO BỐI CẢNH những con số đó.',
    )
    ..writeln(
      '2. TUYỆT ĐỐI KHÔNG đưa ra con số khác, không tính lại, không làm tròn '
      'thành số của riêng bạn. Nếu bạn không đồng ý với Rule Twin, hãy nói '
      'bằng LỜI VĂN vì sao (dữ liệu mỏng, biến động mạnh, mùa vụ…) — không '
      'được nêu một con số thay thế.',
    )
    ..writeln(
      '3. Chỉ dùng dữ liệu trong các khối dưới đây. Không bịa, không suy ra '
      'dữ liệu không được cung cấp.',
    )
    ..writeln(
      '4. Nhắc lại đúng các mã lý do (reason codes) Rule Twin đã đưa ra; '
      'không thêm mã mới, không đổi ý nghĩa của mã.',
    )
    ..writeln(
      '5. Nếu Rule Twin nói CHƯA ĐỦ DỮ LIỆU thì câu trả lời cũng phải nói '
      'chưa đủ dữ liệu, và không được đưa ra bất kỳ dự báo nào.',
    )
    ..writeln(
      '6. Bạn không có công cụ, không truy vấn được dữ liệu và không thực '
      'hiện được hành động nào — chỉ giải thích.',
    );

  for (final context in contexts) {
    buffer
      ..writeln()
      ..writeln(context.promptBlock());
  }

  buffer
    ..writeln()
    ..write(ruleBlock);
  return buffer.toString();
}

// ── Rule Twin blocks (the AI's second, authoritative half) ──────────────────
/// Renders the weekly-review twin for the prompt. Pure, and **PII-free**: it
/// carries the week's own numbers and reason codes, never a customer name.
String weeklyReviewRuleBlock(RuleTwinResult<WeeklyReview> twin) {
  final buffer = StringBuffer()
    ..writeln('# Rule Twin: ${PredictiveTopic.weeklyReview.labelVi}')
    ..write(_twinHeader(twin));

  final review = twin.result;
  if (review == null) {
    buffer.write(
      '- KHÔNG CÓ CON SỐ: rule từ chối tổng kết vì chưa có tuần hoàn chỉnh nào '
      'có đơn. Không được tự đưa ra bất kỳ con số nào.',
    );
    return buffer.toString();
  }

  final week = review.week;
  buffer
    ..writeln(
      '- Tuần: ${week.week} đến ${TongtaiFormatters.isoDate(week.week.sunday)}',
    )
    ..writeln('- Doanh thu: ${TongtaiFormatters.vnd(week.revenue)}')
    ..writeln('- Số đơn: ${week.orderCount}')
    ..writeln('- Số khách đã mua: ${week.customerCount}')
    ..writeln(
      '- Trung bình mỗi đơn: ${TongtaiFormatters.vnd(week.averageOrderValue)}',
    )
    ..writeln('- Xu hướng so tuần trước: ${review.trend.name}');

  // ⛔ `null` phải nói ra thành lời, không được im lặng thành 0 %: model đọc
  // một khoảng trống rất dễ tự điền "không đổi".
  final change = review.revenueChange;
  buffer.writeln(
    change == null
        ? '- So với tuần trước: KHÔNG SO ĐƯỢC (không có tuần trước, hoặc tuần '
              'trước bằng 0). Không được nói "không đổi" hay "0%".'
        : '- So với tuần trước: ${capabilityDecimal(change * 100, decimals: 1)}%',
  );

  if (week.topProduct case final top?) {
    buffer.writeln(
      '- Bán chạy nhất (theo tiền): ${top.name}, '
      '${TongtaiFormatters.vnd(top.revenue)}, ${top.quantity} đơn vị',
    );
  } else {
    buffer.writeln('- Bán chạy nhất: không có, tuần rồi không bán được gì');
  }

  buffer.writeln('- Bốn tuần gần nhất (cũ → mới):');
  for (final point in review.history) {
    buffer.writeln(
      '  · ${point.week}: ${TongtaiFormatters.vnd(point.revenue)}, '
      '${point.orderCount} đơn',
    );
  }
  return buffer.toString();
}

/// Renders the revenue forecast twin for the prompt. Pure.
String revenueForecastRuleBlock(RuleTwinResult<RevenueForecast> twin) {
  final buffer = StringBuffer()
    ..writeln('# Rule Twin: ${PredictiveTopic.revenueForecast.labelVi}')
    ..write(_twinHeader(twin));

  final forecast = twin.result;
  if (forecast == null) {
    buffer.write(
      '- KHÔNG CÓ CON SỐ: rule từ chối dự báo vì chưa đủ dữ liệu. '
      'Không được tự đưa ra bất kỳ con số nào.',
    );
    return buffer.toString();
  }

  final target = forecast.targetMonth;
  buffer
    ..writeln(
      '- Dự báo tháng ${target ?? 'kế tiếp'}: '
      '${TongtaiFormatters.vnd(forecast.nextMonthRevenue)}',
    )
    ..writeln(
      '- Dải hợp lý: ${TongtaiFormatters.vnd(forecast.lowerBound)} '
      'đến ${TongtaiFormatters.vnd(forecast.upperBound)}',
    )
    ..writeln(
      '- Xu hướng đo được: ${TongtaiFormatters.vnd(forecast.trendPerMonth)}'
      '/tháng, hướng ${forecast.direction.name}',
    )
    ..writeln(
      '- Hệ số mùa vụ đã áp dụng: '
      '${forecast.seasonalMultiplierApplied == null ? 'không áp dụng' : '${capabilityDecimal(forecast.seasonalMultiplierApplied)}×'}',
    );

  final basis = forecast.basis;
  if (basis.isNotEmpty) {
    buffer.write(
      '- Cơ sở tính: ${basis.length} tháng '
      '(${basis.first.key} đến ${basis.last.key}), tháng gần nhất '
      '${TongtaiFormatters.vnd(basis.last.revenue)}',
    );
  }
  return buffer.toString();
}

/// Renders the customer risk twin for the prompt — **ids, counts and bands
/// only**. No name, phone, email or address exists in [CustomerRiskAssessment]
/// to leak (structural guarantee, D-7 / ADR-TON-005). Pure.
String customerRiskRuleBlock(
  RuleTwinResult<CustomerRiskAssessment> twin, {
  int topEntries = 5,
}) {
  final buffer = StringBuffer()
    ..writeln('# Rule Twin: ${PredictiveTopic.customerRisk.labelVi}')
    ..write(_twinHeader(twin));

  final risk = twin.result;
  if (risk == null) {
    buffer.write(
      '- KHÔNG CÓ KẾT QUẢ: rule từ chối chấm rủi ro vì chưa đủ dữ liệu. '
      'Không được suy ra tỉ lệ rời bỏ nào.',
    );
    return buffer.toString();
  }

  buffer
    ..writeln(
      '- Khách hàng: ${risk.totalCustomers}, rủi ro ${risk.atRiskCount}, '
      'đã rời bỏ ${risk.churnedCount}, ứng viên win-back ${risk.winBackCount}',
    )
    ..writeln(
      '- Vòng đời: '
      '${[for (final s in CustomerLifecycleStage.values) '${s.labelVi} ${risk.stage(s)}'].join(', ')}',
    )
    ..writeln(
      '- Nhóm rủi ro cao nhất (mã khách, điểm rủi ro 0-100, giai đoạn, số '
      'ngày im lặng, số đơn trọn đời, mã lý do):',
    );

  final top = risk.top(topEntries);
  if (top.isEmpty) {
    buffer.write('  (danh bạ trống)');
    return buffer.toString();
  }
  for (var i = 0; i < top.length; i++) {
    final entry = top[i];
    final line =
        '  ${i + 1}. ${entry.customerId} — '
        '${capabilityDecimal(entry.riskScore, decimals: 1)} — '
        '${entry.stage.labelVi} — '
        '${entry.recencyDays == null ? 'chưa mua lần nào' : '${entry.recencyDays} ngày'} — '
        '${entry.lifetimeOrders} đơn'
        '${entry.winBackCandidate ? ' — nên win-back' : ''} — '
        '${_codes(entry.reasonCodes)}';
    if (i == top.length - 1) {
      buffer.write(line);
    } else {
      buffer.writeln(line);
    }
  }
  return buffer.toString();
}

/// Renders the business alerts twin for the prompt. Pure.
String businessAlertsRuleBlock(RuleTwinResult<List<BusinessAlert>> twin) {
  final buffer = StringBuffer()
    ..writeln('# Rule Twin: ${PredictiveTopic.businessAlerts.labelVi}')
    ..write(_twinHeader(twin));

  final alerts = twin.result;
  if (alerts == null) {
    buffer.write(
      '- KHÔNG CÓ KẾT QUẢ: rule không đọc được tín hiệu nào, chưa đủ dữ liệu '
      'để cảnh báo. Không được suy ra vấn đề nào.',
    );
    return buffer.toString();
  }
  if (alerts.isEmpty) {
    buffer.write(
      '- Không có cảnh báo nào: đây là câu trả lời thật (mọi tín hiệu đọc '
      'được đều bình thường), không phải thiếu dữ liệu.',
    );
    return buffer.toString();
  }

  buffer.writeln('- Số cảnh báo: ${alerts.length} (nặng nhất trước)');
  for (var i = 0; i < alerts.length; i++) {
    final alert = alerts[i];
    final money = alert.kind == BusinessAlertKind.revenueDrop;
    final line =
        '  ${i + 1}. ${alert.kind.labelVi} [${alert.severity.labelVi}] — '
        '${_amount(alert.metricValue, money: money)} so với '
        '${_amount(alert.comparisonValue, money: money)} '
        '(${capabilityPercent(alert.change)}), '
        'ảnh hưởng ${alert.affectedCount} — ${_codes(alert.reasonCodes)}';
    if (i == alerts.length - 1) {
      buffer.write(line);
    } else {
      buffer.writeln(line);
    }
  }
  return buffer.toString();
}

// ── Deterministic twin explanations (the AI-off / offline / refusal answer) ──

/// Explains the revenue forecast without AI. Pure, deterministic, Vietnamese,
/// and it quotes the twin's own reason codes.
/// The deterministic weekly-review explanation — what ships when there is no
/// BYOK key, or every provider fails.
///
/// Nó phải đứng một mình được: đây là câu người bán đọc trong đa số phiên, chứ
/// không phải một chỗ giữ chỗ chờ AI.
String ruleBasedWeeklyReviewExplanation(RuleTwinResult<WeeklyReview> twin) {
  final buffer = StringBuffer();
  final review = twin.result;

  if (review == null) {
    buffer
      ..writeln(
        'Chưa có tuần nào đã kết thúc có đơn hàng, nên phần mềm không tổng kết '
        '— một bản tổng kết toàn số 0 sẽ nói sai về việc kinh doanh của bạn.',
      )
      ..writeln(_bullets(twin.reasonCodes))
      ..writeln(
        'Cứ ghi đơn trong tuần này, sáng thứ Hai sẽ có bản tổng kết đầu tiên.',
      )
      ..write(_ruleFooter(twin));
    return buffer.toString();
  }

  final week = review.week;
  if (week.isEmpty) {
    // ⭐ Đây là một CÂU TRẢ LỜI, không phải một lời từ chối.
    buffer.writeln(
      'Tuần ${week.week} không có đơn nào. Đây là số thật, không phải lỗi đọc '
      'dữ liệu.',
    );
  } else {
    buffer
      ..writeln(
        'Tuần ${week.week}: ${TongtaiFormatters.vnd(week.revenue)} từ '
        '${week.orderCount} đơn của ${week.customerCount} khách, trung bình '
        '${TongtaiFormatters.vnd(week.averageOrderValue)} mỗi đơn.',
      )
      ..writeln(
        week.topProduct == null
            ? ''
            : 'Bán chạy nhất là ${week.topProduct!.name} '
                  '(${TongtaiFormatters.vnd(week.topProduct!.revenue)}).',
      );
  }

  final change = review.revenueChange;
  buffer.writeln(
    change == null
        // ⛔ Không có tuần trước thì nói thẳng, không vẽ "không đổi".
        ? 'Chưa có tuần trước để so, nên chưa nói được là tăng hay giảm.'
        : 'So với tuần trước: '
              '${change >= 0 ? 'tăng' : 'giảm'} '
              '${capabilityDecimal(change.abs() * 100, decimals: 0)}%.',
  );
  buffer.writeln(_bullets(twin.reasonCodes));
  if (twin.sufficiency == DataSufficiency.partial) {
    buffer.writeln(
      'Mới có một tuần để nhìn, nên hãy đọc con số này như một điểm khởi đầu, '
      'chưa phải một xu hướng.',
    );
  }
  buffer.write(_ruleFooter(twin));
  return buffer.toString();
}

String ruleBasedForecastExplanation(RuleTwinResult<RevenueForecast> twin) {
  final buffer = StringBuffer();
  final forecast = twin.result;

  if (forecast == null) {
    buffer
      ..writeln(
        'Chưa đủ dữ liệu để dự báo doanh thu tháng tới, nên phần mềm không '
        'đưa ra con số nào — một con số đoán bừa còn tệ hơn là không có.',
      )
      ..writeln(_bullets(twin.reasonCodes))
      ..writeln(
        'Cần ít nhất ${RevenueForecastRule.minMonthsOfRevenue} tháng có doanh '
        'thu để bắt đầu dự báo. Cứ ghi đơn đều đặn, dự báo sẽ tự xuất hiện.',
      )
      ..write(_ruleFooter(twin));
    return buffer.toString();
  }

  final target = forecast.targetMonth;
  buffer
    ..writeln(
      'Dự báo doanh thu tháng ${target ?? 'kế tiếp'}: '
      '${TongtaiFormatters.vnd(forecast.nextMonthRevenue)}, thực tế nhiều khả '
      'năng rơi vào khoảng ${TongtaiFormatters.vnd(forecast.lowerBound)} đến '
      '${TongtaiFormatters.vnd(forecast.upperBound)}.',
    )
    ..writeln(
      'Độ tin cậy ${twin.confidence.label('vi').toLowerCase()}, tính trên '
      '${forecast.basis.length} tháng gần nhất với xu hướng '
      '${TongtaiFormatters.vnd(forecast.trendPerMonth)} mỗi tháng.',
    )
    ..writeln(_bullets(twin.reasonCodes));
  if (twin.sufficiency == DataSufficiency.partial) {
    buffer.writeln(
      'Lịch sử còn mỏng nên hãy đọc con số này như một gợi ý, chưa phải cam '
      'kết.',
    );
  }
  buffer.write(_ruleFooter(twin));
  return buffer.toString();
}

/// Explains the customer risk assessment without AI. Pure and PII-free: it
/// speaks in counts and ids, exactly like the twin it explains.
String ruleBasedRiskExplanation(RuleTwinResult<CustomerRiskAssessment> twin) {
  final buffer = StringBuffer();
  final risk = twin.result;

  if (risk == null) {
    buffer
      ..writeln(
        'Chưa đủ dữ liệu để đánh giá rủi ro rời bỏ — danh bạ khách hàng đang '
        'trống, nên không có ai để chấm điểm.',
      )
      ..writeln(_bullets(twin.reasonCodes))
      ..writeln('Thêm khách hàng và đơn hàng đầu tiên để bắt đầu theo dõi.')
      ..write(_ruleFooter(twin));
    return buffer.toString();
  }

  buffer.writeln(
    '${risk.totalCustomers} khách trong danh bạ: ${risk.atRiskCount} đang ở '
    'mức rủi ro, ${risk.churnedCount} coi như đã rời bỏ, '
    '${risk.winBackCount} người đáng để kéo lại.',
  );
  final top = risk.top(3).where((entry) => entry.isLapsed).toList();
  if (top.isNotEmpty) {
    buffer.writeln(
      'Nên liên hệ trước: '
      '${top.map((e) => '${e.customerId} (${capabilityDecimal(e.riskScore, decimals: 1)} điểm)').join(', ')}.',
    );
  } else {
    buffer.writeln('Hiện chưa có khách nào vượt ngưỡng cần liên hệ gấp.');
  }
  buffer.writeln(_bullets(twin.reasonCodes));
  if (twin.sufficiency == DataSufficiency.partial) {
    buffer.writeln(
      'Chưa khách nào từng mua, nên đây mới là danh bạ chứ chưa phải nhịp mua '
      '— chưa kết luận được gì về rời bỏ.',
    );
  }
  buffer.write(_ruleFooter(twin));
  return buffer.toString();
}

/// Explains the business alerts without AI. Pure. An empty alert list is a real
/// answer ("nothing is wrong"), never dressed up as missing data.
String ruleBasedAlertsExplanation(RuleTwinResult<List<BusinessAlert>> twin) {
  final buffer = StringBuffer();
  final alerts = twin.result;

  if (alerts == null) {
    buffer
      ..writeln(
        'Chưa đủ dữ liệu để cảnh báo: chưa đọc được tín hiệu nào về doanh '
        'thu, khách hàng, tồn kho hay dòng tiền.',
      )
      ..writeln(_bullets(twin.reasonCodes))
      ..write(_ruleFooter(twin));
    return buffer.toString();
  }

  if (alerts.isEmpty) {
    buffer
      ..writeln(
        'Không có cảnh báo nào — mọi tín hiệu đọc được đều đang bình thường.',
      )
      ..writeln(_bullets(twin.reasonCodes))
      ..write(_ruleFooter(twin));
    return buffer.toString();
  }

  buffer.writeln('${alerts.length} việc cần chú ý, nặng nhất trước:');
  for (final alert in alerts) {
    final money = alert.kind == BusinessAlertKind.revenueDrop;
    buffer.writeln(
      '• ${alert.kind.labelVi} (${alert.severity.labelVi}): '
      '${_amount(alert.metricValue, money: money)} so với '
      '${_amount(alert.comparisonValue, money: money)} '
      '(${capabilityPercent(alert.change)}).',
    );
  }
  buffer.writeln(_bullets(twin.reasonCodes));
  if (twin.sufficiency == DataSufficiency.partial) {
    buffer.writeln(
      'Chưa so sánh được hai kỳ doanh thu, nên danh sách này còn thiếu tín '
      'hiệu quan trọng nhất.',
    );
  }
  buffer.write(_ruleFooter(twin));
  return buffer.toString();
}

// ── Service ─────────────────────────────────────────────────────────────────

/// Turns a Rule Twin result into prose for the seller (WTM-158).
///
/// Deliberately **not** built on `BusinessAiEngine`: that runner serializes the
/// flat `BusinessContext`, which ADR-TON-016 removed from the predictive path.
/// The invariants are mirrored one for one — provider chain, rule fallback,
/// zero provider spend when there is nothing to explain.
///
/// The caller passes the capability context and the twin it already watches
/// (`revenueForecastProvider` & co.), so nothing is loaded, re-derived or
/// counted twice here, and this service structurally cannot reach a repository.
class PredictiveAiService {
  const PredictiveAiService(this._ai, {this.preference = const [], this.clock});

  final TongtaiAiService _ai;

  /// Provider order to try; empty means the router's complex-query default.
  final List<TongtaiAiProviderKind> preference;

  /// Injectable clock for deterministic tests; defaults to [DateTime.now].
  final DateTime Function()? clock;

  List<TongtaiAiProviderKind> get _chain => preference.isNotEmpty
      ? preference
      : kWorkizenRoutingPreference[WorkizenQueryClass.complex]!;

  /// Explains the next-month revenue forecast over its revenue context.
  Future<PredictiveExplanation> explainForecast({
    required RevenueCapabilityContext context,
    required RuleTwinResult<RevenueForecast> forecast,
  }) => _explain(
    topic: PredictiveTopic.revenueForecast,
    contexts: [context],
    twin: forecast,
    ruleBlock: revenueForecastRuleBlock(forecast),
    ruleText: ruleBasedForecastExplanation(forecast),
  );

  /// Explains the churn / win-back assessment over its customer context.
  Future<PredictiveExplanation> explainRisk({
    required CustomerCapabilityContext context,
    required RuleTwinResult<CustomerRiskAssessment> risk,
  }) => _explain(
    topic: PredictiveTopic.customerRisk,
    contexts: [context],
    twin: risk,
    ruleBlock: customerRiskRuleBlock(risk),
    ruleText: ruleBasedRiskExplanation(risk),
  );

  /// Explains today's business alerts. Alerts span both capabilities, so both
  /// blocks are supplied — the twin was computed from them.
  Future<PredictiveExplanation> explainAlerts({
    required RevenueCapabilityContext revenue,
    required CustomerCapabilityContext customers,
    required RuleTwinResult<List<BusinessAlert>> alerts,
  }) => _explain(
    topic: PredictiveTopic.businessAlerts,
    contexts: [revenue, customers],
    twin: alerts,
    ruleBlock: businessAlertsRuleBlock(alerts),
    ruleText: ruleBasedAlertsExplanation(alerts),
  );

  /// Explains the weekly review.
  ///
  /// Không truyền capability context: [WeeklyReviewRule] đọc thẳng sổ đơn nên
  /// **bản thân bản tổng kết đã là bằng chứng**. Cửa zero-spend vì thế hỏi
  /// đúng câu của nó — *"tuần rồi có gì để nói không"* — thay vì hỏi một
  /// capability context không tồn tại.
  Future<PredictiveExplanation> explainWeeklyReview({
    required RuleTwinResult<WeeklyReview> review,
  }) => _explain(
    topic: PredictiveTopic.weeklyReview,
    contexts: const [],
    twin: review,
    ruleBlock: weeklyReviewRuleBlock(review),
    ruleText: ruleBasedWeeklyReviewExplanation(review),
    // Một tuần trống VẪN đáng giải thích: *"tuần rồi không bán được gì"* là
    // đúng lúc người bán cần một câu nói cho ra hồn nhất.
    hasEvidence: review.result != null,
  );

  /// The one runner behind all four topics.
  ///
  /// Order matters: the zero-spend guard comes first, then the provider chain,
  /// then the deterministic twin explanation. Whatever answers, the twin's
  /// `version` and `reasonCodes` are what the result carries.
  Future<PredictiveExplanation> _explain({
    required PredictiveTopic topic,
    required List<CapabilityContext> contexts,
    required RuleTwinResult<Object> twin,
    required String ruleBlock,
    required String ruleText,
    bool? hasEvidence,
  }) async {
    final now = (clock ?? DateTime.now)();

    PredictiveExplanation build({
      required String text,
      required TongtaiAiProviderKind? provider,
    }) => PredictiveExplanation(
      text: text,
      topic: topic,
      source: provider == null
          ? BusinessSummarySource.rule
          : BusinessSummarySource.ai,
      provider: provider,
      // Copied from the twin on BOTH paths — never parsed from model output.
      ruleVersion: twin.version,
      reasonCodes: List<ReasonCode>.unmodifiable(twin.reasonCodes),
      generatedAt: now,
    );

    // Zero-spend guard. A twin that refused to answer has nothing to explain,
    // and neither does a set of empty capability contexts — sending either to
    // a provider would burn the seller's BYOK quota to be told "no data".
    //
    // `hasEvidence` cho phép một twin KHÔNG có capability context tự khai bằng
    // chứng của nó (Tổng kết tuần đọc thẳng sổ đơn). Mặc định vẫn là câu hỏi
    // cũ — đây là khái quát hoá, không phải nới lỏng: cửa vẫn đóng khi twin từ
    // chối, và đó là vế quan trọng.
    final worthExplaining =
        twin.sufficiency.canAnswer &&
        (hasEvidence ?? contexts.any((context) => context.hasData));

    if (worthExplaining) {
      final input = predictiveAiPromptTextFor(
        contexts: contexts,
        ruleBlock: ruleBlock,
        topic: topic,
      );
      for (final provider in _chain) {
        if (!await _ai.hasKey(provider: provider)) continue;
        try {
          final response = await _ai.chat(
            messages: [TongtaiAiMessage.user(input)],
            systemPrompt: kPredictiveAiSystemPrompt,
            provider: provider,
          );
          return build(text: response.text, provider: provider);
        } on TongtaiAiException {
          continue; // Next provider in the chain.
        }
      }
    }

    return build(text: ruleText, provider: null);
  }
}

// ── Shared rendering helpers ────────────────────────────────────────────────

/// The identical opening lines of every Rule Twin block: provenance (the
/// PII-free string the ADR blesses for prompts and telemetry alike), the
/// sufficiency/confidence bands, and the reason codes the AI must quote back.
String _twinHeader(RuleTwinResult<Object> twin) =>
    '- Provenance: ${twin.provenance}\n'
    '- Phiên bản công thức: ${twin.version} (số liệu chính thức, AI không '
    'được sửa)\n'
    '- Mức đủ dữ liệu: ${_sufficiencyVi(twin.sufficiency)} '
    '(${twin.sufficiency.name})\n'
    '- Độ tin cậy: ${twin.confidence.label('vi')} (${twin.confidence.name})\n'
    '- Mã lý do (giữ nguyên, không thêm bớt): ${_codes(twin.reasonCodes)}\n';

String _sufficiencyVi(DataSufficiency sufficiency) => switch (sufficiency) {
  DataSufficiency.insufficient => 'chưa đủ dữ liệu',
  DataSufficiency.partial => 'đủ một phần',
  DataSufficiency.sufficient => 'đủ',
};

/// Machine codes, comma-separated — the exact strings the UI and the tests
/// assert on.
String _codes(List<ReasonCode> codes) =>
    codes.isEmpty ? 'không có' : codes.map((code) => code.code).join(', ');

/// Reason codes as readable Vietnamese bullets.
String _bullets(List<ReasonCode> codes) => codes.isEmpty
    ? 'Vì sao: rule không nêu lý do nào.'
    : 'Vì sao:\n${codes.map((code) => '• ${code.labelVi}').join('\n')}';

/// The closing provenance line — states the formula version and repeats the
/// machine codes, so the rule-based text carries the same contract the AI text
/// is told to quote.
String _ruleFooter(RuleTwinResult<Object> twin) =>
    '(Giải thích rule-based ${twin.version}, mã lý do: '
    '${_codes(twin.reasonCodes)}. Không tốn lượt gọi AI — '
    'thêm API key trong More → AI Assistant để nhận giải thích chi tiết hơn.)';

/// A twin metric: đồng when it is money, a plain count otherwise.
String _amount(double value, {required bool money}) => money
    ? TongtaiFormatters.vnd(value)
    : capabilityDecimal(value, decimals: 0);
