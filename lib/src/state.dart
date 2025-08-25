enum LastOutcome { none, positive, negative }

class ReviewContext {
  final DateTime installAt;
  final int sessionCount;
  final DateTime? lastAskedAt;
  final LastOutcome lastOutcome;
  final Map<String, int> eventCounts;

  const ReviewContext({
    required this.installAt,
    required this.sessionCount,
    required this.lastAskedAt,
    required this.lastOutcome,
    required this.eventCounts,
  });
}
