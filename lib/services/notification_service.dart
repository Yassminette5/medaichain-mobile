import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import '../models/calendar_event_model.dart';

import 'notification_permission_stub.dart'
  if (dart.library.html) 'notification_permission_web.dart' as web_notif;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    // For web, notifications are handled differently (browser notifications)
    // For mobile, would use flutter_local_notifications
    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Request notification permission.
  ///
  /// - Web (Chrome): triggers browser prompt via Notification API.
  /// - Mobile: requests runtime notification permission (Android 13+/iOS).
  ///
  /// Note: On web this MUST be called from a user gesture (e.g. login button).
  Future<void> requestPermission() async {
    if (kIsWeb) {
      final supported = web_notif.browserNotificationsSupported();
      if (!supported) {
        debugPrint('🔔 Browser notifications not supported');
        return;
      }

      final current = web_notif.getBrowserNotificationPermission();
      debugPrint('🔔 Browser notification permission (before): $current');

      // Calling requestPermission triggers the prompt (if not already decided).
      final permission = await web_notif.requestBrowserNotificationPermission();
      debugPrint('🔔 Browser notification permission (after): $permission');
      return;
    }

    try {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        debugPrint('🔔 Notification permission already granted');
        return;
      }

      final result = await Permission.notification.request();
      debugPrint('🔔 Notification permission request result: $result');
    } catch (e) {
      debugPrint('❌ Notification permission request failed: $e');
    }
  }

  /// Schedule a notification for a calendar event
  Future<void> scheduleEventAlert(CalendarEvent event) async {
    if (event.alertBefore == AlertOption.none) return;
    if (kIsWeb) {
      // Web notifications would use browser notifications API
      debugPrint('📅 Alert scheduled (Web): ${event.title}');
      return;
    }
    // Mobile implementation would go here
    debugPrint('📅 Alert scheduled: ${event.title}');
  }

  /// Cancel a scheduled notification for an event
  Future<void> cancelEventAlert(String eventId) async {
    debugPrint('🔕 Alert cancelled for event: $eventId');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    debugPrint('🔕 All alerts cancelled');
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    debugPrint('📅 Test notification');
  }
}
