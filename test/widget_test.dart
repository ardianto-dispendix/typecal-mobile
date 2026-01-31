// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calc_mobile/main.dart';

void main() {
  testWidgets('CalcApp loads and shows input + result areas',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CalcApp());

    // Input + result areas exist
    expect(find.byKey(const ValueKey('input_area')), findsOneWidget);
    expect(find.byKey(const ValueKey('result_area')), findsOneWidget);

    // Input hint is present
    expect(find.textContaining('Tap to type'), findsOneWidget);
  });
}
