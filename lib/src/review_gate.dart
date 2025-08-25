import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'config.dart';
import 'state.dart';
import 'storage.dart';
import 'ui/default_prompt.dart';
import 'platform/review_bridge.dart';

class ReviewGate {
  final ReviewGateConfig config;
  final IReviewGateStore store;
  final ReviewPromptDelegate prompt;

  ReviewGate({
    ReviewGateConfig? config,
    IReviewGateStore? store,
    ReviewPromptDelegate? prompt,
  })  : config = config ?? const ReviewGateConfig(),
        store = store ?? SharedPrefsReviewGateStore(),
        prompt = prompt ?? const DefaultReviewPrompt();

  Future<void> trackAppOpen() async {
    final installAt = await store.getInstallAt();
    if (installAt == null) {
      await store.setInstallAt(DateTime.now());
    }
    final c = await store.getSessionCount();
    await store.setSessionCount(c + 1);
  }

  Future<void> trackEvent(String key) async {
    final counts = await store.getEventCounts();
    counts[key] = (counts[key] ?? 0) + 1;
    await store.setEventCounts(counts);
  }

  Future<bool> shouldAsk(BuildContext context) async {
    final ctx = await _loadContext();
    return _eligible(ctx, config);
  }

  Future<void> ask(
      BuildContext context, {
        Future<void> Function(BuildContext, ReviewContext)? onNegativeFeedback,
      }) async {
    if (config.debugShowMockPrompt) {
      await _showMockFlow(context);
      return;
    }

    final ctx = await _loadContext();
    if (!_eligible(ctx, config)) return;

    final result = await prompt.show(context);
    if (result == PromptResult.positive) {
      config.onPositiveBeforeStore?.call();
      await ReviewBridge.requestReviewOrStore();
      await _markAsked(LastOutcome.positive);
    } else if (result == PromptResult.negative) {
      if (onNegativeFeedback != null) {
        await onNegativeFeedback(context, ctx);
      } else {
        await _defaultFeedbackDialog(context);
      }
      await _markAsked(LastOutcome.negative);
    }
  }

  Future<ReviewContext> _loadContext() async {
    final installAt = await store.getInstallAt() ?? DateTime.now();
    final sessionCount = await store.getSessionCount();
    final lastAskedAt = await store.getLastAskedAt();
    final lastOutcomeStr = await store.getLastOutcome() ?? 'none';
    final counts = await store.getEventCounts();
    return ReviewContext(
      installAt: installAt,
      sessionCount: sessionCount,
      lastAskedAt: lastAskedAt,
      lastOutcome: _outcomeFrom(lastOutcomeStr),
      eventCounts: counts,
    );
  }

  bool _eligible(ReviewContext ctx, ReviewGateConfig cfg) {
    final now = DateTime.now();
    if (ctx.sessionCount < cfg.minSessions) return false;
    if (now.difference(ctx.installAt).inDays < cfg.minDays) return false;

    if (ctx.lastAskedAt != null) {
      final gap = now.difference(ctx.lastAskedAt!).inDays;
      final mult = (ctx.lastOutcome == LastOutcome.negative) ? 2 : 1;
      if (gap < cfg.cooldownDays * mult) return false;
    }

    for (final e in cfg.askAtEvents.entries) {
      if ((ctx.eventCounts[e.key] ?? 0) < e.value) return false;
    }
    return true;
  }

  Future<void> _markAsked(LastOutcome outcome) async {
    await store.setLastAskedAt(DateTime.now());
    await store.setLastOutcome(_outcomeToString(outcome));
  }

  String _outcomeToString(LastOutcome o) =>
      o == LastOutcome.positive ? 'positive' : o == LastOutcome.negative ? 'negative' : 'none';

  LastOutcome _outcomeFrom(String s) =>
      s == 'positive' ? LastOutcome.positive : s == 'negative' ? LastOutcome.negative : LastOutcome.none;

  Future<void> _defaultFeedbackDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text('Thanks for the feedback'),
        content: Text('Please share details via support so we can fix issues faster.'),
      ),
    );
  }

  Future<void> _showMockFlow(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text('Mock Review'),
        content: Text('Debug build: a native review prompt would appear in a store-delivered build.'),
      ),
    );
  }
}
