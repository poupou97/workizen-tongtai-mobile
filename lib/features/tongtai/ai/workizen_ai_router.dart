import '../chat/chat_controller.dart';
import '../chat/chat_message.dart';
import 'tongtai_ai_errors.dart';
import 'tongtai_ai_models.dart';
import 'tongtai_ai_provider_kind.dart';
import 'tongtai_ai_service.dart';
import 'workizen_ai_context.dart';

/// How a seller query is classified for routing (WTM-82 AC1).
enum WorkizenQueryClass {
  /// Short, factual, transactional — cheap/fast models are fine.
  simple,

  /// Analysis, planning, comparison, forecasting — worth a stronger model.
  complex,
}

/// Rule-based query classifier (WTM-82 AC1). Deterministic and local: long
/// prompts or prompts containing analysis/planning vocabulary (VI + EN) are
/// [WorkizenQueryClass.complex]; everything else is simple.
WorkizenQueryClass classifyWorkizenQuery(String prompt) {
  final text = prompt.trim().toLowerCase();
  if (text.length > 200) return WorkizenQueryClass.complex;
  const complexMarkers = [
    // Vietnamese
    'phân tích', 'so sánh', 'kế hoạch', 'chiến lược', 'dự báo', 'tại sao',
    'đánh giá', 'tối ưu', 'xu hướng', 'nên làm gì', 'lộ trình',
    // English
    'analy', 'compare', 'plan', 'strategy', 'forecast', 'why', 'evaluate',
    'optimi', 'trend', 'roadmap',
  ];
  for (final marker in complexMarkers) {
    if (text.contains(marker)) return WorkizenQueryClass.complex;
  }
  return WorkizenQueryClass.simple;
}

/// Preferred provider order per query class (WTM-82 routing criteria —
/// reviewed with the Founder in the PR). Strong reasoning first for complex
/// queries; fast/cheap first for simple ones. Only providers the user has
/// enabled (key stored / Ollama opted in) are actually tried, in this order.
const Map<WorkizenQueryClass, List<TongtaiAiProviderKind>>
kWorkizenRoutingPreference = {
  WorkizenQueryClass.complex: [
    TongtaiAiProviderKind.xai,
    TongtaiAiProviderKind.gemini,
    TongtaiAiProviderKind.openAI,
    TongtaiAiProviderKind.openRouter,
    TongtaiAiProviderKind.cerebras,
    TongtaiAiProviderKind.ollama,
  ],
  WorkizenQueryClass.simple: [
    TongtaiAiProviderKind.cerebras,
    TongtaiAiProviderKind.openRouter,
    TongtaiAiProviderKind.ollama,
    TongtaiAiProviderKind.gemini,
    TongtaiAiProviderKind.xai,
    TongtaiAiProviderKind.openAI,
  ],
};

/// Deterministic offline responder — the WTM-82 AC5 fallback when no AI
/// provider is available (no keys, network down, all providers erroring).
/// Answers from the same local context the AI would get, and tells the seller
/// how to enable a provider. No network, fully testable.
class RuleBasedChatResponder implements ChatResponder {
  RuleBasedChatResponder({WorkizenAiContextBuilder? context})
    : _context = context ?? WorkizenAiContextBuilder();

  final WorkizenAiContextBuilder _context;

  @override
  Future<String> reply(List<ChatMessage> history, String prompt) async {
    final buffer = StringBuffer();
    final customers = _context.customersMentionedIn(prompt);
    final products = _context.productsMentionedIn(prompt);

    if (customers.isEmpty && products.isEmpty) {
      buffer.writeln(
        'Workizen AI (chế độ ngoại tuyến): tôi có thể tra cứu khách hàng, '
        'sản phẩm và đơn hàng ngay trên máy — hãy nhắc tên khách hoặc sản '
        'phẩm trong câu hỏi.',
      );
    } else {
      buffer.writeln('Workizen AI (chế độ ngoại tuyến) — dữ liệu trên máy:');
      for (final customer in customers.take(2)) {
        buffer.writeln(
          '• ${customer.name}: hạng ${customer.tier.labelVi}, '
          '${customer.orderCount} đơn.',
        );
      }
      for (final product in products.take(3)) {
        buffer.writeln(
          '• ${product.name}: tồn ${product.quantity}, SKU ${product.sku}.',
        );
      }
    }
    buffer.write(
      'Để nhận phân tích AI đầy đủ, thêm API key trong More → AI Assistant. '
      '(Offline mode — add an AI key in More → AI Assistant for full answers.)',
    );
    return buffer.toString();
  }
}

/// Workizen AI Router (WTM-82, ADR-TON-006): the [ChatResponder] behind the
/// chat screen. The seller only ever sees "Workizen AI" — this router
/// classifies the query (AC1), injects local business context into the system
/// prompt (AC2/AC3/AC4), picks the best *enabled* provider for the class, and
/// falls back through the preference chain to [RuleBasedChatResponder] when
/// no provider can answer (AC5).
///
/// Phase-2 modes per ADR-TON-006 + D-5: BYOK and Local (Ollama). Managed
/// keys need a backend and arrive in Phase 3 — the preference chain already
/// has room for them.
class WorkizenAiRouter implements ChatResponder {
  WorkizenAiRouter({
    required this._service,
    WorkizenAiContextBuilder? context,
    ChatResponder? fallback,
    Map<WorkizenQueryClass, List<TongtaiAiProviderKind>>? preference,
    this.historyWindow = 12,
  }) : _context = context ?? WorkizenAiContextBuilder(),
       _fallback =
           fallback ??
           RuleBasedChatResponder(
             context: context ?? WorkizenAiContextBuilder(),
           ),
       _preference = preference ?? kWorkizenRoutingPreference;

  final TongtaiAiService _service;
  final WorkizenAiContextBuilder _context;
  final ChatResponder _fallback;
  final Map<WorkizenQueryClass, List<TongtaiAiProviderKind>> _preference;

  /// How many recent turns are forwarded to the provider.
  final int historyWindow;

  /// The provider that answered the most recent turn (for diagnostics/tests);
  /// null when the rule-based fallback answered.
  TongtaiAiProviderKind? lastProvider;

  @override
  Future<String> reply(List<ChatMessage> history, String prompt) async {
    final queryClass = classifyWorkizenQuery(prompt);
    final systemPrompt = _context.build(prompt);
    final messages = _toAiMessages(history, prompt);

    for (final provider in _preference[queryClass]!) {
      // "Enabled" = a value in the provider's key slot (a real key, or the
      // opt-in marker for Ollama, which requires none).
      if (!await _service.hasKey(provider: provider)) continue;
      try {
        final response = await _service.chat(
          messages: messages,
          systemPrompt: systemPrompt,
          provider: provider,
        );
        lastProvider = provider;
        return response.text;
      } on TongtaiAiException {
        // Provider unavailable/erroring — try the next one in the chain.
        continue;
      }
    }

    lastProvider = null;
    return _fallback.reply(history, prompt);
  }

  /// Map the on-screen conversation to provider messages, keeping the last
  /// [historyWindow] turns so long chats stay within context cheaply. The
  /// just-sent prompt is always the final user turn (the controller adds it
  /// to [history] before calling reply, so avoid duplicating it).
  List<TongtaiAiMessage> _toAiMessages(
    List<ChatMessage> history,
    String prompt,
  ) {
    final recent = history.length > historyWindow
        ? history.sublist(history.length - historyWindow)
        : history;
    final mapped = <TongtaiAiMessage>[
      for (final m in recent)
        if (m.text.trim().isNotEmpty)
          m.isSeller
              ? TongtaiAiMessage.user(m.text)
              : TongtaiAiMessage.assistant(m.text),
    ];
    if (mapped.isEmpty || mapped.last.content != prompt) {
      mapped.add(TongtaiAiMessage.user(prompt));
    }
    return mapped;
  }
}
