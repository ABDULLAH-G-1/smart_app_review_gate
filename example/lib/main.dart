import 'package:flutter/material.dart';
import 'package:smart_app_review_gate/smart_app_review_gate.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});
  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final ReviewGate gate;
  int orderSuccessCount = 0;
  bool? eligible;

  @override
  void initState() {
    super.initState();
    gate = ReviewGate(
      // nicer custom prompt (bottom sheet) instead of plain AlertDialog
      prompt: const FancyReviewPrompt(),
      config: const ReviewGateConfig(
        minSessions: 1,
        minDays: 0,
        cooldownDays: 0,              // testing ke liye 0
        askAtEvents: {'order_success': 2},
        debugShowMockPrompt: false,   // custom 2-button prompt dikhega
      ),
    );
    gate.trackAppOpen();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('smart_app_review_gate demo')),
        body: Builder(
          builder: (ctx) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 1,
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Demo controls', style: Theme.of(ctx).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'order_success',
                              value: '$orderSuccessCount',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              label: 'eligible',
                              value: eligible == null ? '—' : '$eligible',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.check_circle),
                        onPressed: () async {
                          await gate.trackEvent('order_success');
                          setState(() => orderSuccessCount++);
                          ScaffoldMessenger.of(ctx)
                            ..clearSnackBars()
                            ..showSnackBar(
                              const SnackBar(content: Text('Logged: order_success')),
                            );
                        },
                        label: const Text('Simulate success event'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.rule),
                        onPressed: () async {
                          final can = await gate.shouldAsk(ctx);
                          setState(() => eligible = can);
                          ScaffoldMessenger.of(ctx)
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(content: Text('shouldAsk: $can')));
                        },
                        label: const Text('Check eligibility'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.reviews),
                        onPressed: () => gate.ask(
                          ctx,
                          onNegativeFeedback: handleNegativeFeedback, // EMAIL callback
                        ),
                        label: const Text('Ask now'),
                      ),
                      const Divider(height: 24),
                      Text('Debug helpers', style: Theme.of(ctx).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset demo state'),
                            onPressed: () async {
                              final s = SharedPrefsReviewGateStore();
                              await s.setInstallAt(DateTime.now().subtract(const Duration(days: 10)));
                              await s.setSessionCount(5);
                              await s.setLastAskedAt(DateTime.now().subtract(const Duration(days: 9999)));
                              await s.setLastOutcome('none');
                              await s.setEventCounts({});
                              setState(() {
                                orderSuccessCount = 0;
                                eligible = null;
                              });
                              ScaffoldMessenger.of(ctx)
                                ..clearSnackBars()
                                ..showSnackBar(const SnackBar(content: Text('State reset')));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Negative feedback → email compose open
Future<void> handleNegativeFeedback(BuildContext ctx, ReviewContext rc) async {
  const supportEmail = 'support@yourapp.com'; // <-- apna email lagao
  final subject = Uri.encodeComponent('App feedback');
  final body = Uri.encodeComponent(
    'Please describe the issue:\n'
        '\n---\n'
        'Meta:\n'
        'Installed: ${rc.installAt}\n'
        'Sessions: ${rc.sessionCount}\n'
        'Last asked: ${rc.lastAskedAt}\n'
        'Last outcome: ${rc.lastOutcome}\n'
        'Events: ${rc.eventCounts}\n',
  );

  final uri = Uri.parse('mailto:$supportEmail?subject=$subject&body=$body');
  final ok = await launchUrl(uri);
  if (!ok) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text("Couldn't open email app.")),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        // surfaceContainerHighest ho sakta hai aapke Flutter me na ho;
        // isliye surfaceVariant use kar rahe hain (widely supported).
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

/// A prettier 2-button prompt that implements ReviewPromptDelegate.
class FancyReviewPrompt implements ReviewPromptDelegate {
  const FancyReviewPrompt();

  @override
  Future<PromptResult> show(BuildContext context) async {
    final res = await showModalBottomSheet<PromptResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(blurRadius: 24, color: Colors.black12)],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Enjoying the app?', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Your quick review helps others and supports development.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx, PromptResult.negative),
                        icon: const Icon(Icons.thumb_down_alt_outlined),
                        label: const Text('Not great'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, PromptResult.positive),
                        icon: const Icon(Icons.thumb_up_alt_outlined),
                        label: const Text('I love it'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return res ?? PromptResult.dismissed;
  }
}
