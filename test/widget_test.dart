// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:medaichainmobile/main.dart';
import 'package:medaichainmobile/providers/auth_provider.dart';
import 'package:medaichainmobile/providers/medicines_provider.dart';
import 'package:medaichainmobile/providers/calendar_provider.dart';
import 'package:medaichainmobile/providers/patients_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
          ChangeNotifierProvider(create: (_) => MedicinesProvider()),
          ChangeNotifierProvider(create: (_) => CalendarProvider()),
          ChangeNotifierProvider(create: (_) => PatientsProvider()),
        ],
        child: const MEDAIChainApp(),
      ),
    );

    // Wait for the app to finish loading
    await tester.pumpAndSettle();

    // Verify that the app has loaded (check for any widget from the app)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
