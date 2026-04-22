import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../screens/patients/patient_medical_record_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? navigatorKey;

  void init(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    _appLinks = AppLinks();
    
    _handleInitialLink();
    
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        // Optionnel : retarder légèrement la navigation pour s'assurer
        // que l'UI initiale (AuthWrapper) est bien montée.
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleUri(uri);
        });
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Error getting initial link: $e');
    }
  }

  void _handleUri(Uri uri) {
    debugPrint('[DeepLinkService] Handling URI: $uri');
    
    bool isMatch = false;
    String? userId;

    if (uri.scheme == 'medaichain' && uri.host == 'records') {
      isMatch = true;
      if (uri.pathSegments.isNotEmpty) {
         userId = uri.pathSegments.first;
      }
    } else if (uri.scheme == 'https' && uri.host == 'medaichain.app' && uri.pathSegments.contains('records')) {
      isMatch = true;
      final index = uri.pathSegments.indexOf('records');
      if (index + 1 < uri.pathSegments.length) {
        userId = uri.pathSegments[index + 1];
      }
    }

    if (isMatch && userId != null && userId.isNotEmpty) {
      _navigateToProfile(userId);
    }
  }

  void _navigateToProfile(String userId) {
    if (navigatorKey?.currentState != null) {
      debugPrint('[DeepLinkService] Navigating to profile for user: $userId');
      navigatorKey!.currentState!.push(
        MaterialPageRoute(
          builder: (context) => PatientMedicalRecordScreen(patientId: userId),
        ),
      );
    } else {
      debugPrint('[DeepLinkService] Navigator state is null. Cannot navigate.');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}

