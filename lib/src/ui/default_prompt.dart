import 'package:flutter/material.dart';

enum PromptResult { positive, negative, dismissed }

abstract class ReviewPromptDelegate {
  Future<PromptResult> show(BuildContext context);
}

class DefaultReviewPrompt implements ReviewPromptDelegate {
  const DefaultReviewPrompt();

  @override
  Future<PromptResult> show(BuildContext context) async {
    final res = await showDialog<PromptResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('How is your experience?'),
        content: const Text('Your feedback helps us improve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, PromptResult.negative),
            child: const Text('👎 Needs work'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, PromptResult.positive),
            child: const Text('👍 Going well'),
          ),
        ],
      ),
    );
    return res ?? PromptResult.dismissed;
  }
}
