import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/tongtai_ai_errors.dart';
import '../../ai/tongtai_ai_key_validator.dart';
import '../../ai/tongtai_ai_provider_kind.dart';
import '../../ai/tongtai_ai_service.dart';
import '../../navigation/tongtai_design_tokens.dart';
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

  String get _lang =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;

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
    final validation = TongtaiAiKeyValidator.validate(
      _controller.text,
      provider: _providerKind,
    );
    if (!validation.ok) {
      // Reject up front so an invalid key is never stored (WTM-61 AC).
      setState(() {
        _fieldError = validation.issue.message(_lang);
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
    _setStatus(
      _lang == 'vi' ? 'Đã lưu khóa API an toàn.' : 'API key saved securely.',
      _AiStatusTone.success,
    );
  }

  /// Safe rotation (WTM-83): the new key from the field is validated, written
  /// and live-verified; on failure the previous working key is restored by the
  /// service — the seller can never brick a working setup.
  Future<void> _rotate() async {
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
        _lang == 'vi'
            ? 'Đã đổi khóa — ${rotation.model} phản hồi với khóa mới.'
            : 'Key rotated — ${rotation.model} responded with the new key.',
        _AiStatusTone.success,
      );
    } else if (rotation.validation != null) {
      setState(() => _fieldError = rotation.validation!.issue.message(_lang));
    } else {
      _setStatus(
        _lang == 'vi'
            ? 'Khóa mới không hoạt động (${rotation.error!.message(_lang)}). '
                  '${rotation.rolledBack ? 'Đã khôi phục khóa cũ.' : 'Chưa có khóa nào được lưu.'}'
            : 'The new key failed (${rotation.error!.message(_lang)}). '
                  '${rotation.rolledBack ? 'Previous key restored.' : 'No key stored.'}',
        _AiStatusTone.error,
      );
    }
  }

  /// QR input (WTM-83): the scanned text only FILLS the field — it still goes
  /// through the exact same validate→save/rotate path as a typed key.
  Future<void> _scan() async {
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
    _setStatus(
      _lang == 'vi'
          ? 'Đã quét khóa từ QR — bấm Lưu (hoặc Đổi khóa) để xác nhận.'
          : 'Key scanned — press Save (or Rotate) to confirm.',
      _AiStatusTone.info,
    );
  }

  Future<void> _test() async {
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final res = await _service.testConnection(provider: _providerKind);
      if (!mounted) return;
      _setStatus(
        _lang == 'vi'
            ? 'Kết nối thành công — ${res.model} đã phản hồi.'
            : 'Connected — ${res.model} responded.',
        _AiStatusTone.success,
      );
    } on TongtaiAiException catch (e) {
      if (!mounted) return;
      _setStatus(e.message(_lang), _AiStatusTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    await _service.deleteKey(provider: _providerKind);
    ref.invalidate(tongtaiHasAiKeyProvider);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hasKey = false;
    });
    _setStatus(
      _lang == 'vi' ? 'Đã xóa khóa API.' : 'API key removed.',
      _AiStatusTone.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vi = _lang == 'vi';
    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(vi ? 'Trợ lý AI' : 'AI Assistant'),
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
              _Header(providerName: _providerKind.displayName, vi: vi),
              const SizedBox(height: TongtaiDesignTokens.spacing4),
              if (_hasKey == true) _KeySetBadge(vi: vi),
              if (_hasKey == true)
                const SizedBox(height: TongtaiDesignTokens.spacing3),
              _KeyField(
                controller: _controller,
                obscure: _obscure,
                enabled: !_busy,
                errorText: _fieldError,
                hasKey: _hasKey == true,
                vi: vi,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('tongtai-ai-scan'),
                  onPressed: _busy ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(vi ? 'Quét QR' : 'Scan QR'),
                ),
              ),
              Text(
                vi
                    ? 'Lấy khóa tại ${_providerKind.keyConsoleUrl}. Khóa chỉ lưu trên máy bạn và chỉ gửi trực tiếp tới ${_providerKind.displayName}.'
                    : 'Get a key at ${_providerKind.keyConsoleUrl}. Your key stays on this device and is sent only to ${_providerKind.displayName}.',
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
                  key: const Key('tongtai-ai-save'),
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: TongtaiDesignTokens.copilotViolet,
                  ),
                  child: Text(vi ? 'Lưu khóa' : 'Save key'),
                ),
              ),
              const SizedBox(height: TongtaiDesignTokens.spacing3),
              SizedBox(
                width: double.infinity,
                height: TongtaiDesignTokens.buttonHeight,
                child: OutlinedButton(
                  key: const Key('tongtai-ai-test'),
                  onPressed: (_busy || _hasKey != true) ? null : _test,
                  child: Text(vi ? 'Kiểm tra kết nối' : 'Test connection'),
                ),
              ),
              if (_hasKey == true) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing3),
                SizedBox(
                  width: double.infinity,
                  height: TongtaiDesignTokens.buttonHeight,
                  child: OutlinedButton(
                    key: const Key('tongtai-ai-rotate'),
                    onPressed: _busy ? null : _rotate,
                    child: Text(
                      vi
                          ? 'Đổi khóa (kiểm tra rồi mới thay)'
                          : 'Rotate key (verified swap)',
                    ),
                  ),
                ),
              ],
              if (_hasKey == true) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing3),
                SizedBox(
                  width: double.infinity,
                  height: TongtaiDesignTokens.buttonHeight,
                  child: OutlinedButton(
                    key: const Key('tongtai-ai-delete'),
                    onPressed: _busy ? null : _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TongtaiDesignTokens.error,
                      side: const BorderSide(color: TongtaiDesignTokens.error),
                    ),
                    child: Text(vi ? 'Xóa khóa' : 'Remove key'),
                  ),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: TongtaiDesignTokens.spacing4),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.providerName, required this.vi});

  final String providerName;
  final bool vi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: TongtaiDesignTokens.copilotViolet,
            ),
            const SizedBox(width: TongtaiDesignTokens.spacing2),
            Expanded(
              child: Text(
                vi ? 'Khóa API $providerName' : '$providerName API key',
                style: TongtaiDesignTokens.heading3Style.copyWith(
                  color: TongtaiDesignTokens.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TongtaiDesignTokens.spacing2),
        Text(
          vi
              ? 'Dùng khóa của riêng bạn (BYOK) để bật trợ lý AI. Khóa được lưu an toàn trên thiết bị.'
              : 'Bring your own key (BYOK) to enable the AI assistant. The key is stored securely on your device.',
          style: TongtaiDesignTokens.smallStyle.copyWith(
            color: TongtaiDesignTokens.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _KeySetBadge extends StatelessWidget {
  const _KeySetBadge({required this.vi});

  final bool vi;

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
              vi
                  ? 'Đã lưu khóa API. Bạn có thể kiểm tra, thay thế hoặc xóa khóa.'
                  : 'An API key is saved. You can test, replace or remove it.',
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
    required this.vi,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
  final String? errorText;
  final bool hasKey;
  final bool vi;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final hint = hasKey
        ? (vi ? 'Dán khóa mới để thay thế' : 'Paste a new key to replace')
        : (vi ? 'Dán khóa API của bạn' : 'Paste your API key');
    return TextField(
      key: const Key('tongtai-ai-key-field'),
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
          key: const Key('tongtai-ai-key-visibility'),
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          tooltip: obscure
              ? (vi ? 'Hiện khóa' : 'Show key')
              : (vi ? 'Ẩn khóa' : 'Hide key'),
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
      key: const Key('tongtai-ai-status'),
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
