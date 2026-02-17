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
  testWidgets('CalcApp loads and shows combined editor',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CalcApp());

    // Single editor area exists
    expect(find.byKey(const ValueKey('input_area')), findsOneWidget);
    expect(find.byKey(const ValueKey('combined_editor')), findsOneWidget);

    // Input hint is present
    expect(find.textContaining('Type naturally'), findsOneWidget);
  });

  testWidgets('Template popup menu uses dark surface styling',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CalcApp());

    await tester.tap(find.byTooltip('Insert template'));
    await tester.pumpAndSettle();

    final menuEntry = find.text('Math example');
    expect(menuEntry, findsOneWidget);

    final popupMaterials = tester
        .widgetList<Material>(
          find.ancestor(of: menuEntry, matching: find.byType(Material)),
        )
        .toList();

    expect(
      popupMaterials
          .any((material) => material.color == const Color(0xFF171D24)),
      isTrue,
    );
  });
}
