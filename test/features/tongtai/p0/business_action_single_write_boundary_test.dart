import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **`BusinessAction` là cửa ghi DUY NHẤT cho mọi side effect của Agent** —
/// WTM-300 · D-3 · Founder Directive 2026-08-08 nguyên tắc 4.
///
/// ## Bằng chứng vì sao phải khoá bằng cấu trúc
///
/// COMP AI có **ba** kỷ luật ghi song song, không đường nào đủ cả ba tính chất
/// (evidence · vòng đời · idempotency). Và bề mặt **mới nhất** rơi vào đường
/// **yếu nhất**: `set_field_value` thêm 5 ngày sau fact ledger, bỏ qua hoàn
/// toàn.
///
/// Không ai làm sai. Họ chỉ **không có gì bắt kỷ luật lan sang bề mặt mới**:
/// 24 file test, 0 file kiểm ranh giới.
///
/// ## Ba lớp
///
/// 1. `plan` là **cửa duy nhất** dựng hành động; `run` là **chỗ duy nhất** side
///    effect xảy ra
/// 2. Side effect và trạng thái nằm trong **một transaction**
/// 3. Idempotency có **cả khoá lẫn vân tay payload**
void main() {
  const modelFile = 'lib/features/tongtai/action/business_action.dart';
  const execFile = 'lib/features/tongtai/action/business_action_executor.dart';
  const seamFiles = [modelFile, execFile];

  String stripComments(String source) {
    final noBlock = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    return noBlock
        .split('\n')
        .map((line) {
          final doc = line.indexOf('///');
          if (doc != -1) return line.substring(0, doc);
          final i = line.indexOf('//');
          return i == -1 ? line : line.substring(0, i);
        })
        .join('\n');
  }

  /// Thân một phương thức, dừng ở phương thức kế tiếp.
  ///
  /// Hai lần liên tiếp trong Epic này một suite governance báo động giả vì cắt
  /// phạm vi bằng `indexOf` mà **không giới hạn đầu kia**. Helper này là bản
  /// đã sửa, và nó ở đây ngay từ đầu.
  String methodBody(String source, String signature) {
    final start = source.indexOf(signature);
    if (start == -1) return '';
    final rest = source.substring(start + signature.length);
    final end = RegExp(
      r'\n  (Future|void|String|BusinessAction|@override)',
    ).firstMatch(rest);
    return signature + (end == null ? rest : rest.substring(0, end.start));
  }

  late final Map<String, String> code;

  setUpAll(() {
    code = {
      for (final f in seamFiles) f: stripComments(File(f).readAsStringSync()),
    };
  });

  test('bộ quét thật sự đọc được code (chống PASS GIẢ)', () {
    for (final f in seamFiles) {
      expect(File(f).existsSync(), isTrue, reason: '$f phải tồn tại');
      expect(code[f], isNotEmpty);
    }
    expect(code[execFile], contains('class BusinessActionExecutor'));
    expect(code[modelFile], contains('enum BusinessActionType'));
  });

  test('lớp 1 · model KHÔNG có tay để ghi', () {
    // Model là từ vựng nghiệp vụ. Nếu nó chạm DB thì "cửa duy nhất" mất nghĩa.
    final model = code[modelFile]!;
    for (final banned in [
      'package:drift/drift.dart',
      'database/database.dart',
      'local_workspace.dart',
    ]) {
      expect(model.contains(banned), isFalse, reason: '$modelFile: `$banned`');
    }
  });

  test('lớp 1b · ĐÚNG MỘT chỗ side effect được gọi', () {
    // `effect(...)` là nơi việc thật xảy ra. Chỗ thứ hai gần như chắc chắn
    // nằm ngoài transaction hoặc ngoài lease.
    final exec = code[execFile]!;
    final calls = RegExp(r'await effect\(').allMatches(exec).length;
    expect(
      calls,
      1,
      reason:
          'thấy $calls chỗ gọi side effect. Chỗ thứ hai là một đường thực thi '
          'song song',
    );
  });

  test(
    'lớp 2 · side effect nằm TRONG transaction, cùng cập nhật trạng thái',
    () {
      final run = methodBody(code[execFile]!, 'Future<ActionRunResult> run(');
      final tx = run.indexOf('_db.transaction(');
      final call = run.indexOf('await effect(');
      final ok = run.indexOf('ActionStatus.succeeded.code');

      expect(tx, greaterThan(-1), reason: '`run` phải mở transaction');
      expect(
        tx,
        lessThan(call),
        reason: 'side effect phải nằm TRONG transaction',
      );
      expect(
        call,
        lessThan(ok),
        reason:
            'trạng thái `succeeded` phải ghi SAU side effect, trong cùng '
            'transaction — nếu không thì có thể "succeeded mà chưa làm"',
      );
    },
  );

  test('lớp 2b · thất bại ghi `failed`, không im lặng', () {
    final run = methodBody(code[execFile]!, 'Future<ActionRunResult> run(');
    expect(run, contains('ActionStatus.failed.code'));
    expect(run, contains('errorCode'));
  });

  test('lớp 3 · idempotency có CẢ khoá lẫn vân tay payload', () {
    // Chỉ có khoá thì hai việc KHÁC NHAU lỡ trùng khoá sẽ lặng lẽ nuốt nhau.
    final plan = methodBody(code[execFile]!, 'Future<BusinessAction> plan(');
    expect(plan, contains('_byKey('));
    expect(
      plan,
      contains('requestHash'),
      reason: 'phải so vân tay payload, không chỉ so khoá',
    );
    expect(
      plan,
      contains('throw StateError'),
      reason: 'cùng khoá khác payload phải NÉM, không ghi đè im lặng',
    );

    // Và bảng phải có ràng buộc duy nhất, không chỉ dựa vào code.
    final table = stripComments(
      File('lib/database/tables/business_actions.dart').readAsStringSync(),
    );
    expect(table, contains('unique: true'));
    expect(table, contains('#idempotencyKey'));
  });

  test('lớp 3b · `vendor: internal` là công dân hạng nhất', () {
    // Đúng chỗ COMP AI hụt: ghi vào DB của chính mình cũng phải qua cửa, nếu
    // không sẽ sinh ra đường ghi thứ ba.
    expect(code[modelFile], contains("internal('internal')"));
  });

  test('⛔ bảy hành động cấm auto là HẰNG SỐ, không phải cấu hình', () {
    final model = code[modelFile]!;
    final marked = RegExp(r'neverAutoByDefault: true').allMatches(model).length;
    expect(
      marked,
      7,
      reason:
          'Founder duyệt đúng bảy loại (2026-08-08). Thấy $marked — thêm hoặc '
          'bớt phải qua Founder, không phải qua một PR kỹ thuật',
    );

    // Và `AutonomyRule` phải chặn tại nơi dựng, không phải lúc chạy.
    expect(
      model,
      contains('mode != AutonomyMode.auto || !actionType.neverAutoByDefault'),
    );
    expect(model, contains('mode != AutonomyMode.auto || !limits.isEmpty'));
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    const offending = '''
      class BusinessActionExecutor {
        Future<void> run() async {
          await effect(db, a);
          await effect(db, b);
        }
      }
    ''';
    expect(
      RegExp(r'await effect\(').allMatches(offending).length,
      greaterThan(1),
      reason: 'phải đếm được đường thực thi thứ hai',
    );

    const noTx = 'Future<ActionRunResult> run() async { await effect(x); }';
    expect(noTx.contains('_db.transaction('), isFalse);
  });
}
