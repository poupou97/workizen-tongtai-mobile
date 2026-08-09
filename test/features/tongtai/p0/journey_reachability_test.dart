import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P0 — **mọi capability L2+ phải có một User Journey dẫn tới nó**
/// (luật Founder 2026-08-02).
///
/// > *"Đối với mọi Capability L2+, phải chứng minh có ít nhất một User Journey
/// > hợp lệ dẫn tới capability đó, hoặc được đánh dấu rõ là Future Capability /
/// > Intentionally Hidden cùng lý do."*
///
/// **Vì sao luật này mạnh hơn WTM-218.** Scan của WTM-218 hỏi *"có file nào
/// trong `lib/` import file màn này không?"* — một bước, không có gốc. Một màn
/// mồ côi được một màn mồ côi khác import vẫn qua được. Ở đây câu hỏi là câu
/// người bán thực sự hỏi: **từ chỗ tôi mở app, tôi đi tới đó bằng cách nào?**
///
/// **Đồ thị suy từ code, không khai tay.** Khai tay 37 đường đi sẽ mục ngay lần
/// đổi điều hướng đầu tiên, và một bảng khai mục thì tệ hơn không có — nó nói
/// dối người đọc sau. Ở đây chỉ **ngoại lệ** mới phải khai, và ngoại lệ nào
/// cũng phải mang lý do đọc được.
///
/// Bằng chứng hành vi ở **gốc** (5 tab + các hành động một-chạm từ Home) nằm ở
/// `nav_availability_test.dart` — nó đi thật trong production wiring. Suite này
/// lo phần còn lại: từ gốc đó, mọi màn L2+ có đường tới hay không.
void main() {
  /// Điểm vào của app — nơi người bán thực sự bắt đầu.
  const roots = <String>[
    'tongtai_app_shell.dart',
    'tongtai_root_gate.dart',
    'tongtai_home_screen.dart',
  ];

  /// Màn L2+ **cố ý** chưa có đường vào. Mỗi mục phải nói **vì sao**, và test
  /// thứ hai bên dưới bắt mục đã hết hạn.
  const declared = <String, String>{
    'tongtai_supplier_search_screen.dart':
        'FUTURE CAPABILITY — Producer (Founder 2026-08-01: "Không cố xây AI '
        'bằng dữ liệu giả"). Danh bạ là SupplierSearchService.sample(), '
        'tức nhà cung cấp bịa; mở đường vào là trưng dữ liệu giả cho người '
        'bán thật. Chờ nguồn dữ liệu thật — Founder gate, không phải bỏ '
        'sót (WTM-218).',
  };

  /// Mức L của từng màn, chép từ `docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md`.
  /// Màn nào không có ở đây mà nằm trong `ui/screens/` sẽ bị test cuối bắt —
  /// thêm màn mới buộc phải khai mức, và khai mức buộc phải nghĩ tới đường vào.
  const levelOf = <String, int>{
    // L4
    'tongtai_reports_screen.dart': 4,
    'tongtai_opportunity_detail_screen.dart': 4,
    // L3
    'tongtai_connections_screen.dart': 3,
    'tongtai_import_screen.dart': 3,
    'tongtai_home_screen.dart': 3,
    'tongtai_consumer_screen.dart': 3,
    'tongtai_producer_screen.dart': 3,
    'tongtai_inventory_screen.dart': 3,
    'tongtai_customer_list_screen.dart': 3,
    'tongtai_goals_screen.dart': 3,
    'tongtai_finance_screen.dart': 3,
    'tongtai_timeline_screen.dart': 3,
    'tongtai_opportunity_feed_screen.dart': 3,
    'tongtai_forecast_screen.dart': 3,
    'tongtai_customer_risk_screen.dart': 3,
    'tongtai_agent_screen.dart': 3,
    'tongtai_brief_story_screen.dart': 3,
    'tongtai_activity_screen.dart': 3,
    'tongtai_autonomy_screen.dart': 2,
    'tongtai_export_screen.dart': 3,
    'tongtai_more_screen.dart': 3,
    'tongtai_chat_screen.dart': 3,
    'tongtai_chat_search_screen.dart': 3,
    'tongtai_unified_search_screen.dart': 3,
    'tongtai_customer_history_screen.dart': 3,
    'tongtai_business_profile_screen.dart': 3,
    'tongtai_feedback_screen.dart': 3,
    'tongtai_journey_screen.dart': 3,
    'tongtai_onboarding_conversation_screen.dart': 3,
    'tongtai_supplier_search_screen.dart': 3,
    'tongtai_supplier_favorites_screen.dart': 3,
    'tongtai_business_inputs_screen.dart': 3,
    'tongtai_ai_key_screen.dart': 3,
    'tongtai_key_scan_screen.dart': 3,
    'tongtai_backup_screen.dart': 3,
    'tongtai_privacy_policy_screen.dart': 3,
    'tongtai_about_screen.dart': 3,
    // L2
    'tongtai_create_order_screen.dart': 2,
    'tongtai_customer_form_screen.dart': 2,
    'tongtai_product_form_screen.dart': 2,
    'tongtai_goal_form_screen.dart': 2,
    'tongtai_transaction_form_screen.dart': 2,
    'tongtai_goal_detail_screen.dart': 2,
    'tongtai_inventory_picker_screen.dart': 2,
    'tongtai_stock_alerts_screen.dart': 2,
    'tongtai_supplier_detail_screen.dart': 2,
    'tongtai_business_input_form_screen.dart': 2,
  };

  /// Bỏ comment trước khi tìm cạnh.
  ///
  /// Không bỏ thì một dòng tài liệu *"mở TongtaiSupplierSearchScreen."* tạo ra
  /// một **cạnh ma**: đồ thị nói người bán tới được, trong khi thứ duy nhất
  /// dẫn tới đó là một câu văn. Suite này tồn tại để không nói dối, nên nó
  /// phải nhìn code chứ không nhìn lời kể về code.
  String withoutComments(String src) => src
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .split('\n')
      .map((line) {
        final i = line.indexOf('//');
        // Không cắt trong chuỗi ('https://…') — chỉ cắt khi trước đó số dấu
        // nháy là chẵn, tức con trỏ đang ở ngoài chuỗi.
        if (i < 0) return line;
        final before = line.substring(0, i);
        final quotes = "'".allMatches(before).length;
        return quotes.isEven ? before : line;
      })
      .join('\n');

  /// Mọi file `.dart` dưới `lib/`, đọc một lần, đã bỏ comment.
  final sources = <String, String>{
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
      f.uri.pathSegments.last: withoutComments(f.readAsStringSync()),
  };

  /// Cạnh A → B: file A **dựng** một màn khai báo trong file B.
  ///
  /// Dùng "dựng" chứ không chỉ "import": một file có thể import màn để khai
  /// kiểu trong chữ ký hàm mà không bao giờ mở nó. `tongtai.dart` (barrel)
  /// bị loại vì nó re-export tất cả, tức nối mọi thứ với mọi thứ và biến
  /// bài kiểm này thành vô nghĩa.
  Map<String, Set<String>> buildGraph() {
    final classToFile = <String, String>{};
    sources.forEach((file, src) {
      for (final m in RegExp(r'class (Tongtai\w+)\b').allMatches(src)) {
        classToFile[m.group(1)!] = file;
      }
    });

    final edges = <String, Set<String>>{};
    sources.forEach((file, src) {
      if (file == 'tongtai.dart') return;
      final out = <String>{};
      classToFile.forEach((cls, target) {
        if (target == file) return;
        // `Foo(`, `const Foo(`, `Foo.named(` — mọi cách dựng widget.
        if (RegExp('(?<![A-Za-z0-9_])$cls\\s*[(.]').hasMatch(src)) {
          out.add(target);
        }
      });
      edges[file] = out;
    });
    return edges;
  }

  /// Mọi file tới được từ [roots] (BFS).
  Set<String> reachableFromRoots(Map<String, Set<String>> edges) {
    final seen = <String>{...roots};
    final queue = [...roots];
    while (queue.isNotEmpty) {
      for (final next in edges[queue.removeAt(0)] ?? const <String>{}) {
        if (seen.add(next)) queue.add(next);
      }
    }
    return seen;
  }

  test('mọi màn L2+ có một đường đi từ điểm vào của app', () {
    final reachable = reachableFromRoots(buildGraph());
    final unreachable = <String>[];
    levelOf.forEach((file, level) {
      if (level < 2) return;
      if (declared.containsKey(file)) return;
      if (!reachable.contains(file)) unreachable.add('$file (L$level)');
    });

    expect(
      unreachable,
      isEmpty,
      reason:
          'Không có đường nào từ điểm vào của app tới những màn này ⇒ người '
          'bán không bao giờ mở được chúng, dù mọi suite chất lượng vẫn xanh '
          '(bài học WTM-218: sáu lượt governance đánh bóng một màn mồ côi). '
          'Nối vào một hành trình có thật, xoá, hoặc khai vào `declared` kèm '
          'lý do:\n${unreachable.join('\n')}',
    );
  });

  test('ngoại lệ nào cũng mang lý do, và không mục', () {
    final reachable = reachableFromRoots(buildGraph());
    for (final entry in declared.entries) {
      expect(
        File('lib/features/tongtai/ui/screens/${entry.key}').existsSync(),
        isTrue,
        reason: '${entry.key} không còn tồn tại — gỡ ngoại lệ',
      );
      expect(
        entry.value.length,
        greaterThan(80),
        reason:
            '${entry.key}: lý do quá ngắn để người đọc sau hiểu được quyết '
            'định. "TODO" hay "chưa làm" không phải lý do.',
      );
      expect(
        RegExp('FUTURE CAPABILITY|INTENTIONALLY HIDDEN').hasMatch(entry.value),
        isTrue,
        reason:
            '${entry.key}: luật Founder đòi nhãn rõ — Future Capability hoặc '
            'Intentionally Hidden.',
      );
      expect(
        reachable.contains(entry.key),
        isFalse,
        reason:
            '${entry.key} nay ĐÃ tới được — gỡ khỏi `declared`, đừng để lời '
            'giải thích cũ nói dối người đọc sau',
      );
    }
  });

  test('màn mới buộc phải khai mức L (không lọt lưới im lặng)', () {
    final onDisk = Directory('lib/features/tongtai/ui/screens')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.dart'))
        .toSet();

    expect(
      onDisk.difference(levelOf.keys.toSet()),
      isEmpty,
      reason:
          'Màn chưa khai mức trong suite này. Khai mức (theo '
          'docs/02-ARCHITECTURE/UI-IMPLEMENTATION-LEVELS.md) — việc khai buộc '
          'phải trả lời "người bán tới đây bằng đường nào".',
    );
    expect(
      levelOf.keys.toSet().difference(onDisk),
      isEmpty,
      reason: 'Khai mức cho màn không còn tồn tại — gỡ đi',
    );
  });
}
