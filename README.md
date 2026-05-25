# Atelerix Flutter SDK

The official Flutter SDK for [Atelerix](https://atelerix.dev) — a unified monitoring and engagement platform built for modern apps.

Integrate once and get everything your team needs: error tracking, crash reporting, analytics, push notifications, in-app messages, user feedback, and update management — all from a single SDK and dashboard.

---

## Features

- **Error & Crash Tracking** — Capture and report errors with full stack traces automatically
- **Analytics** — Track users, sessions, screen views, and geographic data
- **Push Notifications** — Send targeted notifications 
- **In-App Messages** — Display announcements and banners inside your app
- **User Feedback** — Collect feedback directly from your users
- **App Update Management** — Notify users of updates or enforce forced upgrades
- **Event Tracking** — Track live and one-time user interactions
- **Multi-Project Support** — Manage multiple apps under one organization


---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  atelerix: ^lastest_version
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

### 1. Initialize the SDK

Atelerix wraps your app startup via the `builder` callback:

```dart
import 'package:atelerix/atelerix.dart';
import 'package:flutter/material.dart';

void main() {
  Atelerix.init(
    url: "https://api.atelerix.com",
    apiKey: "YOUR_API_KEY",
    projectId: "YOUR_PROJECT_ID",
    builder: () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    },
  );
}
```

### 2. Initialize Push Notifications

Notifications are lazily initialized — call `init()` when ready:

```dart
await Atelerix.notifications.init();

// Request permissions
final granted = await Atelerix.notifications.requestPermissions();

// Get device token
final token = await Atelerix.notifications.deviceToken;
```

### 3. Handle Notification Events

```dart
Atelerix.notifications.setOnNotificationReceived((data) {
  // Handle foreground notification
});

Atelerix.notifications.setOnNotificationTapped((data) {
  // Handle notification tap
});
```

### 4. Track an Error

```dart
try {
  // your code
} catch (exception, stack) {
  Atelerix.throwError(
    exception,
    stack,
    bugSeverity: BugSeverity.high,
    bugType: BugType.crash,
  );
}
```

With extra metadata:

```dart
Atelerix.throwError(
  exception,
  stack,
  bugSeverity: BugSeverity.high,
  bugType: BugType.crash,
  metaData: {"userId": "123", "screen": "checkout"},
);
```

### 5. Get User ID

```dart
final userId = Atelerix.getUserId(); // returns String?
```

---

## API Reference

### `Atelerix.init()`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | `String` | ✅ | Your Atelerix API base URL |
| `apiKey` | `String` | ✅ | Your project API key |
| `projectId` | `String` | ✅ | Your project ID |
| `builder` | `Future<void> Function()` | ✅ | App startup callback |

### `Atelerix.throwError()`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `exception` | `dynamic` | ✅ | The caught exception |
| `stack` | `StackTrace` | ✅ | The stack trace |
| `bugSeverity` | `BugSeverity` | ❌ | `low`, `medium`, `high` |
| `bugType` | `BugType` | ❌ | `crash`, `bug`, etc. |
| `metaData` | `Map<String, dynamic>` | ❌ | Any extra context |

### `Atelerix.notifications`

| Method | Returns | Description |
|--------|---------|-------------|
| `init()` | `Future<void>` | Initialize the notifications module |
| `requestPermissions()` | `Future<bool>` | Request notification permissions |
| `deviceToken` | `Future<String?>` | Get the device push token |
| `setOnNotificationReceived(callback)` | `void` | Foreground notification handler |
| `setOnNotificationTapped(callback)` | `void` | Notification tap handler |

---

## Modules

| Module | Description | Status |
|--------|-------------|--------|
| Error Tracking | Automatic and manual error capture | ✅ Live |
| Push Notifications | Send Notifications via dashboard or api request | ✅ Live |
| Analytics | User and session analytics | 🔜 Soon |
| In-App Messages | Popup and banner messages | 🔜 Soon |
| Feedback | User feedback collection UI | 🔜 Soon |
| Updates | Soft and forced update prompts | 🔜 Soon |
| Events | Live and one-time event tracking | 🔜 Soon |

---

## Requirements

- Flutter `>=3.0.0`
- Dart `>=3.0.0`
- Android `minSdkVersion 21`
- iOS `>=12.0`

---

## Support

- 📧 [info@alqtech.com](mailto:info@alqtech.com)
- 🌐 [atelerix.dev](https://atelerix.dev)
- 📖 [Documentation](https://docs.atelerix.dev)

---

## License

This SDK is distributed under the Atelerix SDK License. See [LICENSE](LICENSE) for details.