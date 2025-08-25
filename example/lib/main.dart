import 'package:flutter/material.dart';
import 'package:smart_app_review_gate/smart_app_review_gate.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});
  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final ReviewGate gate;

  @override
  void initState() {
    super.initState();
    gate = ReviewGate(
      config: const ReviewGateConfig(
        minSessions: 1,
        minDays: 0,
        cooldownDays: 1,
        askAtEvents: {'order_success': 2},
        debugShowMockPrompt: true, // web/dev me mock dialog
      ),
    );
    gate.trackAppOpen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('smart_app_review_gate demo')),
        // IMPORTANT: use a Builder to get a context under Scaffold
        body: Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => gate.trackEvent('order_success'),
                  child: const Text('Simulate success event'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final can = await gate.shouldAsk(ctx); // use ctx
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('shouldAsk: $can')),
                    );
                  },
                  child: const Text('Check eligibility'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => gate.ask(ctx), // use ctx
                  child: const Text('Ask for review (mock)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
