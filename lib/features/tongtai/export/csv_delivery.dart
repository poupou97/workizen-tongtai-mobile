import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_exporter.dart';

/// Hands a finished CSV to the user (WTM-99 AC4). The production
/// implementation writes a temp file and opens the OS **share sheet** — the
/// local-first "email delivery option": the seller picks Mail/Gmail (or Zalo,
/// Drive…) and the file leaves the device only through an app the seller
/// chose. No backend, nothing uploaded by Tổng Tài itself (D-5).
abstract interface class TongtaiCsvDelivery {
  /// Deliver [csv] under [fileName]; [subject] pre-fills the email subject
  /// when the seller picks a mail app.
  Future<void> deliver(TongtaiCsv csv, String fileName, String subject);
}

/// Share-sheet delivery over a temp file (production).
class ShareSheetCsvDelivery implements TongtaiCsvDelivery {
  const ShareSheetCsvDelivery();

  @override
  Future<void> deliver(TongtaiCsv csv, String fileName, String subject) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv.content);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: subject,
      ),
    );
  }
}

/// Test fake capturing what would have been shared.
class RecordingCsvDelivery implements TongtaiCsvDelivery {
  final List<(TongtaiCsv, String, String)> delivered = [];

  @override
  Future<void> deliver(TongtaiCsv csv, String fileName, String subject) async {
    delivered.add((csv, fileName, subject));
  }
}
