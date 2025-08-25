
---

# smart\_app\_review\_gate

[![pub](https://img.shields.io/pub/v/smart_app_review_gate?logo=dart)](https://pub.dev/packages/smart_app_review_gate)
![likes](https://img.shields.io/pub/likes/smart_app_review_gate)
![points](https://img.shields.io/pub/points/smart_app_review_gate)
![popularity](https://img.shields.io/pub/popularity/smart_app_review_gate)

A tiny Flutter package that asks for **store reviews only when users are happy** — otherwise it routes them to a **private feedback** path.
Configurable thresholds, session/day gates, anti-nag cooldowns, and a simple, accessible prompt with plug-and-play hooks.

> Works on Android, iOS, Web (web uses a custom prompt; native in-app review is mobile only).

---

## ✨ Features

* Ask **only at good moments** (event thresholds, min sessions/days)
* **Cooldowns** so you don’t nag users
* **Customizable prompt** (plug your own UI)
* **Negative feedback callback** (email / form / support screen)
* **Storage** via SharedPreferences
* **Zero-config** default prompt for quick start

---

## 🛠️ Install

```bash
flutter pub add smart_app_review_gate
```

or add manually:

```yaml
dependencies:
  smart_app_review_gate: ^0.0.1
```

```bash
flutter pub get
```

---

## 🚀 Quick start

```dart
import 'package:flutter/material.dart';
import 'package:smart_app_review_gate/smart_app_review_gate.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ReviewGate gate;

  @override
  void initState() {
    super.initState();
    gate = ReviewGate(
      config: const ReviewGateConfig(
        minSessions: 3,                 // app opened at least 3 times
        minDays: 2,                     // at least 2 days since install
        cooldownDays: 7,                // don’t ask again within a week
        askAtEvents: {'order_success': 3}, // ask after 3 successes
      ),
    );
    gate.trackAppOpen(); // call at app start
  }

  Future<void> onOrderCompleted(BuildContext context) async {
    await gate.trackEvent('order_success');     // log the happy moment
    if (await gate.shouldAsk(context)) {
      await gate.ask(context);                  // show prompt
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(home: Container());
}
```

---

## 📨 Negative feedback → email (1-minute setup)

```yaml
# pubspec.yaml
dependencies:
  url_launcher: ^6.3.0
```

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> handleNegative(BuildContext ctx, ReviewContext rc) async {
  final uri = Uri.parse(
    'mailto:support@yourapp.com'
    '?subject=${Uri.encodeComponent('App feedback')}'
    '&body=${Uri.encodeComponent('Please describe the issue...')}',
  );
  await launchUrl(uri);
}

// use it somewhere inside a button handler or callback:
Future<void> askForReview(BuildContext context, ReviewGate gate) async {
  await gate.ask(context, onNegativeFeedback: handleNegative);
}
```

You can also open a Google Form / support page instead of email.

---

#// Example config with defaults (copyable)
const cfg = ReviewGateConfig(
minSessions: 1,                 // minimum app opens
minDays: 0,                     // minimum days since install
cooldownDays: 0,                // wait after last prompt
askAtEvents: {},                // {eventName: requiredCount}
debugShowMockPrompt: false,     // show mock note in debug
onPositiveBeforeStore: null,    // callback before store prompt
);

// Use it:
final gate = ReviewGate(config: cfg);

```

* `ReviewGate.trackAppOpen()` – call at app start
* `ReviewGate.trackEvent('eventName')` – increment counters
* `ReviewGate.shouldAsk(context)` – check gates
* `ReviewGate.ask(context, onNegativeFeedback: …)` – show prompt

### Custom prompt (optional)

Implement your own 2-button UI:

```dart
class MyPrompt implements ReviewPromptDelegate {
  const MyPrompt();

  @override
  Future<PromptResult> show(BuildContext context) async {
    return showDialog<PromptResult>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enjoying the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, PromptResult.negative),
            child: const Text('Not great'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, PromptResult.positive),
            child: const Text('I love it'),
          ),
        ],
      ),
    ).then((v) => v ?? PromptResult.dismissed);
  }
}

// usage
final gate = ReviewGate(
  prompt: const MyPrompt(),
  config: const ReviewGateConfig(
    minSessions: 1,
    minDays: 0,
    cooldownDays: 3,
    askAtEvents: {'order_success': 2},
  ),
);
```

---

## 📱 Platform notes

| Platform    | Behavior                                                                                                                                 |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Android** | Uses Play In-App Review. Quota & heuristics are controlled by Play services; best tested via **Play Console → Internal testing** builds. |
| **iOS**     | Uses `SKStoreReviewController`. Apple caps how often the native dialog appears (per user/year). Test on TestFlight/Release.              |
| **Web**     | No native store review; package shows your custom/simple prompt. Route negatives to a feedback form/email.                               |

> In debug/sideload builds, the native store prompt may be skipped by the OS. That’s expected.

---

## 🧪 Example app

See `/example` for a runnable demo with:

* counters for events
* check eligibility button
* a nice bottom-sheet prompt
* email feedback callback

Run:

```bash
cd example
flutter run
```

---

## ❓ FAQ

**Why doesn’t a native review dialog appear every time?**
Stores throttle review prompts (Play/Apple). The API is a *request*, not a guarantee.

**What should my production defaults be?**
Something like `minSessions: 3`, `minDays: 2`, `cooldownDays: 7`, and an event threshold of `3`.

**Is incentivizing reviews allowed?**
No. Don’t reward users for ratings/reviews (store policy).

---

## 🔧 Development

```bash
dart format .
dart analyze
```

---

## 📄 License

MIT © M.Abdullah

## Links

* [Repository (GitHub)](https://github.com/ABDULLAH-G-1/smart_app_review_gate)
* [Report issues](https://github.com/ABDULLAH-G-1/smart_app_review_gate/issues)

---
