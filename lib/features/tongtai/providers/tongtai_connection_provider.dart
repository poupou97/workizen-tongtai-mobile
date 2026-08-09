import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../action/business_action.dart';
import '../action/business_action_executor.dart';
import '../action/demo_action_handlers.dart';
import '../connection/connection_credential_store.dart';
import '../connection/connection_repository.dart';
import '../connection/connection_service.dart';
import '../connection/google/drive_backup_coordinator.dart';
import '../connection/google/drive_backup_service.dart';
import '../connection/google/google_connection.dart';
import '../connection/google/google_oauth.dart';
import '../connection/telegram/owner_notifier.dart';
import '../connection/telegram/telegram_client.dart';
import '../connection/telegram/telegram_connection.dart';
import 'tongtai_agentic_provider.dart';
import 'tongtai_backup_provider.dart';
import 'tongtai_chat_provider.dart' show tongtaiDatabaseProvider;

/// **Kết nối nền tảng ngoài, nối vào app** — WTM-317 (C1 · Epic WTM-315).
///
/// Riverpod-only (ADR-TON-002). Test ghi đè [connectionCredentialStoreProvider]
/// và [googleAuthenticatorProvider] để chạy trọn luồng mà không cần Keystore
/// hay trình duyệt.

/// Metadata kết nối — **không** giữ bí mật nào.
final connectionRepositoryProvider = Provider<ConnectionRepository>(
  (ref) => DriftConnectionRepository(ref.watch(tongtaiDatabaseProvider)),
);

/// Bí mật — Keychain (iOS) / Keystore (Android).
final connectionCredentialStoreProvider = Provider<ConnectionCredentialStore>(
  (ref) => SecureConnectionCredentialStore(),
);

final connectionServiceProvider = Provider<ConnectionService>(
  (ref) => ConnectionService(
    repository: ref.watch(connectionRepositoryProvider),
    credentials: ref.watch(connectionCredentialStoreProvider),
  ),
);

/// ⭐ **Chưa có OAuth client ID nên đây là bản chưa cấu hình.**
///
/// Client ID do Founder tạo trên Google Cloud Console — §30, thứ tôi không tự
/// làm được. Bản này **ném** `notConfigured` thay vì im lặng trả rỗng, nên khi
/// nút "Kết nối Google" chưa chạy được thì lý do hiện ra ngay chỗ bấm.
///
/// Ngày có client ID: thay đúng provider này bằng authenticator thật (AppAuth,
/// PKCE — WTM-309). Không màn hình nào, không bảng nào, không luật nào đổi.
/// Các bước tạo: `docs/08-PLATFORM/22-GOOGLE-DRIVE-CONNECTOR.md`.
final googleAuthenticatorProvider = Provider<GoogleAuthenticator>(
  (ref) => const UnconfiguredGoogleAuthenticator(),
);

final googleConnectionProvider = Provider<GoogleConnection>(
  (ref) => GoogleConnection(
    connections: ref.watch(connectionServiceProvider),
    authenticator: ref.watch(googleAuthenticatorProvider),
  ),
);

final driveBackupServiceProvider = Provider<DriveBackupService>(
  (ref) => DriveBackupService(),
);

final telegramClientProvider = Provider<TelegramClient>(
  (ref) => TelegramClient(),
);

/// Telegram — **không** OAuth, không client ID, không xét duyệt: một bot token
/// dán vào là chạy. Đó là lý do nó là connector thật chạy được **sớm nhất**.
final telegramConnectionProvider = Provider<TelegramConnection>(
  (ref) => TelegramConnection(
    connections: ref.watch(connectionServiceProvider),
    client: ref.watch(telegramClientProvider),
  ),
);

final ownerNotifierProvider = Provider<OwnerNotifier>(
  (ref) => OwnerNotifier(
    executor: ref.watch(businessActionExecutorProvider),
    telegram: ref.watch(telegramConnectionProvider),
  ),
);

/// Bộ handler của **cửa ghi duy nhất**, đã có connector thật.
///
/// `demoActionHandlers` vẫn ở đây cho những loại chưa nối được nền tảng nào —
/// và chúng vẫn khai mình là diễn tập bằng `demo:`. Loại nào có connector thật
/// thì ghi đè lên, nên không có đường nào để một hành động **thật** lặng lẽ
/// chạy bằng handler diễn tập.
final tongtaiActionHandlersProvider =
    Provider<Map<BusinessActionType, ActionEffect>>(
      (ref) => {
        ...demoActionHandlers,
        BusinessActionType.storageBackupUpload: DriveBackupCoordinator.effect(
          connection: ref.watch(googleConnectionProvider),
          drive: ref.watch(driveBackupServiceProvider),
          backup: ref.watch(tongtaiBackupServiceProvider),
        ),
        BusinessActionType.ownerNotify: OwnerNotifier.effect(
          ref.watch(telegramConnectionProvider),
        ),
      },
    );

final driveBackupCoordinatorProvider = Provider<DriveBackupCoordinator>(
  (ref) => DriveBackupCoordinator(
    executor: ref.watch(businessActionExecutorProvider),
    connection: ref.watch(googleConnectionProvider),
    drive: ref.watch(driveBackupServiceProvider),
  ),
);

/// Trạng thái các nền tảng — nguồn của màn Kết nối.
final connectorCatalogProvider = FutureProvider<List<ConnectorState>>(
  (ref) => ref.watch(connectionServiceProvider).catalogState(),
);

/// Các bản sao lưu đang nằm trên Drive. Rỗng khi chưa kết nối — không phải lỗi.
final driveBackupListProvider = FutureProvider<List<DriveBackupFile>>(
  (ref) => ref.watch(driveBackupCoordinatorProvider).list(),
);

/// Telegram đã đủ để gửi chưa — token **và** nơi nhận.
///
/// Không nằm trong `kBusinessDataProviders`: nó hỏi Keystore, không hỏi cơ sở
/// dữ liệu nghiệp vụ, nên gieo hay xoá dữ liệu mẫu không đổi được câu trả lời.
final telegramReadyProvider = FutureProvider<bool>(
  (ref) => ref.watch(telegramConnectionProvider).isReady,
);
