// Web-only notification permission helpers.
// ignore_for_file: avoid_print

import 'dart:html' as html;

Future<String?> requestBrowserNotificationPermission() async {
  if (!browserNotificationsSupported()) return null;
  try {
    // Triggers the browser permission prompt (requires secure context + user gesture).
    final permission = await html.Notification.requestPermission();
    return permission;
  } catch (_) {
    return null;
  }
}

String? getBrowserNotificationPermission() {
  if (!browserNotificationsSupported()) return null;
  try {
    return html.Notification.permission;
  } catch (_) {
    return null;
  }
}

bool browserNotificationsSupported() {
  try {
    return html.Notification.supported;
  } catch (_) {
    return false;
  }
}
