import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:calc_mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('var1 assignment, expression, and currency command resolve',
      (tester) async {
    await tester.pumpWidget(const CalcApp());

    final editor = find.byKey(const ValueKey('combined_editor'));
    expect(editor, findsOneWidget);

    await tester.enterText(
      editor,
      'var1 = 1+2\nvar1 + 1\nvar1 usd to usd',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Two lines should evaluate to 3:
    // - assignment (`var1 = 1+2`)
    // - same-currency conversion (`var1 usd to usd`)
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('4'), findsOneWidget);
  });
}
