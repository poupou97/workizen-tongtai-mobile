/// **Ngôn ngữ thị giác AI** — pattern quan trọng nhất của Tổng Tài (WTM-364).
///
/// ```
/// QUAN SÁT      (tím)      "Tổng Tài phát hiện 3 SKU có nguy cơ hết hàng."
///    ↓
/// LÝ LẼ         (neutral)  "Bán trung bình 12/ngày. Tồn còn 31."
///    ↓
/// ĐỀ XUẤT       (tím)      "Nên nhập thêm 120 sản phẩm."
///    ↓
/// HÀNH ĐỘNG     (cam)      [Tạo đơn nhập]
///    ↓
/// KẾT QUẢ       (semantic) xanh / đỏ / lam tuỳ chuyện đã xảy ra
/// ```
///
/// ## Vì sao đây là component chứ không phải một mục trong tài liệu
///
/// Một guideline viết trong tài liệu được tuân thủ đúng tới lúc có người vội.
/// Đặt trật tự vào **kiểu dữ liệu** thì màn hình muốn kể sai thứ tự cũng không
/// có chỗ để làm: [TtAiStory] nhận năm khe có tên, và nó tự dựng theo đúng trật
/// tự ấy với đúng màu của từng vai.
///
/// Ba ràng buộc mà kiểu dữ liệu ép được, còn tài liệu thì không:
///
/// 1. **Quan sát bắt buộc.** Không có quan sát thì không có gì để giải thích —
///    một thẻ mở đầu bằng đề xuất là lời khuyên không căn cứ.
/// 2. **Lý lẽ là neutral.** Tô tím cả phần *"vì sao"* sẽ làm cả thẻ thành một
///    khối tím, và người bán mất chỗ bấu để phân biệt điều AI **thấy** với điều
///    AI **suy ra**.
/// 3. **Hành động là cam, và nó phải bấm được.** [TtAiStory.action] không nhận
///    chuỗi suông; nó nhận nhãn **và** callback. Không có callback thì không vẽ
///    nút — thà không có nút còn hơn một nút không đi đâu (WTM-360).
library;

import 'package:flutter/material.dart';

import 'tt_buttons.dart';
import 'tt_cards.dart';
import 'tt_tokens.dart';

/// Một việc AI đề nghị làm.
@immutable
class TtAiAction {
  const TtAiAction({required this.label, required this.onPressed});

  final String label;

  /// Bắt buộc, và cố ý **không** cho `null`: một hành động không biết mình chạy
  /// gì là CTA chết — lỗi dogfood WTM-360 đúng ở chỗ này.
  final VoidCallback onPressed;
}

/// Kết quả đã xảy ra, sau khi người bán bấm.
@immutable
class TtAiResult {
  const TtAiResult({required this.status, required this.label});

  final TtStatus status;
  final String label;
}

/// Câu chuyện AI, kể đúng một trật tự.
class TtAiStory extends StatelessWidget {
  const TtAiStory({
    super.key,
    required this.observation,
    this.reasoning,
    this.recommendation,
    this.action,
    this.result,
    this.leading,
  });

  /// **Bắt buộc.** Chuyện gì AI nhìn thấy — một câu, có số của chính doanh
  /// nghiệp này.
  final String observation;

  /// Vì sao nghĩ vậy. `null` khi luật không nói được lý do — và khi đó thà
  /// vắng mặt còn hơn một câu chung chung, vì câu chung chung làm người bán
  /// tưởng đã có bằng chứng.
  final String? reasoning;

  /// Nên làm gì, bằng lời.
  final String? recommendation;

  /// Nên làm gì, bằng nút.
  final TtAiAction? action;

  /// Đã xảy ra gì.
  final TtAiResult? result;

  /// Chỗ cho linh vật hoặc biểu tượng — dùng có chủ đích, không mặc định.
  final Widget? leading;

  @override
  Widget build(BuildContext context) => TtAiCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1 · QUAN SÁT (tím) ─────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading case final l?) ...[
              l,
              const SizedBox(width: TtSpace.x3),
            ] else ...[
              const Icon(Icons.auto_awesome, size: 20, color: TtColors.ai),
              const SizedBox(width: TtSpace.x2),
            ],
            Expanded(
              child: Text(
                observation,
                key: const Key('tt-ai-observation'),
                style: TtType.title.copyWith(color: TtColors.ai),
              ),
            ),
          ],
        ),

        // ── 2 · LÝ LẼ (neutral) ────────────────────────────────────────────
        if (reasoning case final r?) ...[
          const SizedBox(height: TtSpace.x2),
          Text(
            r,
            key: const Key('tt-ai-reasoning'),
            style: TtType.body.copyWith(color: TtColors.textSecondary),
          ),
        ],

        // ── 3 · ĐỀ XUẤT (tím) ──────────────────────────────────────────────
        if (recommendation case final rec?) ...[
          const SizedBox(height: TtSpace.x3),
          Text(
            rec,
            key: const Key('tt-ai-recommendation'),
            style: TtType.bodyMedium.copyWith(color: TtColors.ai),
          ),
        ],

        // ── 4 · HÀNH ĐỘNG (cam) ────────────────────────────────────────────
        if (action case final a?) ...[
          const SizedBox(height: TtSpace.x4),
          TtPrimaryButton(
            key: const Key('tt-ai-action'),
            label: a.label,
            onPressed: a.onPressed,
          ),
        ],

        // ── 5 · KẾT QUẢ (semantic) ─────────────────────────────────────────
        if (result case final res?) ...[
          const SizedBox(height: TtSpace.x3),
          TtStatusBadge(
            key: const Key('tt-ai-result'),
            status: res.status,
            label: res.label,
          ),
        ],
      ],
    ),
  );
}
