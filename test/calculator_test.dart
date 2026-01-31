import 'package:flutter_test/flutter_test.dart';
import 'package:math_expressions/math_expressions.dart';

String eval(String expr) {
  final parser = Parser();
  final exp = parser.parse(expr);
  final cm = ContextModel();
  final value = exp.evaluate(EvaluationType.REAL, cm);
  if (value is int || value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  final s = (value as num).toStringAsFixed(6);
  return s.replaceFirst(RegExp(r"\.0+$"), '').replaceFirst(RegExp(r"0+$"), '');
}

void main() {
  test('basic arithmetic', () {
    expect(eval('1+2'), '3');
    expect(eval('10-3'), '7');
    expect(eval('4*2'), '8');
    expect(eval('9/3'), '3');
  });

  test('precedence and parentheses', () {
    expect(eval('2+3*4'), '14');
    expect(eval('(2+3)*4'), '20');
  });

  test('power operator', () {
    expect(eval('2^3'), '8');
  });
}
