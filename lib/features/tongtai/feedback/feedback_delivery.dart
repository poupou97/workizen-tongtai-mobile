import 'package:share_plus/share_plus.dart';

/// Hands a finished feedback report to the seller's own apps (WTM-175).
///
/// There is **no backend and no account** (D-4, D-5), so there is nowhere to
/// POST feedback to. The OS share sheet is the local-first delivery: the seller
/// picks Zalo, Gmail, Messenger — whatever they already use — and **they** press
/// send. Nothing leaves the device unless they choose an app and confirm.
///
/// Same shape as `export/csv_delivery.dart`, for the same reason: the seam is
/// injectable so widget tests never open a real share sheet.
abstract class FeedbackDelivery {
  Future<void> send({required String report, required String subject});
}

class ShareSheetFeedbackDelivery implements FeedbackDelivery {
  const ShareSheetFeedbackDelivery();

  @override
  Future<void> send({required String report, required String subject}) async {
    await SharePlus.instance.share(ShareParams(text: report, subject: subject));
  }
}
