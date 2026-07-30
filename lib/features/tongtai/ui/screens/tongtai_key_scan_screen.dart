import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../navigation/tongtai_design_tokens.dart';

/// QR scanner for BYOK API keys (WTM-83, Founder-approved dependency).
///
/// Thin by design: the camera feed runs here and the first decoded barcode
/// value is popped back to the caller — validation/storage stay on the key
/// screen (the scanned text goes through exactly the same save/rotate path as
/// a typed key). Local-first: frames are processed on-device by ML Kit; the
/// key is never sent anywhere by this screen.
class TongtaiKeyScanScreen extends StatefulWidget {
  const TongtaiKeyScanScreen({super.key});

  @override
  State<TongtaiKeyScanScreen> createState() => _TongtaiKeyScanScreenState();
}

class _TongtaiKeyScanScreenState extends State<TongtaiKeyScanScreen> {
  bool _popped = false;

  void _onDetect(BuildContext context, BarcodeCapture capture) {
    if (_popped) return;
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .firstOrNull;
    if (value == null) return;
    _popped = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.l10n.titleKeyScan),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            key: const Key('key-scan-camera'),
            onDetect: (capture) => _onDetect(context, capture),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(TongtaiDesignTokens.spacing6),
              child: Text(
                context.l10n.keyScanHint,
                key: const Key('key-scan-hint'),
                textAlign: TextAlign.center,
                style: TongtaiDesignTokens.smallStyle.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
