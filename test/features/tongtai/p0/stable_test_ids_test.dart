import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P0 Process Hardening §5 (ADR-TON-015 §3) — **Stable Test IDs**.
///
/// Every production screen (Implementation Level ≥ 2) must expose stable
/// Widget Keys so behaviour tests never depend on displayed text — text moves
/// with the locale (ADR-TON-007), and a text-based test silently stops
/// covering the screen the moment a label changes.
///
/// The registry below mirrors
/// `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`. A new L2+ screen must be
/// added here in the SAME PR — that is the point: a screen with no data path
/// and no keys (the `Consumer` static-shell bug, Testing Bible P-03) can no
/// longer slip in unnoticed.
void main() {
  /// screen file (under lib/features/tongtai/ui/screens/) → key prefix.
  const productionScreens = <String, String>{
    'tongtai_home_screen.dart': 'home',
    'tongtai_consumer_screen.dart': 'consumer',
    'tongtai_producer_screen.dart': 'producer',
    'tongtai_inventory_screen.dart': 'inventory',
    'tongtai_customer_list_screen.dart': 'customer',
    'tongtai_goals_screen.dart': 'goals',
    'tongtai_finance_screen.dart': 'finance',
    'tongtai_timeline_screen.dart': 'timeline',
    'tongtai_opportunity_feed_screen.dart': 'opportunity',
    'tongtai_opportunity_detail_screen.dart': 'opportunity',
    'tongtai_reports_screen.dart': 'reports',
    'tongtai_forecast_screen.dart': 'forecast',
    'tongtai_customer_risk_screen.dart': 'risk',
    'tongtai_agent_screen.dart': 'agent',
    'tongtai_export_screen.dart': 'export',
    'tongtai_backup_screen.dart': 'backup',
    'tongtai_more_screen.dart': 'more',
    'tongtai_chat_screen.dart': 'chat',
    'tongtai_unified_search_screen.dart': 'search',
    'tongtai_stock_alerts_screen.dart': 'stock',
    'tongtai_supplier_search_screen.dart': 'supplier-search',
    'tongtai_supplier_favorites_screen.dart': 'supplier-fav',
    'tongtai_supplier_detail_screen.dart': 'supplier-detail',
    'tongtai_customer_history_screen.dart': 'history',
    'tongtai_ai_key_screen.dart': 'ai-key',
    // Flow screens (forms/pickers/detail) — reached from a domain screen but
    // still Level 2: they render production records and must be drivable by
    // key, not by label text.
    'tongtai_chat_search_screen.dart': 'chat',
    'tongtai_create_order_screen.dart': 'create-order',
    'tongtai_customer_form_screen.dart': 'customer',
    'tongtai_goal_detail_screen.dart': 'goal',
    'tongtai_goal_form_screen.dart': 'goal',
    'tongtai_inventory_picker_screen.dart': 'picker',
    'tongtai_key_scan_screen.dart': 'key-scan',
    'tongtai_onboarding_conversation_screen.dart': 'onboarding',
    'tongtai_product_form_screen.dart': 'product',
    'tongtai_transaction_form_screen.dart': 'transaction',
  };

  /// Screens that render a record list → must key each row with the record id
  /// (`<prefix>-item-<id>`), otherwise a contract test cannot prove the rows
  /// the summary counted are the rows the user sees.
  const listScreens = <String>{
    'tongtai_inventory_screen.dart',
    'tongtai_customer_list_screen.dart',
    'tongtai_goals_screen.dart',
    'tongtai_unified_search_screen.dart',
    'tongtai_stock_alerts_screen.dart',
    'tongtai_supplier_search_screen.dart',
    'tongtai_supplier_favorites_screen.dart',
    'tongtai_customer_risk_screen.dart',
    // Every month in the analysis window is a row, empties included — the
    // forecast history is a record list like any other (WTM-160).
    'tongtai_forecast_screen.dart',
  };

  /// Màn hiện danh sách bản ghi bằng một **widget dùng chung**.
  ///
  /// Màn Tổng Tài và thẻ brief trên Home hiện CÙNG một việc, nên hàng được
  /// dựng ở `widgets/tongtai_brief_widgets.dart` chứ không ở file màn. Viết
  /// hai lần thì hai bề mặt sẽ nói khác nhau về cùng một khách (P-27).
  ///
  /// Luật "mỗi hàng có key theo id" vẫn phải đúng — chỉ là phải tìm ở đúng
  /// chỗ. Bỏ qua ở đây sẽ là một lỗ mà màn tiếp theo chui lọt.
  const sharedRowWidgets = <String>[
    'lib/features/tongtai/ui/widgets/tongtai_brief_widgets.dart',
    'lib/features/tongtai/ui/widgets/tongtai_brief_card.dart',
  ];

  final keyLiteral = RegExp(r"Key\(\s*'([^']+)'");

  Map<String, List<String>> keysPerScreen() {
    final result = <String, List<String>>{};
    final dir = Directory('lib/features/tongtai/ui/screens');
    for (final entry in productionScreens.entries) {
      final file = File('${dir.path}/${entry.key}');
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'registry lists ${entry.key} but the file is gone — update '
            'docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md and this test',
      );
      result[entry.key] = keyLiteral
          .allMatches(file.readAsStringSync())
          .map((m) => m.group(1)!)
          .toList();
    }
    return result;
  }

  test('every production (L2+) screen declares stable keys', () {
    final offenders = <String>[];
    keysPerScreen().forEach((file, keys) {
      final prefix = productionScreens[file]!;
      final owned = keys.where((k) => k.startsWith('$prefix-')).toList();
      if (owned.isEmpty) {
        offenders.add(
          '$file: no key starting with "$prefix-" '
          '(found: ${keys.isEmpty ? 'NONE' : keys.take(5).join(', ')})',
        );
      }
    });
    expect(
      offenders,
      isEmpty,
      reason:
          'Màn production (L2+) phải có stable test ID theo quy ước '
          '<screen>-<role> — xem docs/04-DELIVERY/TESTING-BIBLE.md:\n'
          '${offenders.join('\n')}',
    );
  });

  test('widget hàng dùng chung vẫn key theo id bản ghi', () {
    // Tìm `…-item-$item.id` bất kể tiền tố là hằng (`home-brief-item-`) hay
    // biến (`$keyPrefix-item-`). Kiểm cái CÓ MẶT trong key, không kiểm cách
    // viết chuỗi — một luật bám vào cú pháp sẽ đỏ oan ở lần đổi tên biến đầu
    // tiên, và một luật hay đỏ oan sẽ bị tắt đi.
    final rowKey = RegExp(r"Key\(\s*'[^']*-item-\$\{?item\.id");
    for (final path in sharedRowWidgets) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path biến mất');
      expect(
        rowKey.hasMatch(file.readAsStringSync()),
        isTrue,
        reason:
            '$path: hàng phải mang key "<prefix>-item-<id>" — nếu không thì '
            'không test nào chứng minh được hàng người dùng thấy đúng là hàng '
            'bản tóm tắt đã đếm',
      );
    }
  });

  test('list screens key each row with the record id (<prefix>-item-)', () {
    final offenders = <String>[];
    keysPerScreen().forEach((file, keys) {
      if (!listScreens.contains(file)) return;
      final prefix = productionScreens[file]!;
      final hasItemKey = keys.any((k) => k.startsWith('$prefix-item-'));
      if (!hasItemKey) offenders.add('$file: missing "$prefix-item-<id>" key');
    });
    expect(
      offenders,
      isEmpty,
      reason:
          'Danh sách phải gắn Key theo id bản ghi để contract test chứng minh '
          'được "records the summary counted == records the user sees":\n'
          '${offenders.join('\n')}',
    );
  });

  test('all widget keys in ui/ follow the kebab-case convention', () {
    // `<screen>-<role>[-<qualifier>]`; interpolated ids are allowed at the end
    // (`customer-item-${c.id}` reaches this scan as `customer-item-`).
    final convention = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*-?$');
    final offenders = <String>[];
    for (final f
        in Directory('lib/features/tongtai/ui')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in keyLiteral.allMatches(lines[i])) {
          final value = m.group(1)!;
          if (value.contains(r'$')) continue; // interpolated id tail
          if (!convention.hasMatch(value)) {
            offenders.add('${f.path}:${i + 1}: Key(\'$value\')');
          }
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Key phải kebab-case theo <screen>-<role>[-<qualifier>]:\n'
          '${offenders.join('\n')}',
    );
  });
}
