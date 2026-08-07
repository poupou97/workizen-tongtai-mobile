import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Không bao giờ tự động gộp bản ghi khách** — ADR-TON-024 luật 4 (WTM-291).
///
/// ## Vì sao luật này cần một suite riêng, còn ba luật kia thì không
///
/// Luật 1–3 nói về *mức tin cậy nào làm được gì*, và chúng nằm trong hành vi —
/// test hành vi bình thường bắt được (`identity_resolution_test`).
///
/// Luật 4 khác loại: nó cấm một **khả năng** tồn tại. Không test hành vi nào
/// chứng minh được *"không có đường nào làm việc X"* — nó chỉ chứng minh những
/// đường đã nghĩ ra. Ngày ai đó thêm `mergeCustomers(a, b)` vì thấy tiện, mọi
/// test hành vi vẫn xanh.
///
/// ## Ba lớp, mạnh dần
///
/// 1. **Không hàm nào nhận hai `customerId` và trả về một** — đúng câu chữ của
///    tiêu chí nghiệm thu WTM-291.
/// 2. **Không tên hàm nào mang hình dạng "gộp"** — bắt ý định, kể cả khi thân
///    hàm hiện tại vô hại; cái tên là thứ người sau đọc rồi gọi.
/// 3. **Seam này không với tới được `customers_table`** — lớp quyết định.
///    Hai lớp trên bắt hình dạng đã hình dung ra; lớp này nói một điều mạnh
///    hơn và không cần hình dung: đường ghi ở đây **không chạm** bảng khách,
///    nên nó không xoá hay nhập bản ghi khách nào được, dù đặt tên hàm là gì.
///
/// ## Cùng họ với các suite governance khác
///
/// `derived_data_governance_test` canh *ai sở hữu một con số*;
/// `error_handling_governance_test` canh *màn hình biểu diễn lỗi thế nào*.
/// Cả ba cùng một hình: một luật kiến trúc mà **không có gì thất bại** khi nó
/// bị vi phạm, nên phải dựng cái để thất bại.
void main() {
  /// Vùng code luật này áp dụng. Thêm file vào seam danh tính ⇒ thêm vào đây.
  const seamFiles = <String>[
    'lib/features/tongtai/consumer/external_identity.dart',
    'lib/features/tongtai/consumer/external_identity_repository.dart',
    'lib/features/tongtai/consumer/identity_resolver.dart',
  ];

  /// Bảng Drift duy nhất seam này được phép chạm.
  ///
  /// `customersTable` **cố ý vắng mặt**: một seam không với tới bảng khách thì
  /// không gộp khách được, và đó là bảo đảm không phụ thuộc vào việc ai đó đặt
  /// tên hàm khéo đến đâu.
  const allowedTables = <String>{
    'externalIdentitiesTable',
    'identityLinkEventsTable',
  };

  /// Tên hàm mang hình dạng "gộp hai bản ghi làm một".
  const mergeShapedNames = <String>[
    'merge',
    'combinecustomer',
    'consolidate',
    'dedupecustomer',
    'unifycustomer',
    'absorb',
    'foldinto',
  ];

  final customerIdParam = RegExp(r'\b[a-zA-Z]*[cC]ustomerId\b');

  /// Kiểu trả về "một khách" — `String`, `Customer`, hoặc bọc trong `Future`.
  final returnsACustomer = RegExp(r'\b(String|Customer[A-Za-z]*)\b');

  /// Bỏ chú thích trước khi quét.
  ///
  /// Bắt buộc, không phải tối ưu: doc của chính seam này giải thích luật bằng
  /// câu *"không hàm nào nhận hai `customerId`"* — quét cả chú thích thì tài
  /// liệu mô tả luật lại thành thứ vi phạm luật.
  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return noBlock
        .split('\n')
        .map((line) {
          final i = line.indexOf('//');
          return i == -1 ? line : line.substring(0, i);
        })
        .join('\n');
  }

  /// Danh sách ngoặc này là **khai báo** hàm, hay chỉ là một **lời gọi**?
  ///
  /// Phân biệt được là bắt buộc, và bản nháp đầu của suite này sai đúng chỗ
  /// đó: `ExternalIdentity(customerId: row.customerId, …)` là lời gọi hợp lệ,
  /// nhưng đọc thô thì nó chứa chữ `customerId` **hai lần** và bị báo vi phạm.
  /// Một luật cấm hay báo động giả sẽ bị người ta tắt đi, nên nó phải chính xác
  /// mới có giá trị.
  ///
  /// Nhận dạng bằng dấu hiệu **dương tính** — *"mọi đối số trông giống một
  /// tham số"* — chứ không phải bằng danh sách các dạng lời gọi cần loại trừ.
  /// Lý do: danh sách loại trừ luôn thiếu một dạng (bản nháp thứ hai lọc được
  /// `Foo(a: b)` nhưng vẫn dính `.insert(Foo(a: b))`), còn dấu hiệu dương tính
  /// thì đóng.
  ///
  /// Một tham số Dart luôn có dạng `Kiểu tên`, `this.tên` hoặc `super.tên` —
  /// tức **hai định danh liền nhau**, thứ mà một biểu thức không có.
  bool looksLikeDeclaration(String params) {
    var depth = 0;
    var segment = StringBuffer();
    final segments = <String>[];
    for (final ch in params.split('')) {
      if (ch == '(' || ch == '[' || ch == '{' || ch == '<') depth++;
      if (ch == ')' || ch == ']' || ch == '}' || ch == '>') depth--;
      if (ch == ',' && depth == 0) {
        segments.add(segment.toString());
        segment = StringBuffer();
        continue;
      }
      segment.write(ch);
    }
    segments.add(segment.toString());

    final modifiers = RegExp(r'^(required|covariant|final|const)\s+');
    final typeThenName = RegExp(
      r'^[A-Za-z_$][A-Za-z0-9_$]*'
      r'(\s*<.*>)?\s*\??\s+'
      r'[a-zA-Z_$][A-Za-z0-9_$]*',
    );
    final fieldFormal = RegExp(r'^(this|super)\.');

    return segments.every((raw) {
      var s = raw.trim();
      while (s.startsWith('{') || s.startsWith('[')) {
        s = s.substring(1).trim();
      }
      while (s.endsWith('}') || s.endsWith(']')) {
        s = s.substring(0, s.length - 1).trim();
      }
      while (modifiers.hasMatch(s)) {
        s = s.replaceFirst(modifiers, '').trim();
      }
      if (s.isEmpty) return true; // dấu phẩy cuối cùng
      return fieldFormal.hasMatch(s) || typeThenName.hasMatch(s);
    });
  }

  /// Kiểu đứng ngay trước tên hàm — `Future<void>`, `IdentityDecision`, …
  ///
  /// Cần vì luật là *"nhận hai và **trả về một**"*: một hàm ghi lịch sử nhận
  /// `fromCustomerId` + `toCustomerId` và trả `Future<void>` **không** gộp gì
  /// cả — nó ghi lại một lần đổi chủ. Bỏ vế trả về đi thì suite này cấm luôn
  /// việc ghi nhật ký, và một luật cấm quá tay sẽ bị gỡ.
  String returnTypeBefore(String code, int nameStart) {
    var i = nameStart - 1;
    while (i >= 0 && (code[i] == ' ' || code[i] == '\n')) {
      i--;
    }
    if (i < 0) return '';
    final end = i + 1;
    if (code[i] == '>') {
      var depth = 0;
      while (i >= 0) {
        if (code[i] == '>') depth++;
        if (code[i] == '<') {
          depth--;
          if (depth == 0) {
            i--;
            break;
          }
        }
        i--;
      }
    }
    final typeChars = RegExp(r'[A-Za-z0-9_$.?]');
    while (i >= 0 && typeChars.hasMatch(code[i])) {
      i--;
    }
    return code.substring(i + 1, end).trim();
  }

  /// Mọi khai báo `(tên, tham số, kiểu trả về)` trong một file.
  ///
  /// Quét thủ công theo độ sâu ngoặc thay vì regex: tham số Dart chứa ngoặc
  /// lồng (`Future<void> Function(String)`), và một regex ngoặc-cân-bằng thì
  /// không viết được.
  List<(String name, String params, String returnType)> declarations(
    String source,
  ) {
    final code = stripComments(source);
    final out = <(String, String, String)>[];
    final nameChars = RegExp(r'[A-Za-z0-9_$]');
    for (var i = 0; i < code.length; i++) {
      if (code[i] != '(') continue;
      var end = i;
      while (end > 0 && code[end - 1] == ' ') {
        end--;
      }
      var start = end;
      while (start > 0 && nameChars.hasMatch(code[start - 1])) {
        start--;
      }
      if (start == end) continue; // `(a + b)` — không phải lời gọi/khai báo
      var depth = 0;
      var close = -1;
      for (var j = i; j < code.length; j++) {
        if (code[j] == '(') depth++;
        if (code[j] == ')') {
          depth--;
          if (depth == 0) {
            close = j;
            break;
          }
        }
      }
      if (close == -1) continue;
      final params = code.substring(i + 1, close);
      if (params.trim().isNotEmpty && looksLikeDeclaration(params)) {
        out.add((
          code.substring(start, end),
          params,
          returnTypeBefore(code, start),
        ));
        // Nhảy qua phần trong: một danh sách tham số không chứa khai báo nào
        // khác, và tham số kiểu hàm (`void Function(String a) cb`) thì đã nằm
        // trong chuỗi vừa lấy nên vẫn được đếm.
        i = close;
      }
      // Với lời gọi thì KHÔNG nhảy qua — bên trong nó vẫn có thể còn khai báo
      // (closure có tham số kiểu tường minh), và bỏ sót là hướng sai duy nhất
      // nguy hiểm ở đây.
    }
    return out;
  }

  bool isMerge((String, String, String) d) {
    final twoIds = customerIdParam.allMatches(d.$2).length >= 2;
    return twoIds && returnsACustomer.hasMatch(d.$3);
  }

  late final Map<String, List<(String, String, String)>> parsed;
  late final Map<String, String> sources;

  setUpAll(() {
    sources = {for (final p in seamFiles) p: File(p).readAsStringSync()};
    sources.forEach((_, _) {});
    parsed = {
      for (final entry in sources.entries) entry.key: declarations(entry.value),
    };
  });

  test('bộ quét thật sự đọc được code (chống PASS GIẢ)', () {
    // Bài học đã trả giá hai lần trong dự án này: một phép quét không tìm thấy
    // gì vì nó **không phân tích được gì** trông y hệt một phép quét sạch.
    // Nên trước khi tin kết luận "không có vi phạm", chứng minh bộ quét chạy.
    for (final path in seamFiles) {
      expect(File(path).existsSync(), isTrue, reason: '$path phải tồn tại');
      expect(
        parsed[path],
        isNotEmpty,
        reason:
            '$path: bộ quét không đọc ra khai báo nào — nó hỏng, không sạch',
      );
    }
    final allNames = parsed.values.expand((d) => d.map((e) => e.$1)).toSet();
    // Vài tên đã biết chắc có mặt. Đổi tên chúng thì test này đỏ trước, và đó
    // là điều đúng: bộ quét phải được cập nhật cùng lúc với seam.
    expect(
      allNames,
      containsAll(['resolve', 'moveToCustomer', 'link', 'unlink']),
      reason: 'bộ quét không thấy các hàm đã biết là có ⇒ nó đang bỏ sót',
    );
    // …và đọc được cả kiểu trả về, thứ vế thứ hai của luật dựa vào.
    final move = parsed.values
        .expand((d) => d)
        .firstWhere((d) => d.$1 == 'moveToCustomer');
    expect(move.$3, 'Future<void>');
  });

  test('lớp 1 · không hàm nào nhận hai customerId và TRẢ VỀ một', () {
    final violations = <String>[];
    for (final entry in parsed.entries) {
      for (final d in entry.value) {
        if (isMerge(d)) {
          violations.add('${entry.key} · ${d.$3} ${d.$1}(${d.$2})');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'ADR-TON-024 luật 4: "hai khách vào, một khách ra" là hình dạng của '
          'phép gộp. Sửa liên kết = moveToCustomer (một danh tính đổi chủ, '
          'không bản ghi khách nào biến mất).\n${violations.join('\n')}',
    );
  });

  test('lớp 2 · không tên hàm nào mang hình dạng "gộp"', () {
    final violations = <String>[];
    for (final entry in parsed.entries) {
      for (final d in entry.value) {
        final lower = d.$1.toLowerCase();
        if (mergeShapedNames.any((m) => lower == m || lower.startsWith(m))) {
          violations.add('${entry.key} · ${d.$1}');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Gộp hai bản ghi khách trùng là bài toán KHÁC — nó cần luồng UI '
          'riêng có xem trước và hoàn tác, không phải một hàm trong seam '
          'connector.\n${violations.join('\n')}',
    );
  });

  test('lớp 3 · seam KHÔNG với tới bảng khách', () {
    // Lớp quyết định. Hai lớp trên bắt những hình dạng đã hình dung ra được;
    // lớp này nói một điều mạnh hơn: đường ghi ở đây không chạm `customers_
    // table`, nên nó không xoá hay nhập bản ghi khách nào được, bất kể hàm
    // được đặt tên là gì.
    final all = <String>{};
    for (final entry in sources.entries) {
      // `_?db\.` chứ không phải `db\.`: trường trong repository tên `_db`, và
      // `\b` không khớp giữa `_` với `d`. Bản đầu viết `\bdb\.` nên khớp 0
      // lần — tập rỗng, mà tập rỗng thì "không chạm bảng cấm" luôn đúng. Đúng
      // kiểu PASS GIẢ mà `expect(all, allowedTables)` bên dưới sinh ra để
      // chặn, và nó đã chặn thật.
      all.addAll(
        RegExp(
          r'\b_?db\.([a-zA-Z]+Table)\b',
        ).allMatches(stripComments(entry.value)).map((m) => m.group(1)!),
      );
    }

    // Bịt đường vòng: với tới bảng khách qua một repository khác cũng là với
    // tới bảng khách.
    for (final entry in sources.entries) {
      expect(
        entry.value,
        isNot(contains('customer_repository.dart')),
        reason:
            '${entry.key} import CustomerRepository ⇒ seam này ghi được vào '
            'bản ghi khách, và lớp 3 không còn nghĩa gì',
      );
    }

    // Chống PASS GIẢ: nếu biểu thức trên không khớp gì, tập rỗng ⊆ mọi tập và
    // test xanh oan. Nên trước hết phải thấy ĐÚNG hai bảng seam thật sự dùng.
    expect(
      all,
      allowedTables,
      reason:
          'seam danh tính chỉ được chạm $allowedTables. Thấy: $all\n'
          'Chạm được `customersTable` là mở đường cho phép gộp — dù không hàm '
          'nào tên là "merge".',
    );
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    // Một luật cấm chỉ đáng tin khi đã thấy nó bắt được thứ nó phải bắt. Không
    // có test này thì ba test trên xanh vĩnh viễn kể cả khi biểu thức chính
    // quy sai chính tả.
    const offending = '''
      class Bad {
        Future<String> mergeCustomers(String customerId, String otherCustomerId)
            async => customerId;
      }
    ''';
    final decls = declarations(offending);
    expect(decls.where(isMerge), isNotEmpty, reason: 'phải bắt được lớp 1');
    expect(
      decls.any((d) => d.$1.toLowerCase().startsWith('merge')),
      isTrue,
      reason: 'phải bắt được lớp 2',
    );
  });

  test('ghi nhật ký đổi chủ KHÔNG bị tính là gộp', () {
    // Chống cấm quá tay: một hàm nhận `fromCustomerId` + `toCustomerId` và trả
    // `Future<void>` là hàm ghi lịch sử. Cấm luôn nó thì suite này cấm mất
    // đúng thứ làm cho tự động hoá hoàn tác được.
    const auditLog = '''
      Future<void> writeEvent({
        required String identityId,
        String? fromCustomerId,
        String? toCustomerId,
      }) async {}
    ''';
    final decls = declarations(auditLog);
    expect(decls.map((d) => d.$1), contains('writeEvent'));
    expect(decls.where(isMerge), isEmpty);
  });

  test('lời gọi `customerId: row.customerId` KHÔNG bị tính là vi phạm', () {
    // Đây là lỗi bản nháp đầu tiên của chính suite này: đọc thô thì một lời
    // gọi hợp lệ chứa chữ `customerId` hai lần. Giữ lại làm test hồi quy —
    // một luật cấm hay báo động giả sẽ bị người ta tắt đi.
    const legitimateCall = '''
      ExternalIdentity read(Row row) => ExternalIdentity(
        id: row.id,
        customerId: row.customerId,
        fromCustomerId: row.fromCustomerId,
        toCustomerId: row.toCustomerId,
      );
    ''';
    final decls = declarations(legitimateCall);
    expect(decls.where(isMerge), isEmpty);
    expect(decls.map((d) => d.$1), contains('read'));
  });

  test('chú thích giải thích luật KHÔNG bị tính là vi phạm', () {
    // Chống một kiểu đỏ giả cũng thật: doc của seam nói về "hai customerId" để
    // giải thích vì sao không có hàm nào như vậy.
    const documented = '''
      /// không hàm nào nhận hai customerId và một otherCustomerId nữa
      String link(String customerId) => customerId;
    ''';
    expect(declarations(documented).where(isMerge), isEmpty);
  });
}
