// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autoatendimento/main.dart';

void main() {
  testWidgets('App should start', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TotemApp());

    // Verify that app starts (splash screen shows)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
