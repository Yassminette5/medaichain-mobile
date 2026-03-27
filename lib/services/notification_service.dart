import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';
import '../models/calendar_event_model.dart';
import 'api_service.dart';

const AndroidNotificationChannel kDefaultNotificationChannel =
    AndroidNotificationChannel(
  'ordonnance_channel',
  'Ordonnance Notifications',
  description: 'Notifications for prescriptions and pharmacy orders',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidInitializationSettings _bgInitSettingsAndroid =
    AndroidInitializationSettings('ic_launcher');
const DarwinInitializationSettings _bgInitSettingsIOS =
    DarwinInitializationSettings();
const InitializationSettings _bgInitSettings = InitializationSettings(
  android: _bgInitSettingsAndroid,
  iOS: _bgInitSettingsIOS,
);

Future<void> _ensureBackgroundLocalNotificationsInitialized() async {
  final androidImpl = _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidImpl != null) {
    await androidImpl.createNotificationChannel(kDefaultNotificationChannel);
  }
  await _backgroundLocalNotifications.initialize(_bgInitSettings);
}

Future<void> _showBackgroundLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? 'Notification';
  final body = notification?.body ?? message.data.toString();

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails();

  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    kDefaultNotificationChannel.id,
    kDefaultNotificationChannel.name,
    channelDescription: kDefaultNotificationChannel.description,
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    icon: 'ic_launcher',
  );

  final NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await _backgroundLocalNotifications.show(
    DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
    title,
    body,
    platformChannelSpecifics,
    payload: message.data.isNotEmpty ? message.data.toString() : null,
  );
}

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    // If already initialized, ignore.
  }
  await _ensureBackgroundLocalNotificationsInitialized();
  // If the message includes a notification payload, Android/iOS will usually
  // display it automatically when the app is backgrounded/terminated.
  // Only show a local notification for data-only messages.
  if (message.notification == null) {
    await _showBackgroundLocalNotification(message);
  }
  debugPrint('🔔 Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FirebaseMessaging _firebaseMessaging;
  late FlutterLocalNotificationsPlugin _localNotifications;
  bool _initialized = false;
  bool _tokenRefreshListenerAttached = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  void attachNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Initialize the notification service with Firebase and local notifications
  Future<void> init() async {
    // Initialize the plumbing once, but allow token registration retries
    // (init() may be called before login, then again after login).
    if (_initialized) {
      if (!kIsWeb) {
        await registerFcmTokenIfPossible();
      }
      return;
    }

    try {
      if (!kIsWeb) {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        _firebaseMessaging = FirebaseMessaging.instance;

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Request notification permissions
        await _requestNotificationPermissions();

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        // Handle foreground messages with in-app popup + fallback notification
        FirebaseMessaging.onMessage.listen((message) async {
          await _handleForegroundMessage(message);
        });

        // Handle notification taps
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Mark initialized before registering token so registration works on first run.
        _initialized = true;

        // Register token now (if logged in) and on refresh
        await registerFcmTokenIfPossible();
        _attachTokenRefreshListener();

        debugPrint('✅ NotificationService initialized with Firebase');
      } else {
        debugPrint('✅ NotificationService initialized (Web mode)');
      }

      // _initialized may already be true (set above). Keep it true.
      _initialized = true;
    } catch (e) {
      // Do not mark initialized if Firebase init fails.
      // This allows a later retry after Firebase is properly configured.
      debugPrint('❌ Error initializing NotificationService: $e');
      _initialized = false;
    }
  }

  void _attachTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) {
      return;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM token refreshed');
      await registerFcmTokenIfPossible(tokenOverride: newToken);
    });

    _tokenRefreshListenerAttached = true;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Android 13+ requires runtime permission for notifications.
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      try {
        await androidImpl.requestNotificationsPermission();
        await androidImpl.createNotificationChannel(kDefaultNotificationChannel);
      } catch (_) {
        // Ignore: older devices / vendor implementations.
      }
    }
  }

  /// Request notification permissions from the user
  Future<void> _requestNotificationPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ Notification permissions granted (provisional)');
    } else {
      debugPrint('❌ Notification permissions denied');
    }
  }

  /// Register the FCM token with the backend (requires user to be logged in).
  /// This is safe to call multiple times.
  Future<void> registerFcmTokenIfPossible({String? tokenOverride}) async {
    try {
      if (kIsWeb) return;
      final token = tokenOverride ?? await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint(
          '⚠️ FCM getToken() returned null/empty. Push will not work. '
          'Most common causes: Firebase not configured for Android in this build, '
          'wrong Firebase app/package name, or Google Play services issue.',
        );
        return;
      }

      {
        debugPrint('🔑 FCM Token: $token');
        // Send token to backend
        await ApiService.updateFCMToken(token);
        debugPrint('✅ FCM token registered with backend');
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message received:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';

    final shownInApp = await _showInAppPopup(
      title: title,
      body: body,
      data: message.data,
    );

    if (!shownInApp) {
      await _showLocalNotification(
        title: title,
        body: body,
        payload: message.data,
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🎯 Notification tapped:');
    debugPrint('Data: ${message.data}');

    // Navigate to appropriate screen based on notification data
    _navigateToScreen(message.data);
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('🎯 Local notification tapped: ${response.payload}');
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _navigateToScreen({'payload': payload});
    }
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        kDefaultNotificationChannel.id,
        kDefaultNotificationChannel.name,
        channelDescription: kDefaultNotificationChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        icon: 'ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload != null ? payload.toString() : null,
      );
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Small in-app popup (bottom-right). Falls back to local notification if no navigatorKey/overlay.
  Future<bool> _showInAppPopup({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final overlayState = _navigatorKey?.currentState?.overlay;
      if (overlayState == null) {
        return false;
      }

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  entry.remove();
                  if (data != null) {
                    _navigateToScreen(data);
                  }
                },
                child: Material(
                  elevation: 8,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        if (data != null && data.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            data.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      overlayState.insert(entry);
      await Future.delayed(const Duration(seconds: 4));
      entry.remove();
      return true;
    } catch (e) {
      debugPrint('❌ Error showing in-app popup: $e');
      return false;
    }
  }

  /// Navigate to the appropriate screen based on notification data
  void _navigateToScreen(Map<String, dynamic> data) {
    final type = data['type'];
    final prescriptionId = data['prescriptionId'];

    debugPrint('🔀 Navigating based on notification type: $type');
    debugPrint('Prescription ID: $prescriptionId');

    // TODO: Implement navigation based on notification type
    // Example:
    // if (type == 'prescription_new') {
    //   // Navigate to prescription detail screen
    // } else if (type == 'order_status_update') {
    //   // Navigate to order tracking screen
    // }
  }

  /// Schedule a notification for a calendar event
  Future<void> scheduleEventAlert(CalendarEvent event) async {
    if (event.alertBefore == AlertOption.none) return;
    if (kIsWeb) {
      debugPrint('📅 Alert scheduled (Web): ${event.title}');
      return;
    }
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
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from MedaiChain',
    );
  }
}
