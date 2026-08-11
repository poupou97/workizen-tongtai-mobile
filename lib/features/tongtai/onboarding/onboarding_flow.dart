/// Máy trạng thái của onboarding V2 — WTM-350 (S1, Epic WTM-349).
///
/// ## Vì sao đảo ngược quan hệ
///
/// Onboarding V1 hỏi bốn câu hồ sơ rồi thả người bán vào một ứng dụng trống.
/// Người bán trả lời xong và **không nhận lại gì**. V2 đi theo chiều ngược
/// lại: `CONNECT/TELL → AI LEARNS → FIRST INSIGHT → CHOOSE GOAL → FIRST PLAN
/// → HOME`, và kết thúc bằng việc người bán *đã nhìn thấy một điều đúng về
/// chính doanh nghiệp mình*.
///
/// ## Ba đường, một máy trạng thái
///
/// Điều dễ làm sai nhất ở đây là để mỗi màn tự quyết định màn kế tiếp bằng một
/// cờ riêng. Làm thế thì "người chưa có dữ liệu không được vào bước phân tích"
/// trở thành một quy ước mà mọi màn phải nhớ — và chỉ cần một màn quên là
/// người bán chưa có đơn nào sẽ nhìn thấy dòng chữ *"đang phân tích 1.246 đơn
/// hàng"*.
///
/// Nên đường đi **suy ra từ một lựa chọn duy nhất** ([DataStartChoice]), và
/// danh sách màn của mỗi đường được khai báo ở [OnboardingFlow.stages]. Đường
/// B không có [OnboardingStage.analysis] trong danh sách của nó, nên nó không
/// *thể* đi vào đó — không phải "UI không vẽ nút".
library;

import 'package:flutter/foundation.dart';

import 'onboarding_conversation.dart';

/// Một màn trong luồng. Thứ tự trong enum không phải thứ tự đi — thứ tự đi nằm
/// ở [OnboardingFlow.stages], vì nó khác nhau theo đường.
enum OnboardingStage {
  /// Gặp Tổng Tài.
  welcome,

  /// Năm câu hồ sơ (WTM-351).
  profile,

  /// Đưa dữ liệu cho Tổng Tài (WTM-352).
  dataStart,

  /// Tổng Tài đang hiểu doanh nghiệp — **công việc thật** (WTM-353).
  analysis,

  /// "Tôi đã hiểu doanh nghiệp của bạn" (WTM-354).
  insight,

  /// Chọn mục tiêu (WTM-355).
  goal,

  /// Kế hoạch đầu tiên (WTM-356).
  plan,
}

/// Người bán bắt đầu bằng dữ liệu nào.
///
/// Ba lựa chọn này là **toàn bộ** những gì chạy trọn từ đầu tới cuối hôm nay.
/// Sàn thương mại điện tử và Google Drive cố ý vắng mặt: chưa có connector nào
/// tồn tại, và một nút mang tên Shopee mà không kết nối được Shopee là lời nói
/// dối đắt nhất mà một màn onboarding có thể kể.
enum DataStartChoice {
  /// Nhập tệp Excel/CSV — tái dùng `CommerceImporter`.
  csv('csv'),

  /// Bộ dữ liệu mẫu — tái dùng `SampleBusinessSeeder` (WTM-343).
  sample('sample'),

  /// Chưa có dữ liệu / đang chuẩn bị kinh doanh.
  none('none');

  const DataStartChoice(this.code);

  /// Mã canonical. **Không bao giờ là nhãn hiển thị** (ADR-TON-018).
  final String code;

  static DataStartChoice? fromCode(String? code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }

  OnboardingPath get path => switch (this) {
    DataStartChoice.csv => OnboardingPath.withData,
    DataStartChoice.sample => OnboardingPath.sample,
    DataStartChoice.none => OnboardingPath.noData,
  };
}

/// Đường đi của người bán qua onboarding.
enum OnboardingPath {
  /// A — doanh nghiệp đang chạy, nhập dữ liệu thật.
  withData,

  /// C — Golden Demo Path. Engine tính **thật** trên bộ mẫu; khác A ở chỗ dữ
  /// liệu từ đâu ra, không khác ở chỗ kết luận được tính thế nào.
  sample,

  /// B — chưa có dữ liệu. Giá trị đến từ **lập kế hoạch**, không phải từ
  /// business intelligence bịa ra.
  noData;

  /// Đường này có chạy phân tích không.
  ///
  /// Đây là câu trả lời **duy nhất** cho câu hỏi đó trong toàn bộ mã. Mọi nơi
  /// khác hỏi lại nó là một nơi nữa có thể trả lời sai.
  bool get analysesData => this != OnboardingPath.noData;
}

const List<OnboardingStage> _commonPrefix = [
  OnboardingStage.welcome,
  OnboardingStage.profile,
  OnboardingStage.dataStart,
];

/// Danh sách màn của một đường. `null` = chưa chọn ở [OnboardingStage.dataStart].
///
/// Khi chưa chọn, danh sách **dừng lại** ở `dataStart`: không có màn nào sau
/// nó, nên không đi tiếp được. Đó là cách "phải chọn một cửa" được ép bằng cấu
/// trúc chứ không bằng một câu `if` trong màn.
@visibleForTesting
List<OnboardingStage> stagesFor(OnboardingPath? path) => switch (path) {
  null => _commonPrefix,
  OnboardingPath.noData => const [
    ..._commonPrefix,
    OnboardingStage.goal,
    OnboardingStage.plan,
  ],
  _ => const [
    ..._commonPrefix,
    OnboardingStage.analysis,
    OnboardingStage.insight,
    OnboardingStage.goal,
    OnboardingStage.plan,
  ],
};

/// Tiến trình qua luồng — một **giá trị**, không phải trạng thái widget.
///
/// Giữ như giá trị để test được luồng mà không cần pump widget, và để
/// [back] là một phép trừ chứ không phải một chồng route.
@immutable
class OnboardingFlow {
  const OnboardingFlow({
    this.stageIndex = 0,
    this.conversation = const OnboardingConversation(),
    this.dataStart,
  });

  final int stageIndex;

  /// Năm câu hồ sơ. Tái dùng nguyên [OnboardingConversation] của V1 — nó đã
  /// đúng ở phần khó nhất: mọi đáp án là chip từ từ vựng đóng, nên không gì
  /// người bán gõ có thể lọt vào một prompt AI.
  final OnboardingConversation conversation;

  /// `null` cho tới khi người bán chọn ở [OnboardingStage.dataStart].
  final DataStartChoice? dataStart;

  /// Người bán tự khai *"đang chuẩn bị kinh doanh"* ở bước hồ sơ.
  ///
  /// **Suy ra**, không lưu riêng — một cờ song song với câu trả lời là hai chủ
  /// cho một khái niệm, và cách chúng lệch nhau là bài học P-27/P-28.
  ///
  /// Cố ý **không** ép sang đường B: người đang chuẩn bị kinh doanh vẫn có thể
  /// có một bảng tính hàng định nhập. Nó chỉ làm cửa *"chưa có dữ liệu"* thành
  /// gợi ý mặc định.
  bool get preparing => conversation.isPreparing;

  OnboardingPath? get path => dataStart?.path;

  List<OnboardingStage> get stages => stagesFor(path);

  /// Xong luồng. **Chưa chọn cửa thì không bao giờ xong** — một luồng chưa
  /// biết đi đường nào mà tự khai là đã hoàn tất sẽ thả người bán vào Home mà
  /// không có gì trong tay.
  bool get isComplete => path != null && stageIndex >= stages.length;

  OnboardingStage? get stage => stageIndex >= stages.length
      ? null
      : stages[stageIndex.clamp(0, stages.length - 1)];

  /// Đi tiếp. Đứng ở [OnboardingStage.dataStart] mà chưa chọn cửa nào thì
  /// **không đi được**: danh sách màn còn chưa biết dài tới đâu.
  OnboardingFlow next() {
    final last = stages.length - 1;
    if (stageIndex < last) return copyWith(stageIndex: stageIndex + 1);
    if (path == null || isComplete) return this;
    return copyWith(stageIndex: stageIndex + 1);
  }

  OnboardingFlow back() =>
      stageIndex == 0 ? this : copyWith(stageIndex: stageIndex - 1);

  /// Trả lời một câu hồ sơ.
  OnboardingFlow answerProfile(String code) =>
      copyWith(conversation: conversation.answer(code));

  /// Chọn cửa dữ liệu. Chọn lại cửa đang chọn thì **giữ nguyên** thay vì bỏ
  /// chọn: bỏ chọn ở đây sẽ đưa luồng về trạng thái không đi tiếp được, và một
  /// cú chạm nhầm không nên khoá người bán lại.
  OnboardingFlow chooseDataStart(DataStartChoice choice) =>
      copyWith(dataStart: choice);

  OnboardingFlow copyWith({
    int? stageIndex,
    OnboardingConversation? conversation,
    DataStartChoice? dataStart,
  }) => OnboardingFlow(
    stageIndex: stageIndex ?? this.stageIndex,
    conversation: conversation ?? this.conversation,
    dataStart: dataStart ?? this.dataStart,
  );
}
