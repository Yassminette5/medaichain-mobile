// Used on non-web platforms.
// ignore_for_file: avoid_print

Future<String?> requestBrowserNotificationPermission() async {
  return null;
}

String? getBrowserNotificationPermission() {
  return null;
}

bool browserNotificationsSupported() {
  return false;
}
