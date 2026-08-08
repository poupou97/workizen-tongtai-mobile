import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Durable Agent phải độc lập với nơi chạy** — WTM-301 · D-4 ·
/// điều kiện Founder duyệt 2026-08-08.
///
/// > *"V1 có thể chạy khi Mobile/Compute runtime hoạt động, nhưng domain/task
/// > model **không được phụ thuộc vòng đời mobile**. Cùng một task về sau phải
/// > chạy được trên Workizen Managed Worker / Oracle VM 24/7 mà **không đổi
/// > business model**."*
///
/// ## Vì sao điều kiện này cần một suite riêng
///
/// *"Độc lập với nơi chạy"* rất dễ thành một câu hay mà không ai chứng minh
/// được. Nó chỉ trở thành hợp đồng khi có thứ **đỏ lên** lúc bị vi phạm — và
/// vi phạm ở đây trông rất vô hại: thêm một trường `appSessionId` "cho tiện
/// debug", hoặc `import 'package:flutter/widgets.dart'` để lấy `@immutable`.
///
/// ## Bốn lớp, lớp 3 là lớp quyết định
///
/// 1. Seam **không import Flutter**
/// 2. `AgentTask` **không có trường nào mang nghĩa mobile**
/// 3. **Logic nhận việc chạy được trong test thuần Dart** — bằng chứng thật
/// 4. **Đúng một** chỗ đóng một việc
void main() {
  const modelFile = 'lib/features/tongtai/agent/agent_task.dart';
  const queueFile = 'lib/features/tongtai/agent/agent_task_queue.dart';
  const pureTest = 'test/features/tongtai/agent/agent_task_pure_dart_test.dart';

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

  late final String model;
  late final String queue;

  setUpAll(() {
    model = stripComments(File(modelFile).readAsStringSync());
    queue = stripComments(File(queueFile).readAsStringSync());
  });

  test('bộ quét thật sự đọc được code (chống PASS GIẢ)', () {
    expect(File(modelFile).existsSync(), isTrue);
    expect(File(queueFile).existsSync(), isTrue);
    expect(model, contains('class AgentTask'));
    expect(queue, contains('class AgentTaskQueue'));
  });

  test('lớp 1 · seam KHÔNG import Flutter', () {
    // `@immutable` bình thường đến kèm `flutter/foundation`. Seam này khai
    // `meta` tường minh thay vì mượn qua Flutter — đó là lý do `meta` nằm
    // trong `pubspec.yaml` như một dependency trực tiếp.
    for (final entry in {modelFile: model, queueFile: queue}.entries) {
      for (final banned in [
        'package:flutter/',
        'WidgetsBinding',
        'AppLifecycleState',
        'WorkManager',
        'workmanager',
      ]) {
        expect(
          entry.value.contains(banned),
          isFalse,
          reason:
              '${entry.key} chạm `$banned` ⇒ đổi runner sẽ phải sửa code này, '
              'và điều kiện D-4 gãy',
        );
      }
    }
    expect(
      model,
      contains("import 'package:meta/meta.dart'"),
      reason: 'model lấy @immutable từ meta, không mượn qua Flutter',
    );
  });

  test('lớp 2 · KHÔNG trường nào mang nghĩa mobile', () {
    final table = stripComments(
      File('lib/database/tables/agent_tasks.dart').readAsStringSync(),
    );
    for (final banned in [
      'appSession',
      'isForeground',
      'workManager',
      'lifecycle',
      'app_session',
      'is_foreground',
    ]) {
      expect(
        model.contains(banned),
        isFalse,
        reason: 'AgentTask mang `$banned` ⇒ mô hình dính vào nơi chạy',
      );
      expect(
        table.contains(banned),
        isFalse,
        reason: 'bảng mang `$banned` ⇒ đổi runner thành đổi schema',
      );
    }
  });

  test('⭐ lớp 3 · giao thức nhận việc chạy được trong test THUẦN DART', () {
    // Đây là lớp quyết định, và nó không kiểm bằng cách đọc code — nó kiểm
    // bằng sự tồn tại của một suite dùng `package:test` thay vì `flutter_test`.
    //
    // `flutter_test` tự dựng binding, nên một test dùng nó KHÔNG chứng minh
    // được gì về việc chạy trên worker. `package:test` thì không có binding
    // nào cả: nếu logic chạy được ở đó, nó chạy được trên máy chủ.
    expect(
      File(pureTest).existsSync(),
      isTrue,
      reason: 'phải có một suite thuần Dart chứng minh điều kiện D-4',
    );
    final source = File(pureTest).readAsStringSync();
    expect(
      source,
      contains("import 'package:test/test.dart'"),
      reason: 'suite bằng chứng phải dùng package:test',
    );
    expect(
      source.contains("import 'package:flutter_test/flutter_test.dart'"),
      isFalse,
      reason: 'dùng flutter_test là tự dựng binding — bằng chứng mất hiệu lực',
    );
    expect(
      source,
      contains('isClaimableAt('),
      reason: 'phải thật sự chạy giao thức nhận việc, không chỉ dựng object',
    );
  });

  test('lớp 3b · giao thức nhận việc là hàm thuần trên model', () {
    // Nếu luật nhận việc chỉ tồn tại trong mệnh đề SQL thì nó không portable:
    // một runner không dùng SQLite sẽ phải viết lại luật.
    expect(model, contains('bool isClaimableAt(DateTime now)'));
    expect(model, contains('int compareAgentTaskPriority('));
    expect(
      queue.indexOf('compareAgentTaskPriority'),
      greaterThan(-1),
      reason: 'queue phải DÙNG hàm thuần đó, không tự sắp xếp lại',
    );
  });

  test('lớp 4 · ĐÚNG MỘT chỗ đóng một việc', () {
    // Chỗ thứ ba gần như chắc chắn bỏ qua điều kiện `finishedAt IS NULL`, và
    // hai lần đóng sẽ ghi đè kết cục của nhau.
    //
    // `(?!t\.finishedAt)` loại phép **chuyển đổi** trong `_companion` — nó chỉ
    // chép lại giá trị đã có, không đóng gì. Không loại thì con số luôn thừa
    // một, và một luật đếm sai là luật sẽ bị sửa cho khớp thay vì được tin.
    final closes = RegExp(
      r'finishedAt: Value\((?!t\.finishedAt)',
    ).allMatches(queue).length;
    expect(
      closes,
      2,
      reason: 'chỉ `finish` và `retireExhausted` được đóng việc. Thấy $closes',
    );
    expect(queue, contains('t.finishedAt.isNull()'));
  });

  test('lease là cơ chế DUY NHẤT xử lý "giữ việc rồi biến mất"', () {
    // App bị kill và worker chết là cùng một tình huống. Một cơ chế cho cả
    // hai là lý do giao thức này portable.
    expect(queue, contains('leasedUntil'));
    expect(
      queue,
      contains('t.leasedUntil.isSmallerThanValue(now)'),
      reason: 'lease hết hạn phải cho nhận lại',
    );
  });

  test('bộ quét bắt được vi phạm khi vi phạm thật sự có mặt', () {
    const offending = '''
      import 'package:flutter/widgets.dart';
      class AgentTask {
        final String appSessionId;
        final bool isForeground;
      }
    ''';
    expect(offending.contains('package:flutter/'), isTrue);
    expect(offending.contains('appSession'), isTrue);
    expect(offending.contains('isForeground'), isTrue);
  });
}
