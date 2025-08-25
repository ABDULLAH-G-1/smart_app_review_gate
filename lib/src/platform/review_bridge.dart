import 'package:in_app_review/in_app_review.dart';

class ReviewBridge {
  static final _review = InAppReview.instance;

  static Future<bool> requestReviewOrStore() async {
    try {
      final isAvailable = await _review.isAvailable();
      if (isAvailable) {
        await _review.requestReview();
        return true;
      }
      await _review.openStoreListing();
      return false;
    } catch (_) {
      try { await _review.openStoreListing(); } catch (_) {}
      return false;
    }
  }
}
