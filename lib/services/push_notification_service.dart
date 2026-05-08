import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';

import '../models/pharmacy_dashboard.dart';
import '../screens/patientnesrine/document_list_screen.dart';
import '../screens/patientnesrine/prescription_detail_screen.dart';
import '../screens/pharmacie/prescription_details_screen.dart';
import '../services/api_service.dart';
import '../services/pharmacy_prescriptions_service.dart';
import '../services/pharmacy_service.dart';
import 'push_click_stub.dart' if (dart.library.html) 'push_click_web.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<Map<String, dynamic>>? _webClickSub;

  void configure({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;
  }

  Future<void> startListening() async {
    _openedSub?.cancel();

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleMessage(message);
    });

    _webClickSub?.cancel();
    if (kIsWeb) {
      _webClickSub = pushClickMessages().listen((event) async {
        // Expected shape: { type: 'fcm_notification_click', data: { ...fcmData } }
        final eventType = (event['type'] ?? '').toString();
        if (eventType != 'fcm_notification_click') return;
        final raw = event['data'];
        if (raw is Map) {
          await _handleData(Map<String, dynamic>.from(raw));
        }
      });
    }

    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Ensure we have a navigator ready.
        scheduleMicrotask(() => _handleMessage(initial));
      }
    } catch (e) {
      debugPrint('[PushNotificationService] getInitialMessage failed: $e');
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      try {
        await ApiService.updateFCMToken(t);
      } catch (e) {
        debugPrint('[PushNotificationService] token refresh sync failed: $e');
      }
    });
  }

  Future<void> syncTokenIfPossible() async {
    try {
      // On iOS/macOS this triggers the system prompt; on Android it is a no-op.
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;
      await ApiService.updateFCMToken(token);
    } catch (e) {
      debugPrint('[PushNotificationService] syncTokenIfPossible failed: $e');
    }
  }

  Future<String?> _getToken() async {
    if (!kIsWeb) {
      return FirebaseMessaging.instance.getToken();
    }

    // For web, Firebase may require a VAPID key depending on project settings.
    const vapidKey = String.fromEnvironment('FCM_VAPID_KEY', defaultValue: '');
    try {
      if (vapidKey.isNotEmpty) {
        return FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
      }
      return FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[PushNotificationService] web getToken failed (missing VAPID key?): $e');
      return null;
    }
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    await _handleData(message.data);
  }

  Future<void> _handleData(Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final type = (data['type'] ?? '').toString();
    if (type.isEmpty) return;

    switch (type) {
      case 'patient_prescription_created':
      case 'patient_prescription_status_updated':
        final id = (data['documentId'] ?? data['prescriptionId'] ?? '').toString();
        if (id.isNotEmpty) {
          _openPatientDossier(documentId: id);
        }
        return;

      case 'patient_analysis_result_created':
        final id = (data['documentId'] ?? data['analysisResultId'] ?? '').toString();
        if (id.isNotEmpty) {
          _openPatientDossier(documentId: id);
        }
        return;

      case 'pharmacy_request_created':
        final requestId = (data['requestId'] ?? '').toString();
        if (requestId.isNotEmpty) {
          await _openPharmacyRequestDetails(requestId);
        }
        return;

      case 'pharmacy_prescription_shared':
        final prescriptionId = (data['prescriptionId'] ?? '').toString();
        if (prescriptionId.isNotEmpty) {
          await _openSharedPrescriptionDetails(prescriptionId);
        }
        return;

      case 'pharmacy_request_validated':
      case 'pharmacy_request_rejected':
        // Per requirement: patient shouldn't be navigated anywhere.
        return;

      default:
        return;
    }
  }

  void _openPatientDossier({required String documentId}) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    nav.push(
      MaterialPageRoute(
        builder: (_) => DocumentListScreen(
          title: 'Mon dossier',
          icon: Icons.folder_shared_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)],
          ),
          openDocumentId: documentId,
        ),
      ),
    );
  }

  Future<void> _openPharmacyRequestDetails(String requestId) async {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    try {
      final req = await PharmacyService.getMyRequestModelById(requestId);
      nav.push(
        MaterialPageRoute(
          builder: (_) => PrescriptionDetailsScreen(request: req),
        ),
      );
    } catch (e) {
      debugPrint('[PushNotificationService] open pharmacy request failed: $e');
    }
  }

  Future<void> _openSharedPrescriptionDetails(String prescriptionId) async {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    try {
      final pres = await PharmacyPrescriptionsService.getSharedPrescriptionForPharmacy(prescriptionId);
      nav.push(
        MaterialPageRoute(
          builder: (_) => PrescriptionDetailScreen(prescription: pres),
        ),
      );
    } catch (e) {
      debugPrint('[PushNotificationService] open shared prescription failed: $e');
    }
  }

  Future<void> dispose() async {
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _webClickSub?.cancel();
    _openedSub = null;
    _tokenRefreshSub = null;
    _webClickSub = null;
  }
}
