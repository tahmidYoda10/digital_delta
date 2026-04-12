// Digital Delta Widget Tests
// Tests for authentication and core functionality

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_delta/main.dart';

void main() {
  testWidgets('App launches with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const DigitalDeltaApp());

    // Wait for initialization
    await tester.pumpAndSettle();

    // Verify that login page is shown
    expect(find.text('Digital Delta'), findsWidgets);
    expect(find.text('Disaster Relief Logistics'), findsOneWidget);

    // Verify login form elements exist
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('Generate OTP button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const DigitalDeltaApp());
    await tester.pumpAndSettle();

    // Find the Generate OTP button
    expect(find.text('Generate OTP'), findsOneWidget);
  });

  testWidgets('Login button is initially disabled', (WidgetTester tester) async {
    await tester.pumpWidget(const DigitalDeltaApp());
    await tester.pumpAndSettle();

    // Find login button
    final loginButton = find.widgetWithText(ElevatedButton, 'LOGIN');
    expect(loginButton, findsOneWidget);

    // Button should be disabled initially (no username/OTP entered)
    final button = tester.widget<ElevatedButton>(loginButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('Offline indicator is shown', (WidgetTester tester) async {
    await tester.pumpWidget(const DigitalDeltaApp());
    await tester.pumpAndSettle();

    // Verify offline mode indicator
    expect(find.text('Offline Mode Active'), findsOneWidget);
    expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
  });
}