import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/calendar_event_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request Android 13+ notification permissions
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Schedule a notification for a calendar event
  Future<void> scheduleEventAlert(CalendarEvent event) async {
    if (event.alertBefore == AlertOption.none) return;

    final alertTime = event.dateTime.subtract(event.alertBefore.duration);

    // Don't schedule if the alert time is in the past
    if (alertTime.isBefore(DateTime.now())) return;

    final tzAlertTime = tz.TZDateTime.from(alertTime, tz.local);

    // Build notification content based on event type
    final typeLabel = event.type.displayName;
    final title = '🔔 $typeLabel dans ${event.alertBefore.displayName.replaceAll(' avant', '')}';
    final body = event.patientName != null
        ? '${event.title} — Patient: ${event.patientName}'
        : event.title;

    // Color based on event type
    Color notifColor;
    switch (event.type) {
      case EventType.consultation:
        notifColor = const Color(0xFF7C3AED);
        break;
      case EventType.operation:
        notifColor = const Color(0xFFEF4444);
        break;
      case EventType.note:
        notifColor = const Color(0xFF0EA5E9);
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      'calendar_alerts',
      'Alertes Agenda',
      channelDescription: 'Rappels pour les événements du calendrier médecin',
      importance: Importance.high,
      priority: Priority.high,
      color: notifColor,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        event.id.hashCode,
        title,
        body,
        tzAlertTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: event.id,
      );
      debugPrint('✅ Alert scheduled: "$title" at $alertTime');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel a scheduled notification for an event
  Future<void> cancelEventAlert(String eventId) async {
    await _plugin.cancel(eventId.hashCode);
    debugPrint('🗑️ Alert cancelled for event: $eventId');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Show an immediate test notification
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'calendar_alerts',
      'Alertes Agenda',
      channelDescription: 'Rappels pour les événements du calendrier médecin',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      '🔔 Test de notification',
      'Les alertes de l\'agenda fonctionnent correctement !',
      details,
    );
  }
}
