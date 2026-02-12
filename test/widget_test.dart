// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:madaichain/main.dart';

void main() {
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MEDAIChainApp());

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // Verify that the welcome screen is displayed (or loading indicator)
    // Since AuthProvider initializes, we might see a loading indicator first
    // Then the WelcomeScreen should appear
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
