import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../action/business_action_executor.dart';
import '../../connection/connection_capability.dart';
import '../../connection/connection_service.dart';
import '../../connection/google/drive_backup_service.dart';
import '../../core/connection.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../connection/google/google_connection.dart';
import '../../providers/tongtai_connection_provider.dart';
import '../../providers/tongtai_data_invalidation.dart';
import '../widgets/tongtai_screen_data.dart';
import 'tongtai_backup_screen.dart';

/// **Kết nối** — WTM-317 (C1 · Epic WTM-315). `IMPLEMENTATION_LEVEL=L3`.
///
/// ## Màn này nói SỰ THẬT về trạng thái, kể cả khi sự thật là "chưa xong"
///
/// Founder §8: *chưa nhập khoá ⇒ `SETUP_REQUIRED`, **không fake connected***.
/// Nên "Chưa thiết lập" là một nhãn bình thường, không phải một lỗi màu đỏ, và
/// nút chưa bấm được thì **nói ngay tại chỗ** vì sao.
///
/// Cách khác — ẩn nút đi cho gọn — sẽ để người bán tưởng tính năng không tồn
/// tại, và để Founder đi tìm lỗi ở chỗ khác.
class TongtaiConnectionsScreen extends ConsumerStatefulWidget {
  const TongtaiConnectionsScreen({super.key});

  @override
  ConsumerState<TongtaiConnectionsScreen> createState() =>
      _TongtaiConnectionsScreenState();
}

class _TongtaiConnectionsScreenState
    extends ConsumerState<TongtaiConnectionsScreen> {
  bool _busy = false;
  DateTime? _lastBackupAt;

  Future<void> _connectGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);

    var outcome = GoogleConnectOutcome.rejected;
    final failure = await runTongtaiAction(
      () async => outcome = await ref
          .read(googleConnectionProvider)
          .connectQuietly({ConnectionCapability.driveBackup}),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(connectorCatalogProvider);
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }

    final l10n = context.l10n;
    switch (outcome) {
      case GoogleConnectOutcome.connected:
      case GoogleConnectOutcome.cancelled:
        break;
      case GoogleConnectOutcome.notConfigured:
        _say(l10n.connectionNotConfigured);
      case GoogleConnectOutcome.network:
      case GoogleConnectOutcome.rejected:
        _say(l10n.connectionError);
    }
  }

  Future<void> _disconnectGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    final failure = await runTongtaiAction(
      () => ref.read(googleConnectionProvider).disconnect(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(connectorCatalogProvider);
    ref.invalidate(driveBackupListProvider);
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    _say(context.l10n.connectionDisconnectConfirm);
  }

  Future<void> _backupNow() async {
    if (_busy) return;
    setState(() => _busy = true);

    ActionRunResult? result;
    final failure = await runTongtaiAction(
      () async =>
          result = await ref.read(driveBackupCoordinatorProvider).backupNow(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(driveBackupListProvider);
    // Một bản sao lưu là một `BusinessAction` — nó hiện ở màn Hoạt động. Chỉ
    // làm mới màn này sẽ để màn kia nói con số cũ (WTM-149 device defect 1).
    invalidateBusinessDataProviders(ref);

    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    final l10n = context.l10n;
    switch (result) {
      case ActionSucceeded():
        setState(() => _lastBackupAt = DateTime.now());
        _say(l10n.driveBackupDone(_hhmm(_lastBackupAt!)));
      case ActionFailed(:final errorMessage):
        _say(errorMessage);
      case _:
        _say(l10n.stateRetry);
    }
  }

  /// Tải một bản từ Drive rồi **giao cho đúng màn khôi phục đã có**.
  ///
  /// Drive chỉ thay chỗ *lấy* file. Luật khôi phục — validate → xem trước →
  /// xác nhận phá huỷ → bản an toàn verify được → một transaction — không đổi
  /// một dòng nào (ADR-TON-018).
  Future<void> _restoreFrom(DriveBackupFile file) async {
    final coordinator = ref.read(driveBackupCoordinatorProvider);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TongtaiBackupScreen(
          pickFile: () async => TongtaiPickedBackup(
            path: 'drive:${file.id}',
            content: await coordinator.download(file.id),
          ),
        ),
      ),
    );
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(connectorCatalogProvider);

    return Scaffold(
      backgroundColor: TongtaiDesignTokens.lightBackground,
      appBar: AppBar(
        title: Text(l10n.titleConnections),
        elevation: 0,
        backgroundColor: TongtaiDesignTokens.lightBackground,
        foregroundColor: TongtaiDesignTokens.lightTextPrimary,
      ),
      body: SafeArea(
        child: TongtaiAsyncScreenData<List<ConnectorState>>(
          prefix: 'connections',
          async: catalog,
          onRetry: () async => ref.invalidate(connectorCatalogProvider),
          isEmpty: (states) => states.isEmpty,
          builder: (context, states) => ListView(
            key: const Key('connections-list'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.connectionsIntro,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              for (final state in states) ...[
                _ConnectorCard(
                  state: state,
                  busy: _busy,
                  onConnect: state.descriptor.id == kGoogleConnectorId
                      ? _connectGoogle
                      : null,
                  onDisconnect: state.descriptor.id == kGoogleConnectorId
                      ? _disconnectGoogle
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              _DriveBackupCard(
                busy: _busy,
                lastBackupAt: _lastBackupAt,
                onBackup: _backupNow,
                onRestore: _restoreFrom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một nền tảng: tên, trạng thái, những khả năng nó mở ra.
class _ConnectorCard extends StatelessWidget {
  const _ConnectorCard({
    required this.state,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
  });

  final ConnectorState state;
  final bool busy;
  final Future<void> Function()? onConnect;
  final Future<void> Function()? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = state.descriptor.id;

    return Container(
      key: Key('connections-connector-$id'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _connectorName(l10n, id),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
              ),
              _StatusChip(status: state.status),
            ],
          ),
          const SizedBox(height: 10),
          for (final capability in state.descriptor.capabilities)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '· ${_capabilityName(l10n, capability)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              ),
            ),
          if (onConnect != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: Key('connections-connect-$id'),
                onPressed: busy ? null : () => onConnect!(),
                child: Text(l10n.connectionConnect),
              ),
            ),
          ],
          // Ngắt kết nối chỉ hiện khi **thật sự** có khoá để xoá. Một nút
          // "Ngắt" trên một kết nối chưa thiết lập không làm gì và dạy người
          // bán rằng nút của app không đáng tin.
          if (onDisconnect != null && state.hasCredentials) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                key: Key('connections-disconnect-$id'),
                onPressed: busy ? null : () => onDisconnect!(),
                child: Text(l10n.connectionDisconnect),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sao lưu Drive: nút chạy, và danh sách những bản đã có.
class _DriveBackupCard extends ConsumerWidget {
  const _DriveBackupCard({
    required this.busy,
    required this.lastBackupAt,
    required this.onBackup,
    required this.onRestore,
  });

  final bool busy;
  final DateTime? lastBackupAt;
  final Future<void> Function() onBackup;
  final Future<void> Function(DriveBackupFile) onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final files = ref.watch(driveBackupListProvider);

    return Container(
      key: const Key('connections-drive-backup'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TongtaiDesignTokens.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.driveBackupTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.driveBackupHint,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          if (lastBackupAt != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.driveBackupDone(_hhmm(lastBackupAt!)),
              key: const Key('connections-drive-last'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('connections-drive-backup-now'),
              onPressed: busy ? null : () => onBackup(),
              child: Text(busy ? l10n.driveBackupRunning : l10n.driveBackupNow),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.driveBackupList,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          switch (files) {
            AsyncData(value: final list) when list.isEmpty => Text(
              l10n.driveBackupEmpty,
              key: const Key('connections-drive-empty'),
              style: const TextStyle(
                fontSize: 13,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
            AsyncData(value: final list) => Column(
              children: [
                for (final file in list)
                  _DriveFileRow(file: file, onRestore: onRestore),
              ],
            ),
            // Danh sách hỏng **không** che mất nút sao lưu: không đọc được
            // những bản cũ không có nghĩa là không tạo được bản mới.
            _ => Text(
              l10n.driveBackupEmpty,
              key: const Key('connections-drive-empty'),
              style: const TextStyle(
                fontSize: 13,
                color: TongtaiDesignTokens.lightTextSecondary,
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _DriveFileRow extends StatelessWidget {
  const _DriveFileRow({required this.file, required this.onRestore});

  final DriveBackupFile file;
  final Future<void> Function(DriveBackupFile) onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final created = file.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
                if (created != null)
                  Text(
                    TongtaiFormatters.isoDate(created.toLocal()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: TongtaiDesignTokens.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: TextButton(
              key: Key('connections-drive-restore-${file.id}'),
              onPressed: () => onRestore(file),
              child: Text(l10n.driveBackupRestore),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // `setupRequired` cố ý mang màu trung tính: chưa xong không phải là hỏng.
    final (label, color) = switch (status) {
      ConnectionStatus.setupRequired => (
        l10n.connectionSetupRequired,
        TongtaiDesignTokens.lightTextSecondary,
      ),
      ConnectionStatus.active => (l10n.connectionActive, Colors.green),
      ConnectionStatus.paused => (
        l10n.connectionPaused,
        TongtaiDesignTokens.lightTextSecondary,
      ),
      ConnectionStatus.error => (l10n.connectionError, Colors.orange),
    };

    return Container(
      key: Key('connections-status-${status.code}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Giờ:phút trên máy người bán — mốc "vừa xong" chỉ cần tới phút.
String _hhmm(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';

String _connectorName(AppStrings l10n, String id) => switch (id) {
  kGoogleConnectorId => l10n.connectorGoogle,
  kTelegramConnectorId => l10n.connectorTelegram,
  kAtlassianConnectorId => l10n.connectorAtlassian,
  // Catalog là dữ liệu (WTM-287), nên một nền tảng mới không được rơi vào một
  // ô trống — nó hiện mã canonical cho tới khi ai đó đặt tên.
  _ => id,
};

String _capabilityName(AppStrings l10n, ConnectionCapability capability) =>
    switch (capability) {
      ConnectionCapability.driveBackup => l10n.capabilityDriveBackup,
      ConnectionCapability.telegramMessaging =>
        l10n.capabilityTelegramMessaging,
      ConnectionCapability.jiraWork => l10n.capabilityJiraWork,
      ConnectionCapability.confluenceKnowledge =>
        l10n.capabilityConfluenceKnowledge,
    };
