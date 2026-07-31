import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/ui/widgets/tongtai_fox_mascot.dart';

/// WTM-111 — the in-app Origami Business Fox mascot renders as runtime vector.
void main() {
  testWidgets('face variant renders the fox_face SVG at the given size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TongtaiFoxMascot.face(size: 80))),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    final box = tester.getSize(find.byType(SvgPicture));
    expect(box.width, 80);
    expect(box.height, 80);
  });

  testWidgets('avatar variant uses the avatar asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TongtaiFoxMascot.avatar(size: 40)),
      ),
    );
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    // The bytesLoader is an SvgAssetLoader pointing at the avatar asset.
    expect(svg.bytesLoader, isA<SvgAssetLoader>());
    expect(
      (svg.bytesLoader as SvgAssetLoader).assetName,
      TongtaiFoxMascot.avatarAsset,
    );
  });

  testWidgets('asset paths are the bundled mascot SVGs', (tester) async {
    expect(TongtaiFoxMascot.faceAsset, 'assets/mascot/fox_face.svg');
    expect(TongtaiFoxMascot.avatarAsset, 'assets/mascot/fox_avatar.svg');
  });
}
