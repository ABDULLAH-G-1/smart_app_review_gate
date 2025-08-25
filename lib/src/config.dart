import 'package:flutter/widgets.dart';

class ReviewGateConfig {
  final int minSessions;
  final int minDays;
  final int cooldownDays;
  final int positiveThreshold;
  final Map<String, int> askAtEvents;
  final bool debugShowMockPrompt;
  final VoidCallback? onPositiveBeforeStore;

  const ReviewGateConfig({
    this.minSessions = 3,
    this.minDays = 5,
    this.cooldownDays = 30,
    this.positiveThreshold = 4,
    this.askAtEvents = const {},
    this.debugShowMockPrompt = false,
    this.onPositiveBeforeStore,
  }) : assert(positiveThreshold >= 1 && positiveThreshold <= 5);
}
