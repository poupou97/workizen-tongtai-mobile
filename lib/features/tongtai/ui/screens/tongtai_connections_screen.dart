import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/telemetry/tongtai_telemetry.dart';
import '../../action/business_action_executor.dart';
import '../../connection/connection_capability.dart';
import '../../connection/connection_catalog.dart';
import '../../connection/connection_service.dart';
import '../../connection/google/drive_backup_service.dart';
import '../../core/connection.dart';
import '../../core/screen_data_controller.dart';
import '../../core/tongtai_formatters.dart';
import '../../navigation/tongtai_design_tokens.dart';
import '../../connection/atlassian/atlassian_client.dart';
import '../../connection/atlassian/atlassian_connection.dart';
import '../../connection/google/google_connection.dart';
import '../../connection/telegram/telegram_client.dart';
import '../../connection/telegram/telegram_connection.dart';
import '../../providers/tongtai_connection_provider.dart';
import '../../providers/tongtai_simulation_provider.dart';
import 'tongtai_business_life_screen.dart';
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

  /// Các cuộc trò chuyện tìm được ở lần bấm gần nhất. `null` = **chưa tìm**,
  /// khác hẳn danh sách rỗng = *đã tìm và chưa thấy ai* (kỷ luật `null` ≠ 0).
  List<TelegramChat>? _chats;

  /// `null` = chưa nhập khoá xong. Rỗng = đã hỏi, tài khoản không có dự án nào.
  List<AtlassianProject>? _projects;

  /// Space Confluence. Cùng kỷ luật `null` ≠ rỗng như [_projects].
  List<AtlassianSpace>? _spaces;

  Future<void> _saveAtlassian({
    required String instanceUrl,
    required String email,
    required String token,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    AtlassianSetup? setup;
    var projects = <AtlassianProject>[];
    var spaces = <AtlassianSpace>[];
    final failure = await runTongtaiAction(
      () async {
        final connection = ref.read(atlassianConnectionProvider);
        setup = await connection.attachCredentials(
          instanceUrl: instanceUrl,
          email: email,
          token: token,
        );
        // Chỉ hỏi dự án khi khoá đã được Atlassian xác nhận — hỏi trước là
        // chắc chắn nhận về 401 và một danh sách rỗng khó hiểu.
        if (setup!.succeeded) {
          projects = await connection.projects();
          spaces = await connection.spaces();
        }
      },
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      final ok = setup?.succeeded ?? false;
      _projects = ok ? projects : null;
      _spaces = ok ? spaces : null;
    });
    ref.invalidate(connectorCatalogProvider);
    ref.invalidate(atlassianReadyProvider);
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }
    if (!(setup?.succeeded ?? false)) _say(context.l10n.atlassianBad);
  }

  Future<void> _pickSpace(AtlassianSpace space) async {
    if (_busy) return;
    setState(() => _busy = true);
    final failure = await runTongtaiAction(
      () => ref.read(atlassianConnectionProvider).selectSpace(space),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(knowledgeReferencesProvider);
    if (failure != null) showTongtaiFailure(context, failure);
  }

  Future<void> _pickProject(AtlassianProject project) async {
    if (_busy) return;
    setState(() => _busy = true);
    final failure = await runTongtaiAction(
      () => ref.read(atlassianConnectionProvider).selectProject(project.key),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(connectorCatalogProvider);
    ref.invalidate(atlassianReadyProvider);
    ref.invalidate(workContextProvider);
    if (failure != null) showTongtaiFailure(context, failure);
  }

  Future<void> _saveTelegramToken(String token) async {
    if (_busy) return;
    setState(() => _busy = true);

    TelegramSetup? setup;
    final failure = await runTongtaiAction(
      () async =>
          setup = await ref.read(telegramConnectionProvider).attachToken(token),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(connectorCatalogProvider);
    ref.invalidate(telegramReadyProvider);
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }

    final l10n = context.l10n;
    final bot = setup?.bot;
    _say(
      bot == null
          ? l10n.telegramTokenBad
          : l10n.telegramBotFound('@${bot.username}'),
    );
  }

  Future<void> _findTelegramChats() async {
    if (_busy) return;
    setState(() => _busy = true);

    var found = <TelegramChat>[];
    final failure = await runTongtaiAction(
      () async =>
          found = await ref.read(telegramConnectionProvider).discoverChats(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _chats = found;
    });
    if (failure != null) showTongtaiFailure(context, failure);
  }

  Future<void> _pickTelegramChat(TelegramChat chat) async {
    if (_busy) return;
    setState(() => _busy = true);
    final failure = await runTongtaiAction(
      () => ref.read(telegramConnectionProvider).attachChat(chat.id),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(connectorCatalogProvider);
    ref.invalidate(telegramReadyProvider);
    if (failure != null) showTongtaiFailure(context, failure);
  }

  Future<void> _sendTelegramTest() async {
    if (_busy) return;
    setState(() => _busy = true);

    ActionRunResult? result;
    final failure = await runTongtaiAction(
      () async => result = await ref.read(ownerNotifierProvider).sendTest(),
      telemetry: () => ref.read(tongtaiTelemetryProvider),
      screen: 'connections',
    );

    if (!mounted) return;
    setState(() => _busy = false);
    // Tin thử là một `BusinessAction` — màn Hoạt động phải thấy nó.
    invalidateBusinessDataProviders(ref);
    if (failure != null) {
      showTongtaiFailure(context, failure);
      return;
    }

    final l10n = context.l10n;
    switch (result) {
      case ActionSucceeded():
        _say(l10n.telegramTestSent);
      case ActionFailed(:final errorMessage):
        _say(errorMessage);
      case _:
        _say(l10n.stateRetry);
    }
  }

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
              const SizedBox(height: 12),
              _TelegramCard(
                busy: _busy,
                chats: _chats,
                onSaveToken: _saveTelegramToken,
                onFindChats: _findTelegramChats,
                onPickChat: _pickTelegramChat,
                onSendTest: _sendTelegramTest,
              ),
              const SizedBox(height: 12),
              const _SourceCatalogCard(),
              const SizedBox(height: 12),
              _AtlassianCard(
                busy: _busy,
                projects: _projects,
                spaces: _spaces,
                onSave: _saveAtlassian,
                onPickProject: _pickProject,
                onPickSpace: _pickSpace,
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

/// Telegram: dán token → tìm cuộc trò chuyện → gửi thử.
///
/// Ba bước hiện **cùng lúc**, không phải wizard ba màn. Người bán thấy được
/// mình đang ở đâu trong chuỗi, và quay lại sửa bước trước không phải bấm
/// "Quay lại" ba lần.
class _TelegramCard extends ConsumerStatefulWidget {
  const _TelegramCard({
    required this.busy,
    required this.chats,
    required this.onSaveToken,
    required this.onFindChats,
    required this.onPickChat,
    required this.onSendTest,
  });

  final bool busy;

  /// `null` = chưa bấm tìm lần nào. Rỗng = đã tìm, chưa ai nhắn cho bot.
  final List<TelegramChat>? chats;

  final Future<void> Function(String token) onSaveToken;
  final Future<void> Function() onFindChats;
  final Future<void> Function(TelegramChat) onPickChat;
  final Future<void> Function() onSendTest;

  @override
  ConsumerState<_TelegramCard> createState() => _TelegramCardState();
}

class _TelegramCardState extends ConsumerState<_TelegramCard> {
  final TextEditingController _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // `valueOrNull ?? false`: đang tải thì coi như **chưa sẵn sàng**. Hiện nút
    // "Gửi tin thử" trong lúc còn chưa biết có token hay không sẽ mời người
    // bán bấm vào một thứ chắc chắn hỏng.
    final ready = ref.watch(telegramReadyProvider).asData?.value ?? false;
    final chats = widget.chats;

    return Container(
      key: const Key('connections-telegram'),
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
            l10n.telegramTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.telegramHint,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('connections-telegram-token'),
            controller: _token,
            enabled: !widget.busy,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.telegramTokenLabel,
              helperText: l10n.telegramTokenHint,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('connections-telegram-save'),
              onPressed: widget.busy
                  ? null
                  : () => widget.onSaveToken(_token.text),
              child: Text(l10n.telegramSaveToken),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.telegramStartHint,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              key: const Key('connections-telegram-find'),
              onPressed: widget.busy ? null : () => widget.onFindChats(),
              child: Text(l10n.telegramFindChats),
            ),
          ),
          if (chats != null) ...[
            const SizedBox(height: 8),
            if (chats.isEmpty)
              Text(
                l10n.telegramNoChats,
                key: const Key('connections-telegram-no-chats'),
                style: const TextStyle(
                  fontSize: 13,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              )
            else
              for (final chat in chats)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    key: Key('connections-telegram-chat-${chat.id}'),
                    onPressed: widget.busy
                        ? null
                        : () => widget.onPickChat(chat),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(chat.label),
                    ),
                  ),
                ),
          ],
          if (ready) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const Key('connections-telegram-test'),
                onPressed: widget.busy ? null : () => widget.onSendTest(),
                child: Text(l10n.telegramSendTest),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Jira + Confluence: nhập khoá → chọn dự án → thấy một câu tóm tắt.
///
/// ⛔ **Không** phải Jira mobile: không board, không sprint, không backlog.
/// Thứ hiện ra là **một dòng** trả lời "công việc đang thế nào".
class _AtlassianCard extends ConsumerStatefulWidget {
  const _AtlassianCard({
    required this.busy,
    required this.projects,
    required this.spaces,
    required this.onSave,
    required this.onPickProject,
    required this.onPickSpace,
  });

  final bool busy;
  final List<AtlassianProject>? projects;
  final List<AtlassianSpace>? spaces;
  final Future<void> Function(AtlassianSpace) onPickSpace;
  final Future<void> Function({
    required String instanceUrl,
    required String email,
    required String token,
  })
  onSave;
  final Future<void> Function(AtlassianProject) onPickProject;

  @override
  ConsumerState<_AtlassianCard> createState() => _AtlassianCardState();
}

class _AtlassianCardState extends ConsumerState<_AtlassianCard> {
  final TextEditingController _url = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _token = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _email.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final work = ref.watch(workContextProvider);
    final projects = widget.projects;

    return Container(
      key: const Key('connections-atlassian'),
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
            l10n.atlassianTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.atlassianHint,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('connections-atlassian-url'),
            controller: _url,
            enabled: !widget.busy,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.atlassianUrlLabel,
              hintText: l10n.atlassianUrlHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('connections-atlassian-email'),
            controller: _email,
            enabled: !widget.busy,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.atlassianEmailLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('connections-atlassian-token'),
            controller: _token,
            enabled: !widget.busy,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.atlassianTokenLabel,
              helperText: l10n.atlassianTokenHint,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('connections-atlassian-save'),
              onPressed: widget.busy
                  ? null
                  : () => widget.onSave(
                      instanceUrl: _url.text,
                      email: _email.text,
                      token: _token.text,
                    ),
              child: Text(l10n.atlassianSave),
            ),
          ),
          if (projects != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.atlassianPickProject,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            if (projects.isEmpty)
              Text(
                l10n.atlassianNoProjects,
                key: const Key('connections-atlassian-no-projects'),
                style: const TextStyle(
                  fontSize: 13,
                  color: TongtaiDesignTokens.lightTextSecondary,
                ),
              )
            else
              for (final project in projects)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    key: Key('connections-atlassian-project-${project.key}'),
                    onPressed: widget.busy
                        ? null
                        : () => widget.onPickProject(project),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${project.key} · ${project.name}'),
                    ),
                  ),
                ),
          ],
          if (widget.spaces != null && widget.spaces!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.atlassianPickSpace,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TongtaiDesignTokens.lightTextPrimary,
              ),
            ),
            for (final space in widget.spaces!)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  key: Key('connections-atlassian-space-${space.key}'),
                  onPressed: widget.busy
                      ? null
                      : () => widget.onPickSpace(space),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(space.name),
                  ),
                ),
              ),
          ],
          // Một dòng, không một cái board. `null` và "chưa đủ dữ liệu" nói
          // cùng một câu vì với người đọc chúng giống nhau: chưa trả lời được.
          const SizedBox(height: 12),
          Text(
            work.asData?.value?.headline ?? l10n.atlassianNoData,
            key: const Key('connections-atlassian-headline'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: TongtaiDesignTokens.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Danh sách nguồn dữ liệu — **đọc từ catalog**, không dựng bằng tay.
///
/// §24: trạng thái phải nói thật. Một danh sách mà mọi dòng trông như nhau sẽ
/// khiến người bán tin app đang đồng bộ với sàn, trong khi thứ họ có là một
/// file Excel họ tự tải về.
class _SourceCatalogCard extends ConsumerWidget {
  const _SourceCatalogCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Rỗng khi chưa bật mô phỏng — và rỗng là câu trả lời đúng, không phải
    // trạng thái chờ: chưa bật thì không nền tảng nào đang phát.
    final live = ref.watch(liveDemoVendorsProvider).asData?.value ?? const {};
    final demoCount = [
      for (final source in ConnectionCatalog.all)
        if (readinessWithDemo(source, live) ==
            ConnectionReadiness.demoConnected)
          source,
    ].length;

    return Container(
      key: const Key('connections-sources'),
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
            l10n.sourcesHonestNote,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: TongtaiDesignTokens.lightTextSecondary,
            ),
          ),
          if (demoCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('connections-demo-live'),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7A4FCF).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.sourcesDemoLive(demoCount),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B3AA6),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                key: const Key('connections-start-demo'),
                // Không tự khởi động ở đây: đồng hồ mô phỏng có **một** chủ,
                // là màn Doanh nghiệp của bạn. Hai nút cùng gọi `start()` là
                // hai đường ghi cho một khái niệm (P-27).
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const TongtaiBusinessLifeScreen(),
                  ),
                ),
                child: Text(l10n.sourcesStartDemo),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SourceGroup(
            title: l10n.sourcesCommerce,
            sources: ConnectionCatalog.commerce,
            live: live,
          ),
          const SizedBox(height: 12),
          _SourceGroup(
            title: l10n.sourcesMessaging,
            sources: ConnectionCatalog.messaging,
            live: live,
          ),
          const SizedBox(height: 12),
          _SourceGroup(
            title: l10n.sourcesLogistics,
            sources: ConnectionCatalog.logistics,
            live: live,
          ),
          const SizedBox(height: 12),
          _SourceGroup(
            title: l10n.sourcesSourcing,
            sources: ConnectionCatalog.sourcing,
            live: live,
          ),
          const SizedBox(height: 12),
          _SourceGroup(
            title: l10n.sourcesFinance,
            sources: ConnectionCatalog.finance,
            live: live,
          ),
        ],
      ),
    );
  }
}

class _SourceGroup extends StatelessWidget {
  const _SourceGroup({
    required this.title,
    required this.sources,
    required this.live,
  });

  final String title;
  final List<ConnectionSource> sources;

  /// Nền tảng đang phát trong bản mô phỏng.
  final Set<String> live;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TongtaiDesignTokens.lightTextPrimary,
        ),
      ),
      const SizedBox(height: 6),
      for (final source in sources)
        Padding(
          key: Key('connections-source-${source.id}'),
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  source.name,
                  style: const TextStyle(
                    fontSize: 13,
                    color: TongtaiDesignTokens.lightTextPrimary,
                  ),
                ),
              ),
              _ReadinessChip(readiness: readinessWithDemo(source, live)),
            ],
          ),
        ),
    ],
  );
}

class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({required this.readiness});

  final ConnectionReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Chỉ `connected` được màu xanh. `fileBridge` là màu trung tính chứ không
    // phải xanh nhạt: "nhập qua file" là một cách dùng thật, nhưng nó không
    // phải "đã nối", và màu không được nói khác chữ.
    final (label, color) = switch (readiness) {
      ConnectionReadiness.connected => (l10n.readinessConnected, Colors.green),
      ConnectionReadiness.fileBridge => (
        l10n.readinessFileBridge,
        TongtaiDesignTokens.lightTextPrimary,
      ),
      ConnectionReadiness.demo => (
        l10n.readinessDemo,
        TongtaiDesignTokens.lightTextSecondary,
      ),
      // Tím, KHÔNG xanh. Màu là thứ người ta đọc trước chữ, nên một nhãn demo
      // màu xanh lá đã nói dối xong trước khi ai kịp đọc nó.
      ConnectionReadiness.demoConnected => (
        l10n.readinessDemoConnected,
        const Color(0xFF7A4FCF),
      ),
      ConnectionReadiness.researched => (
        l10n.readinessResearched,
        TongtaiDesignTokens.lightTextSecondary,
      ),
      ConnectionReadiness.partnerRequired => (
        l10n.readinessPartnerRequired,
        Colors.orange,
      ),
      ConnectionReadiness.apiFuture => (
        l10n.readinessApiFuture,
        TongtaiDesignTokens.lightTextSecondary,
      ),
    };

    return Container(
      key: Key('connections-readiness-${readiness.code}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
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
