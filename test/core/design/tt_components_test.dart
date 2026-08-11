import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/core/design/tt.dart';

/// Component lõi — WTM-364 (Epic WTM-362).
///
/// Test ở đây kiểm **nghĩa**, không kiểm hình: một nút vẽ đẹp mà mang sai màu
/// vai trò sẽ dạy người dùng sai, và không ảnh chụp nào bắt được điều đó.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  group('⛔ nút — màu là vai trò, không phải trang trí', () {
    testWidgets('hành động kinh doanh là CAM', (tester) async {
      await tester.pumpWidget(
        host(TtPrimaryButton(label: 'Tạo đơn nhập', onPressed: () {})),
      );

      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(
        style.backgroundColor!.resolve({}),
        TtColors.brand,
        reason: 'nút hành động không mang màu thương hiệu',
      );
    });

    testWidgets('⭐ nút AI là tím NHẠT, không phải tím đặc', (tester) async {
      await tester.pumpWidget(
        host(TtAiActionButton(label: 'Hỏi Tổng Tài', onPressed: () {})),
      );

      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      // Nút tím đặc trông ngang hàng nút cam và sẽ dạy người bán rằng hai thứ
      // đó cùng loại. Nút AI phải MỜI, không GIỤC.
      expect(style.backgroundColor!.resolve({}), TtColors.aiSoft);
      expect(style.foregroundColor!.resolve({}), TtColors.ai);
      expect(style.backgroundColor!.resolve({}), isNot(TtColors.ai));
    });

    testWidgets('mọi nút cao 48 và vùng chạm ≥ 44', (tester) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              TtPrimaryButton(label: 'A', onPressed: () {}),
              TtSecondaryButton(label: 'B', onPressed: () {}),
              TtAiActionButton(label: 'C', onPressed: () {}),
              TtTextAction(label: 'D', onPressed: () {}),
            ],
          ),
        ),
      );

      for (final type in [FilledButton, OutlinedButton]) {
        for (final e in find.byType(type).evaluate()) {
          expect(
            tester.getSize(find.byWidget(e.widget)).height,
            greaterThanOrEqualTo(TtButtonMetrics.minTouch),
          );
        }
      }
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(TtButtonMetrics.minTouch),
      );
    });

    testWidgets('nút bị vô hiệu KHÔNG mang màu hành động', (tester) async {
      await tester.pumpWidget(
        host(const TtPrimaryButton(label: 'Tạo đơn nhập', onPressed: null)),
      );

      // Một nút xám mà vẫn cam thì người bán bấm mãi rồi mới hiểu là nó chết.
      // `ButtonStyle` không phơi `disabledBackgroundColor` riêng — nó nằm trong
      // `WidgetStateProperty`, nên phải hỏi đúng trạng thái.
      final style = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .style!;
      expect(
        style.backgroundColor!.resolve({WidgetState.disabled}),
        isNot(TtColors.brand),
      );
    });
  });

  group('⛔ thẻ — AI nói thì phải nhìn ra là AI nói', () {
    testWidgets('thẻ AI mang nền tím nhạt và viền tím', (tester) async {
      await tester.pumpWidget(host(const TtAiCard(child: Text('x'))));

      final d = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == TtColors.aiSoft);
      expect((d.border! as Border).top.color, TtColors.aiBorder);
    });

    testWidgets('thẻ tiêu chuẩn KHÔNG mang màu AI', (tester) async {
      await tester.pumpWidget(host(const TtCard(child: Text('x'))));

      final colors = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.color);
      // Tô tím một bản ghi người bán tự nhập là nhận công cho AI.
      expect(colors, isNot(contains(TtColors.aiSoft)));
    });

    testWidgets('mặc định KHÔNG đổ bóng', (tester) async {
      await tester.pumpWidget(
        host(const Column(children: [TtCard(child: Text('a'))])),
      );

      for (final c in tester.widgetList<Container>(find.byType(Container))) {
        final d = c.decoration;
        if (d is BoxDecoration) {
          expect(d.boxShadow ?? const [], isEmpty);
        }
      }
    });

    testWidgets('thẻ mức khẩn có vạch ĐẶC, không phải sắc độ viền', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const TtStatusCard(status: TtStatus.danger, child: Text('hết hàng')),
        ),
      );

      final stripe = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) => c.color == TtStatus.danger.color);
      expect(stripe.color, TtColors.danger);
    });
  });

  group(
    '⭐ CHƯA ĐỦ DỮ LIỆU là một widget riêng, không phải một biến thể màu',
    () {
      testWidgets('nó xám, và nó khác empty state', (tester) async {
        await tester.pumpWidget(
          host(
            const Column(
              children: [
                TtInsufficientData(
                  title: 'Chưa tính được lời',
                  reason: 'Thiếu giá vốn cho 12 mặt hàng',
                ),
              ],
            ),
          ),
        );

        final d = tester
            .widgetList<Container>(find.byType(Container))
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .first;
        expect(d.color, TtStatus.unknown.soft);
        expect(d.color, isNot(TtStatus.success.soft));
        // Nó phải nói THIẾU CÁI GÌ — biết là thiếu mà không biết thiếu gì thì
        // người bán không làm được gì tiếp.
        expect(find.textContaining('giá vốn'), findsOneWidget);
      });

      test('hai widget này là hai lớp khác nhau', () {
        // Rỗng = "đã xét và không có gì"; chưa đủ = "chưa xét được". Gộp chúng
        // là cách một màn im lặng biến thành lời trấn an sai.
        expect(TtEmptyState, isNot(TtInsufficientData));
      });
    },
  );

  group('KPI đứng chung một mặt', () {
    testWidgets('ba KPI ⇒ một thẻ, không phải ba', (tester) async {
      await tester.pumpWidget(
        host(
          const TtMetricRow(
            metrics: [
              TtMetric(label: 'Doanh thu', value: '128,4 trđ'),
              TtMetric(label: 'Lợi nhuận', value: '28,7 trđ'),
              TtMetric(label: 'Đơn hàng', value: '1.246'),
            ],
          ),
        ),
      );

      expect(find.byType(TtCard), findsOneWidget);
      expect(find.byType(TtMetric), findsNWidgets(3));
    });

    testWidgets('chênh lệch chưa biết chiều ⇒ XÁM, không xanh', (tester) async {
      await tester.pumpWidget(
        host(const TtMetric(label: 'Lợi nhuận', value: '—', delta: '?')),
      );

      final delta = tester.widget<Text>(find.text('?'));
      expect(delta.style!.color, TtStatus.unknown.color);
      expect(delta.style!.color, isNot(TtStatus.success.color));
    });
  });

  group(
    '⭐ ngôn ngữ thị giác AI — trật tự nằm trong KIỂU, không trong tài liệu',
    () {
      testWidgets('năm vai hiện đúng thứ tự và đúng màu', (tester) async {
        var pressed = 0;
        await tester.pumpWidget(
          host(
            TtAiStory(
              observation: 'Tổng Tài phát hiện 3 SKU có nguy cơ hết hàng.',
              reasoning: 'Bán trung bình 12/ngày. Tồn còn 31.',
              recommendation: 'Nên nhập thêm 120 sản phẩm.',
              action: TtAiAction(
                label: 'Tạo đơn nhập',
                onPressed: () => pressed++,
              ),
              result: const TtAiResult(
                status: TtStatus.success,
                label: 'Đã tạo đơn',
              ),
            ),
          ),
        );

        Text at(String key) => tester.widget<Text>(find.byKey(Key(key)).first);

        // Quan sát và đề xuất là TÍM — đó là chỗ Tổng Tài đang nói.
        expect(at('tt-ai-observation').style!.color, TtColors.ai);
        expect(at('tt-ai-recommendation').style!.color, TtColors.ai);
        // Lý lẽ là NEUTRAL: tô tím cả phần "vì sao" sẽ làm cả thẻ thành một khối
        // tím, và mất chỗ bấu để phân biệt điều AI THẤY với điều AI SUY RA.
        expect(at('tt-ai-reasoning').style!.color, TtColors.textSecondary);

        // Thứ tự dọc: quan sát → lý lẽ → đề xuất → hành động → kết quả.
        double y(String key) =>
            tester.getTopLeft(find.byKey(Key(key)).first).dy;
        expect(y('tt-ai-observation'), lessThan(y('tt-ai-reasoning')));
        expect(y('tt-ai-reasoning'), lessThan(y('tt-ai-recommendation')));
        expect(y('tt-ai-recommendation'), lessThan(y('tt-ai-action')));
        expect(y('tt-ai-action'), lessThan(y('tt-ai-result')));

        await tester.tap(find.byKey(const Key('tt-ai-action')));
        expect(pressed, 1);
      });

      testWidgets('chỉ có quan sát ⇒ không vẽ nút, không vẽ chỗ trống', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(const TtAiStory(observation: 'Doanh thu tháng này thấp hơn.')),
        );

        expect(find.byKey(const Key('tt-ai-observation')), findsOneWidget);
        // Thà không có nút còn hơn một nút không đi đâu (WTM-360).
        expect(find.byKey(const Key('tt-ai-action')), findsNothing);
        expect(find.byKey(const Key('tt-ai-reasoning')), findsNothing);
        expect(find.byKey(const Key('tt-ai-result')), findsNothing);
      });

      test('hành động KHÔNG nhận callback rỗng', () {
        // Kiểu ép: `TtAiAction.onPressed` không nullable, nên không ai dựng được
        // một hành động chưa nối vào đâu. Đó là lỗi dogfood WTM-360, nay là lỗi
        // biên dịch.
        const action = TtAiAction(label: 'x', onPressed: _noop);
        expect(action.onPressed, isNotNull);
      });
    },
  );
}

void _noop() {}
