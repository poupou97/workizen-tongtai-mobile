import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../ai/tongtai_ai_errors.dart';
import '../../ai/tongtai_ai_key_validator.dart';
import '../../ai/tongtai_ai_provider_kind.dart';
import '../../ai/tongtai_ai_service.dart';
import '../../core/screen_data_controller.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../widgets/tongtai_screen_data.dart';
import '../../providers/tongtai_ai_provider.dart';
import 'tongtai_key_scan_screen.dart';

/// Kind of the inline status banner shown after a save / test / delete.
enum _AiStatusTone { success, error, info }

/// AI settings screen (WTM-61) — paste, validate, store, test and remove the
/// user's Grok (xAI) BYOK API key.
///
/// The key is stored via [flutter_secure_storage] and the field is masked by
/// default (privacy). "Test connection" makes a real, tiny call to the Grok
/// endpoint so the user gets immediate confirmation the key works, with friendly
/// error messages for invalid keys, network failures and rate limits.
class TongtaiAiKeyScreen extends ConsumerStatefulWidget {
  const TongtaiAiKeyScreen({super.key, this.scanLauncher});

  static const provider = TongtaiAiProviderKind.xai;

  /// Launches the QR scan and returns the scanned key text (WTM-83); null when
  /// dismissed. Injectable so tests never touch the camera. Defaults to pushing
  /// [TongtaiKeyScanScreen].
  final Future<String?> Function(BuildContext context)? scanLauncher;

  @override
  ConsumerState<TongtaiAiKeyScreen> createState() => _TongtaiAiKeyScreenState();
}

class _TongtaiAiKeyScreenState extends ConsumerState<TongtaiAiKeyScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool? _hasKey; // null = still loading the stored-key state
  String? _fieldError; // inline validation error under the field
  String? _statusMessage; // banner after save / test / delete
  _AiStatusTone _statusTone = _AiStatusTone.info;

  TongtaiAiService get _service => ref.read(tongtaiAiServiceProvider);
  TongtaiAiProviderKind get _providerKind => TongtaiAiKeyScreen.provider;

  @override
  void initState() {
    super.initState();
    _loadHasKey();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHasKey() async {
    final has = await _service.hasKey(provider: _providerKind);
    if (!mounted) return;
    setState(() => _hasKey = has);
  }

  void _setStatus(String message, _AiStatusTone tone) {
    setState(() {
      _statusMessage = message;
      _statusTone = tone;
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final validation = TongtaiAiKeyValidator.validate(
      _controller.text,
      provider: _providerKind,
    );
    if (!validation.ok) {
      // Reject up front so an invalid key is never stored (WTM-61 AC).
      setState(() {
        _fieldError = validation.issue.message(l10n.languageCode);
        _statusMessage = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
    });
    await _service.saveKey(_controller.text, provider: _providerKind);
    ref.invalidate(tongtaiHasAiKeyProvider);
    if (!mounted) return;
    _controller.clear();
    setState(() {
      _busy = false;
      _hasKey = true;
    });
    _setStatus(l10n.aiKeySavedSnack, _AiStatusTone.success);
  }

  /// Safe rotation (WTM-83): the new key from the field is validated, written
  /// and live-verified; on failure the previous working key is restored by the
  /// service — the seller can never brick a working setup.
  Future<void> _rotate() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _fieldError = null;
      _statusMessage = null;
    });
    final rotation = await _service.rotateKey(
      _controller.text,
      provider: _providerKind,
    );
    ref.invalidate(tongtaiHasAiKeyProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (rotation.ok) {
      _controller.clear();
      setState(() => _hasKey = true);
      _setStatus(
        l10n.aiKeyRotatedSnack(rotation.model!),
        _AiStatusTone.success,
      );
    } else if (rotation.validation != null) {
      setState(
        () =>
            _fieldError = rotation.validation!.issue.message(l10n.languageCode),
      );
    } else {
      _setStatus(
        l10n.aiKeyRotateFailedPrefix(
              rotation.error!.message(l10n.languageCode),
            ) +
            (rotation.rolledBack ? l10n.aiKeyRolledBack : l10n.aiKeyNoneStored),
        _AiStatusTone.error,
      );
    }
  }

  /// QR input (WTM-83): the scanned text only FILLS the field — it still goes
  /// through the exact same validate→save/rotate path as a typed key.
  Future<void> _scan() async {
    final l10n = context.l10n;
    final launcher =
        widget.scanLauncher ??
        (BuildContext context) => Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const TongtaiKeyScanScreen()),
        );
    final scanned = await launcher(context);
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;
    setState(() {
      _controller.text = scanned.trim();
      _fieldError = null;
    });
    _setStatus(l10n.aiKeyScannedSnack, _AiStatusTone.info);
  }

  Future<void> _test() async {
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    // Through the shared action guard (WTM-148) rather than a bespoke catch:
    // `TongtaiAiException` classifies itself, so this screen keeps its inline
    // status line while every other surface renders the same failure the same
    // way. The AI message is still what the user reads — the seam only decides
    // the category and what may be reported.
    final failure = await runTongtaiAction(
      () async {
        final res = await _service.testConnection(provider: _providerKind);
        if (!mounted) return;
        _setStatus(l10n.aiKeyTestOkSnack(res.model), _AiStatusTone.success);
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'ai-key',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      final cause = failure.cause;
      _setStatus(
        cause is TongtaiAiException
            ? cause.message(l10n.languageCode)
            : tongtaiFailureTitle(l10n, failure.kind),
        _AiStatusTone.error,
      );
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    await _service.deleteKey(provider: _providerKind);
    ref.invalidate(tongtaiHasAiKeyProvider);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hasKey = false;
    });
    _setStatus(l10n.aiKeyRemovedSnack, _AiStatusTone.info);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleAiAssistant),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TongtaiDesignTokens.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(providerName: _providerKind.displayName),
              const SizedBox(height: TongtaiDesignTokens.spacing4),
              if (_hasKey == true) const _KeySetBadge(),
              if (_hasKey == true)
                const SizedBox(height: TongtaiDesignTokens.spacing3),
              _KeyField(
                controller: _controller,
                obscure: _obscure,
                enabled: !_busy,
                errorText: _fieldError,
                hasKey: _hasKey == true,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('ai-key-action-scan'),
                  onPressed: _busy ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(l10n.aiKeyScanQr),
                ),
              ),
              Text(
                l10n.aiKeyConsoleHint(
                  _providerKind.keyConsoleUrl,
                  _providerKind.displayName,
                ),
                style: TongtaiDesignTokens.captionStyle.copyWith(
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing4),
              if (_statusMessage != null) ...[
                _StatusBanner(message: _statusMessage!, tone: _statusTone),
                const SizedBox(height: TongtaiDesignTokens.spacing4),
              ],
              SizedBox(
                width: double.infinity,
                height: TongtaiDesignTokens.buttonHeight,
                child: FilledButton(
                  key: const Key('ai-key-action-save'),
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: TongtaiDesignTokens.financeVioletText,
                  ),
                  child: Text(l10n.aiKeySave),
                ),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing3),
              SizedBox(
                width: double.infinity,
                height: TongtaiDesignTokens.buttonHeight,
                child: OutlinedButton(
                  key: const Key('ai-key-action-test'),
                  onPressed: (_busy || _hasKey != true) ? null : _test,
                  child: Text(l10n.aiKeyTest),
                ),
              ),
              if (_hasKey == true) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing3),
                SizedBox(
                  width: double.infinity,
                  height: TongtaiDesignTokens.buttonHeight,
                  child: OutlinedButton(
                    key: const Key('ai-key-action-rotate'),
                    onPressed: _busy ? null : _rotate,
                    child: Text(l10n.aiKeyRotate),
                  ),
                ),
              ],
              if (_hasKey == true) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing3),
                SizedBox(
                  width: double.infinity,
                  height: TongtaiDesignTokens.buttonHeight,
                  child: OutlinedButton(
                    key: const Key('ai-key-action-delete'),
                    onPressed: _busy ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TongtaiDesignTokens.error,
                      side: const BorderSide(color: TongtaiDesignTokens.error),
                    ),
                    child: Text(l10n.aiKeyRemove),
                  ),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing4),
                const Center(child: TongtaiInlineBusy()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.providerName});

  final String providerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: TongtaiDesignTokens.financeVioletText,
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing2),
            Expanded(
              child: Text(
                l10n.aiKeyCardTitle(providerName),
                style: TongtaiDesignTokens.heading3Style.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Text(
          l10n.aiKeyByokHint,
          style: TongtaiDesignTokens.smallStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _KeySetBadge extends StatelessWidget {
  const _KeySetBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: TongtaiDesignTokens.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        border: Border.all(
          color: TongtaiDesignTokens.success.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: TongtaiDesignTokens.success,
          ),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Expanded(
            child: Text(
              context.l10n.aiKeyStoredHint,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyField extends StatelessWidget {
  const _KeyField({
    required this.controller,
    required this.obscure,
    required this.enabled,
    required this.errorText,
    required this.hasKey,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
  final String? errorText;
  final bool hasKey;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = hasKey ? l10n.aiKeyPasteReplace : l10n.aiKeyPaste;
    return TextField(
      key: const Key('ai-key-field'),
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      maxLines: 1,
      style: TongtaiDesignTokens.bodyStyle.copyWith(
        color: TongtaiDesignTokens.lightTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: const Icon(Icons.key_outlined),
        suffixIcon: IconButton(
          key: const Key('ai-key-action-visibility'),
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          tooltip: obscure ? l10n.aiKeyShow : l10n.aiKeyHide,
          onPressed: onToggleObscure,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TongtaiDesignTokens.componentBorderRadius,
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.tone});

  final String message;
  final _AiStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _AiStatusTone.success => TongtaiDesignTokens.success,
      _AiStatusTone.error => TongtaiDesignTokens.error,
      _AiStatusTone.info => TongtaiDesignTokens.info,
    };
    final icon = switch (tone) {
      _AiStatusTone.success => Icons.check_circle_outline,
      _AiStatusTone.error => Icons.error_outline,
      _AiStatusTone.info => Icons.info_outline,
    };
    return Container(
      key: const Key('ai-key-status'),
      width: double.infinity,
      padding: const EdgeInsets.all(TongtaiDesignTokens.spacing3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(
          TongtaiDesignTokens.componentBorderRadius,
        ),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: TongtaiDesignTokens.spacing2),
          Expanded(
            child: Text(
              message,
              style: TongtaiDesignTokens.smallStyle.copyWith(
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
