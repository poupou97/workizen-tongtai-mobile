import 'package:flutter/material.dart';

import '../../chat/chat_message.dart';
import '../../chat/chat_message_store.dart';
import '../../core/tongtai_formatters.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../widgets/tongtai_screen_data.dart';
import '../widgets/tongtai_fox_mascot.dart';
import '../../../../core/l10n/app_strings.dart';

/// Date window for the chat search (WTM-84) — "by session/period".
enum ChatSearchRange {
  all,
  today,
  last7Days;

  String label(AppStrings l10n) => switch (this) {
    ChatSearchRange.all => l10n.filterAll,
    ChatSearchRange.today => l10n.dateToday,
    ChatSearchRange.last7Days => l10n.chatSearchRange7d,
  };

  /// The `from` bound this preset represents at [now]; null = unbounded.
  DateTime? fromAt(DateTime now) => switch (this) {
    ChatSearchRange.all => null,
    ChatSearchRange.today => DateTime(now.year, now.month, now.day),
    ChatSearchRange.last7Days => now.subtract(const Duration(days: 7)),
  };
}

/// Chat Search & History (WTM-84) — searches the persisted conversation by
/// content (case-insensitive, Vietnamese-aware, via [ChatMessageStore.search])
/// and by period, grouping matches by day and highlighting the keyword.
///
/// Local-only (ADR-TON-004): the search runs entirely on-device. `clock` is
/// injectable so the range presets are deterministic under test.
class TongtaiChatSearchScreen extends StatefulWidget {
  const TongtaiChatSearchScreen({super.key, required this.store, this.clock});

  final ChatMessageStore store;
  final DateTime Function()? clock;

  @override
  State<TongtaiChatSearchScreen> createState() =>
      _TongtaiChatSearchScreenState();
}

class _TongtaiChatSearchScreenState extends State<TongtaiChatSearchScreen> {
  final _searchController = TextEditingController();
  late final DateTime Function() _clock;

  ChatSearchRange _range = ChatSearchRange.all;
  String _keyword = '';

  /// The current result set. Its generation counter also replaces this
  /// screen's hand-rolled `_searchToken`: dropping stale responses is now the
  /// seam's job, in one place, for every screen (WTM-148).
  late final ScreenDataController<List<ChatMessage>> _data;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    _data = ScreenDataController<List<ChatMessage>>(
      _read,
      initialValue: const <ChatMessage>[],
      screen: 'chat',
    );
  }

  @override
  void dispose() {
    _data.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ChatMessage>> _read() async {
    final keyword = _keyword.trim();
    if (keyword.isEmpty) return const [];
    final results = await widget.store.search(
      ChatHistoryQuery(text: keyword, from: _range.fromAt(_clock())),
    );
    return results.reversed.toList(); // newest first
  }

  Future<void> _runSearch() => _data.refresh();

  void _onKeyword(String value) {
    setState(() => _keyword = value);
    _runSearch();
  }

  void _onRange(ChatSearchRange range) {
    setState(() => _range = range);
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final hasKeyword = _keyword.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
        elevation: 0,
        title: TextField(
          key: const Key('chat-search-field'),
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.chatSearchHint,
            border: InputBorder.none,
          ),
          onChanged: _onKeyword,
        ),
      ),
      body: Column(
        children: [
          _RangeRow(selected: _range, onSelected: _onRange),
          const Divider(height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: _data,
              builder: (context, _) => TongtaiScreenData<List<ChatMessage>>(
                prefix: 'chat',
                state: _data.state,
                onRetry: _data.retry,
                isEmpty: (results) => !hasKeyword || results.isEmpty,
                emptyBuilder: (_) =>
                    hasKeyword ? const _NoResults() : const _Prompt(),
                builder: (context, results) => _ResultList(
                  results: results,
                  keyword: _keyword.trim(),
                  now: _clock(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.selected, required this.onSelected});

  final ChatSearchRange selected;
  final ValueChanged<ChatSearchRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: TongtaiDesignTokens.spacing4,
        ),
        children: [
          for (final range in ChatSearchRange.values)
            Padding(
              padding: const EdgeInsets.only(
                right: TongtaiDesignTokens.spacing2,
              ),
              child: ChoiceChip(
                key: Key('chat-search-range-${range.name}'),
                label: Text(range.label(context.l10n)),
                selected: selected == range,
                onSelected: (_) => onSelected(range),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.results,
    required this.keyword,
    required this.now,
  });

  final List<ChatMessage> results;
  final String keyword;
  final DateTime now;

  String _dayLabel(DateTime ts, AppStrings l10n) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(ts.year, ts.month, ts.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.dateToday;
    if (diff == 1) return l10n.dateYesterday;
    return TongtaiFormatters.isoDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Group results (already newest-first) into day sections.
    final sections = <String, List<ChatMessage>>{};
    for (final m in results) {
      (sections[_dayLabel(m.timestamp, l10n)] ??= []).add(m);
    }
    return ListView(
      key: const Key('chat-search-results'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TongtaiDesignTokens.spacing4,
            TongtaiDesignTokens.spacing3,
            TongtaiDesignTokens.spacing4,
            0,
          ),
          child: Text(
            l10n.searchResultCount(results.length),
            style: TongtaiDesignTokens.captionStyle.copyWith(
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
        ),
        for (final entry in sections.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TongtaiDesignTokens.spacing4,
              TongtaiDesignTokens.spacing3,
              TongtaiDesignTokens.spacing4,
              TongtaiDesignTokens.spacing2,
            ),
            child: Text(
              entry.key,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final m in entry.value)
            _ResultTile(message: m, keyword: keyword),
        ],
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.message, required this.keyword});

  final ChatMessage message;
  final String keyword;

  bool get _fromSeller => message.sender == ChatSender.seller;

  @override
  Widget build(BuildContext context) {
    final who = _fromSeller ? context.l10n.chatYou : 'Workizen AI';
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}';
    return ListTile(
      leading: _fromSeller
          ? const CircleAvatar(
              radius: 16,
              backgroundColor: TongtaiDesignTokens.lightHover,
              child: Icon(Icons.person_outline, size: 18),
            )
          : const TongtaiFoxMascot.avatar(size: 32),
      title: Text('$who · $time', style: TongtaiDesignTokens.captionStyle),
      subtitle: _Highlighted(text: message.text, keyword: keyword),
    );
  }
}

/// Renders [text] with every case-insensitive occurrence of [keyword] bolded.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.keyword});

  final String text;
  final String keyword;

  @override
  Widget build(BuildContext context) {
    final base = TongtaiDesignTokens.smallStyle.copyWith(
      color: TongtaiDesignTokens.lightTextPrimary,
    );
    if (keyword.isEmpty) return Text(text, style: base);

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKey = keyword.toLowerCase();
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerKey, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: TongtaiDesignTokens.financePurple,
            backgroundColor: TongtaiDesignTokens.financeVioletText.withValues(
              alpha: 0.12,
            ),
          ),
        ),
      );
      start = index + keyword.length;
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('chat-search-prompt'),
      child: Text(
        context.l10n.chatSearchPrompt,
        style: TongtaiDesignTokens.smallStyle.copyWith(
          color: TongtaiDesignTokens.lightTextSecondary,
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('chat-search-empty'),
      child: Padding(
        padding: const EdgeInsets.all(TongtaiDesignTokens.spacing8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TongtaiFoxMascot.face(size: 64),
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              context.l10n.chatSearchNoResults,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
