import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../navigation/tongtai_design_tokens.dart';

/// The Origami Business Fox mascot rendered as runtime vector (WTM-111).
///
/// Mascot = Business Fox, visual language = Origami low-poly (Founder,
/// 2026-07-24). Two forms:
/// - [TongtaiFoxMascot.face] — the bare fox head, for empty states / decoration.
/// - [TongtaiFoxMascot.avatar] — the fox on a navy disc, for the AI Copilot
///   avatar in chat.
///
/// Assets are bundled SVGs (`assets/mascot/`), so they scale crisply at any
/// size without a raster set — the in-app counterpart to the native launcher
/// icon (WTM-110).
class TongtaiFoxMascot extends StatelessWidget {
  const TongtaiFoxMascot._(
    this._asset,
    this.size, {
    super.key,
    this.semanticsLabel,
  });

  /// Bare Origami fox head (transparent) — empty states, decoration.
  const TongtaiFoxMascot.face({
    Key? key,
    double size = 64,
    String? semanticsLabel,
  }) : this._(faceAsset, size, key: key, semanticsLabel: semanticsLabel);

  /// Fox on a navy disc — the Workizen AI avatar.
  const TongtaiFoxMascot.avatar({
    Key? key,
    double size = 32,
    String? semanticsLabel,
  }) : this._(avatarAsset, size, key: key, semanticsLabel: semanticsLabel);

  static const String faceAsset = 'assets/mascot/fox_face.svg';
  static const String avatarAsset = 'assets/mascot/fox_avatar.svg';

  final String _asset;
  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      semanticsLabel: semanticsLabel ?? 'Workizen AI Business Fox',
    );
  }
}

/// A branded loading indicator: the Origami fox above a slim progress bar
/// (WTM-111). Reusable wherever the app waits on local work.
class TongtaiFoxLoader extends StatelessWidget {
  const TongtaiFoxLoader({super.key, this.label, this.size = 72});

  /// Optional caption under the bar (e.g. "Đang tải…").
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TongtaiFoxMascot.face(size: size),
          const SizedBox(height: TongtaiDesignTokens.spacing4),
          SizedBox(
            width: size * 1.4,
            child: const LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: TongtaiDesignTokens.lightHover,
              valueColor: AlwaysStoppedAnimation<Color>(
                TongtaiDesignTokens.inventoryOrange,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: TongtaiDesignTokens.spacing3),
            Text(
              label!,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
