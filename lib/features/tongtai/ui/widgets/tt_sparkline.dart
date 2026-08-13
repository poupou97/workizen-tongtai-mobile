import 'package:flutter/material.dart';

import '../../../../core/design/tt.dart';

/// **Đường xu hướng nhỏ trong thẻ** — WTM-404 (concept-1 `cp_home.png`).
///
/// ## Vì sao nó tồn tại
///
/// Concept vẽ **mọi con số kèm một đường**. Đó không phải trang trí: một con số
/// trần nói *"hôm nay 24 triệu"*, còn con số kèm đường nói *"24 triệu, và đang
/// đi lên sau ba ngày chững"*. Người bán quyết định bằng cái thứ hai.
///
/// Đây là thứ tạo ra khác biệt lớn nhất giữa "trang quản trị" và "sản phẩm"
/// trong bản concept — nên nó là khối dựng đầu tiên, không phải khối cuối.
///
/// ## ⛔ KHÔNG bịa đường
///
/// Thiếu dữ liệu ⇒ **không vẽ gì**, và phía gọi phải nói *"chưa đủ dữ liệu"*.
/// Vẽ một đường phẳng, hay nội suy từ hai điểm, là bịa một xu hướng không ai đo
/// được — cùng lớp lỗi với `estimatedGain` đội lốt `observedRevenue` (WTM-384).
///
/// Ngưỡng tối thiểu là **[minPoints] điểm**: hai điểm chỉ vẽ được một đoạn
/// thẳng, và một đoạn thẳng trông y hệt một xu hướng trong khi nó không nói gì
/// về hình dạng.
class TtSparkline extends StatelessWidget {
  const TtSparkline({
    required this.values,
    required this.color,
    this.height = 36,
    super.key,
  });

  /// Chuỗi giá trị theo thời gian, cũ → mới.
  final List<double> values;

  /// Màu đường. ⚠️ Phía gọi chọn theo **ngữ nghĩa** (xanh = tích cực, xám =
  /// không biết), không theo màu định vị của module — Founder A2: màu thương
  /// hiệu/định vị **không** được dùng để biểu diễn trạng thái hay giá trị.
  final Color color;

  final double height;

  /// Dưới ngưỡng này thì không có hình dạng để nói.
  static const int minPoints = 3;

  /// Có đủ dữ liệu để vẽ không — phía gọi hỏi trước khi quyết bày gì.
  static bool hasShape(List<double> values) => values.length >= minPoints;

  @override
  Widget build(BuildContext context) {
    if (!hasShape(values)) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    // Dãy phẳng tuyệt đối: vẽ đường giữa, không chia cho 0.
    final span = (max - min).abs() < 1e-9 ? 1.0 : max - min;
    final dx = size.width / (values.length - 1);

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, size.height - ((values[i] - min) / span) * size.height),
    ];

    // Vùng tô nhạt dưới đường — thứ làm thẻ trông "có sức nặng" trong concept.
    final fill = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Chấm cuối: mắt bám vào "hiện tại đang ở đâu" trước khi đọc cả đường.
    canvas.drawCircle(points.last, 3, Paint()..color = color);
    canvas.drawCircle(
      points.last,
      3,
      Paint()
        ..color = TtColors.surface
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.color != color || !identical(old.values, values);
}
