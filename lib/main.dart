import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CalcApp());
}

class CalcApp extends StatelessWidget {
  const CalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TypeCal Mobile',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro',
      ),
      debugShowCheckedModeBanner: false,
      home: const CalcHomePage(),
    );
  }
}

class CalcHomePage extends StatefulWidget {
  const CalcHomePage({super.key});

  @override
  State<CalcHomePage> createState() => _CalcHomePageState();
}

class _CalcHomePageState extends State<CalcHomePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _inputScrollController = ScrollController();

  final _CurrencyService _currencyService = _CurrencyService();

  Timer? _debounceTimer;
  int _evaluationRunId = 0;
  double _inputScrollOffset = 0;

  List<_LineEval> _lineEvals = const [];

  static const double _editorFontSize = 22;
  static const double _editorLineHeight = 1.45;

  static final RegExp _currencyPattern = RegExp(
    r'^(.+?)\s*([a-zA-Z]{3})\s+(?:to|tp)\s+([a-zA-Z]{3})',
    caseSensitive: false,
  );
  static final RegExp _unitPattern = RegExp(
    r'^(.+?)\s*([a-zA-Z]+)\s+(?:to|tp)\s+([a-zA-Z]+)',
    caseSensitive: false,
  );
  static final RegExp _assignmentPattern =
      RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.+)');

  static const Map<String, String> _unitAliases = {
    'mm': 'mm',
    'millimeter': 'mm',
    'millimeters': 'mm',
    'cm': 'cm',
    'centimeter': 'cm',
    'centimeters': 'cm',
    'm': 'm',
    'meter': 'm',
    'meters': 'm',
    'km': 'km',
    'kilometer': 'km',
    'kilometers': 'km',
    'in': 'in',
    'inch': 'in',
    'inches': 'in',
    'ft': 'ft',
    'foot': 'ft',
    'feet': 'ft',
    'yd': 'yd',
    'yard': 'yd',
    'yards': 'yd',
    'mi': 'mi',
    'mile': 'mi',
    'miles': 'mi',
    'mg': 'mg',
    'milligram': 'mg',
    'milligrams': 'mg',
    'g': 'g',
    'gram': 'g',
    'grams': 'g',
    'kg': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'oz': 'oz',
    'ounce': 'oz',
    'ounces': 'oz',
    'lb': 'lb',
    'lbs': 'lb',
    'pound': 'lb',
    'pounds': 'lb',
    'ml': 'ml',
    'milliliter': 'ml',
    'milliliters': 'ml',
    'millilitre': 'ml',
    'millilitres': 'ml',
    'l': 'l',
    'liter': 'l',
    'liters': 'l',
    'litre': 'l',
    'litres': 'l',
    'cup': 'cup',
    'cups': 'cup',
    'pt': 'pt',
    'pint': 'pt',
    'pints': 'pt',
    'qt': 'qt',
    'quart': 'qt',
    'quarts': 'qt',
    'gal': 'gal',
    'gallon': 'gal',
    'gallons': 'gal',
    'c': 'c',
    'celsius': 'c',
    'celcius': 'c',
    'f': 'f',
    'fahrenheit': 'f',
    'k': 'k',
    'kelvin': 'k',
  };

  static final Map<String, _UnitDefinition> _unitDefinitions = {
    'mm': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _divBy1000,
      fromBase: _mulBy1000,
    ),
    'cm': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _divBy100,
      fromBase: _mulBy100,
    ),
    'm': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _identity,
      fromBase: _identity,
    ),
    'km': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _mulBy1000,
      fromBase: _divBy1000,
    ),
    'in': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _inchToMeter,
      fromBase: _meterToInch,
    ),
    'ft': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _footToMeter,
      fromBase: _meterToFoot,
    ),
    'yd': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _yardToMeter,
      fromBase: _meterToYard,
    ),
    'mi': const _UnitDefinition(
      category: _UnitCategory.length,
      toBase: _mileToMeter,
      fromBase: _meterToMile,
    ),
    'mg': const _UnitDefinition(
      category: _UnitCategory.mass,
      toBase: _mgToKg,
      fromBase: _kgToMg,
    ),
    'g': const _UnitDefinition(
      category: _UnitCategory.mass,
      toBase: _gToKg,
      fromBase: _kgToG,
    ),
    'kg': const _UnitDefinition(
      category: _UnitCategory.mass,
      toBase: _identity,
      fromBase: _identity,
    ),
    'oz': const _UnitDefinition(
      category: _UnitCategory.mass,
      toBase: _ozToKg,
      fromBase: _kgToOz,
    ),
    'lb': const _UnitDefinition(
      category: _UnitCategory.mass,
      toBase: _lbToKg,
      fromBase: _kgToLb,
    ),
    'ml': const _UnitDefinition(
      category: _UnitCategory.volume,
      toBase: _mlToLiter,
      fromBase: _literToMl,
    ),
    'l': const _UnitDefinition(
      category: _UnitCategory.volume,
      toBase: _identity,
      fromBase: _identity,
    ),
    'cup': const _UnitDefinition(
      category: _UnitCategory.volume,
      toBase: _cupToLiter,
      fromBase: _literToCup,
    ),
    'pt': const _UnitDefinition(
      category: _UnitCategory.volume,
      toBase: _pintToLiter,
      fromBase: _literToPint,
    ),
    'qt': const _UnitDefinition(
      category: _UnitCategory.volume,
      toBase: _quartToLiter,
      fromBase: _literToQuart,
    ),
    'gal': const _UnitDefinition(
      category: _UnitCategory.volume,
      toBase: _gallonToLiter,
      fromBase: _literToGallon,
    ),
    'c': const _UnitDefinition(
      category: _UnitCategory.temperature,
      toBase: _identity,
      fromBase: _identity,
    ),
    'f': const _UnitDefinition(
      category: _UnitCategory.temperature,
      toBase: _fahrenheitToCelsius,
      fromBase: _celsiusToFahrenheit,
    ),
    'k': const _UnitDefinition(
      category: _UnitCategory.temperature,
      toBase: _kelvinToCelsius,
      fromBase: _celsiusToKelvin,
    ),
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    _inputScrollController.addListener(_onInputScrolled);
    unawaited(_initializeServices());
    _scheduleRecompute(immediate: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onInputChanged);
    _inputScrollController.removeListener(_onInputScrolled);
    _controller.dispose();
    _focusNode.dispose();
    _inputScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _currencyService.initialize();
    _scheduleRecompute(immediate: true);
  }

  void _onInputScrolled() {
    final offset =
        _inputScrollController.hasClients ? _inputScrollController.offset : 0.0;
    if ((offset - _inputScrollOffset).abs() < 0.5) {
      return;
    }
    setState(() {
      _inputScrollOffset = offset;
    });
  }

  void _onInputChanged() {
    _scheduleRecompute();
  }

  void _scheduleRecompute({bool immediate = false}) {
    _debounceTimer?.cancel();
    if (immediate) {
      unawaited(_evaluateAllLines());
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 220), () {
      unawaited(_evaluateAllLines());
    });
  }

  Future<void> _evaluateAllLines() async {
    final runId = ++_evaluationRunId;
    final lines = _controller.text.split('\n');
    final next = <_LineEval>[];
    final asyncJobs = <_AsyncLineJob>[];
    final variables = <String, double>{};

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        next.add(const _LineEval.empty());
        continue;
      }

      final assignment = _parseVariableAssignment(line);
      if (assignment != null) {
        try {
          final value = _evaluateExpression(assignment.expression, variables);
          variables[assignment.name] = value;
          next.add(_LineEval.value(_formatResult(value)));
        } catch (_) {
          next.add(const _LineEval.empty());
        }
        continue;
      }

      final currencyMatch = _parseCurrencyCommand(line);
      if (currencyMatch != null) {
        try {
          final amount =
              _evaluateExpression(currencyMatch.amountExpression, variables);
          next.add(const _LineEval.loading('converting'));
          asyncJobs.add(
            _AsyncLineJob.currency(
              lineIndex: next.length - 1,
              amount: amount,
              fromCurrency: currencyMatch.fromCurrency,
              toCurrency: currencyMatch.toCurrency,
            ),
          );
        } catch (_) {
          next.add(const _LineEval.empty());
        }
        continue;
      }

      final unitMatch = _parseUnitConversion(line);
      if (unitMatch != null) {
        try {
          final amount =
              _evaluateExpression(unitMatch.amountExpression, variables);
          final converted = _convertUnit(
            amount,
            unitMatch.fromUnit,
            unitMatch.toUnit,
          );
          if (converted == null) {
            next.add(const _LineEval.error('unsupported unit conversion'));
          } else {
            next.add(_LineEval.value(_formatResult(converted)));
          }
        } catch (_) {
          next.add(const _LineEval.empty());
        }
        continue;
      }

      if (_looksLikeExpressionCandidate(line, variables)) {
        try {
          final value = _evaluateExpression(line, variables);
          next.add(_LineEval.value(_formatResult(value)));
        } catch (_) {
          next.add(const _LineEval.empty());
        }
      } else {
        next.add(const _LineEval.empty());
      }
    }

    if (!mounted || runId != _evaluationRunId) {
      return;
    }
    setState(() {
      _lineEvals = next;
    });

    for (final job in asyncJobs) {
      unawaited(_resolveAsyncJob(job, runId));
    }
  }

  Future<void> _resolveAsyncJob(_AsyncLineJob job, int runId) async {
    _LineEval resolved = const _LineEval.empty();
    try {
      final converted = await _currencyService.convert(
        amount: job.amount,
        fromCurrency: job.fromCurrency,
        toCurrency: job.toCurrency,
      );
      if (converted == null) {
        resolved = const _LineEval.empty();
      } else {
        resolved = _LineEval.value(_formatResult(converted));
      }
    } catch (_) {
      resolved = const _LineEval.empty();
    }

    if (!mounted || runId != _evaluationRunId) {
      return;
    }
    _updateLineEval(job.lineIndex, resolved);
  }

  void _updateLineEval(int index, _LineEval value) {
    if (index < 0 || index >= _lineEvals.length) {
      return;
    }
    setState(() {
      final next = List<_LineEval>.from(_lineEvals);
      next[index] = value;
      _lineEvals = next;
    });
  }

  _VariableAssignment? _parseVariableAssignment(String text) {
    if (text.contains('==') || text.contains('!=')) {
      return null;
    }
    final match = _assignmentPattern.firstMatch(text);
    if (match == null || match.start != 0 || match.end != text.length) {
      return null;
    }

    final name = match.group(1)?.trim();
    final expression = match.group(2)?.trim();
    if (name == null || expression == null || expression.isEmpty) {
      return null;
    }
    return _VariableAssignment(name: name, expression: expression);
  }

  _CurrencyCommand? _parseCurrencyCommand(String text) {
    final match = _currencyPattern.firstMatch(text);
    if (match == null || match.start != 0 || match.end != text.length) {
      return null;
    }

    final amountExpression = match.group(1)?.trim();
    final fromCurrency = match.group(2)?.trim().toUpperCase();
    final toCurrency = match.group(3)?.trim().toUpperCase();
    if (amountExpression == null ||
        amountExpression.isEmpty ||
        fromCurrency == null ||
        toCurrency == null) {
      return null;
    }

    return _CurrencyCommand(
      amountExpression: amountExpression,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
  }

  _UnitConversionCommand? _parseUnitConversion(String text) {
    final match = _unitPattern.firstMatch(text);
    if (match == null || match.start != 0 || match.end != text.length) {
      return null;
    }

    final amountExpression = match.group(1)?.trim();
    final fromRaw = match.group(2)?.trim().toLowerCase();
    final toRaw = match.group(3)?.trim().toLowerCase();
    if (amountExpression == null || fromRaw == null || toRaw == null) {
      return null;
    }

    final fromUnit = _unitAliases[fromRaw];
    final toUnit = _unitAliases[toRaw];
    if (fromUnit == null || toUnit == null) {
      return null;
    }

    return _UnitConversionCommand(
      amountExpression: amountExpression,
      fromUnit: fromUnit,
      toUnit: toUnit,
    );
  }

  bool _looksLikeExpressionCandidate(
      String text, Map<String, double> variables) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (RegExp(r'^[-+]?\d').hasMatch(trimmed)) {
      return true;
    }
    if (RegExp(r'[+\-*/%^()]').hasMatch(trimmed)) {
      return true;
    }
    if (RegExp(r'^(sqrt|sin|cos|tan|log|ln|abs|pow)\(', caseSensitive: false)
        .hasMatch(trimmed)) {
      return true;
    }
    if (trimmed.toLowerCase() == 'pi' || trimmed.toLowerCase() == 'e') {
      return true;
    }
    if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(trimmed)) {
      return variables.containsKey(trimmed);
    }
    return false;
  }

  double _evaluateExpression(String expression, Map<String, double> variables) {
    final parser = ShuntingYardParser();
    final normalized = _normalizeExpression(expression);
    final prepared = _prepareExpressionWithAliases(normalized, variables);
    final exp = parser.parse(prepared.expression);
    final contextModel = ContextModel();
    prepared.aliasBindings.forEach((name, value) {
      contextModel.bindVariable(Variable(name), Number(value));
    });
    contextModel.bindVariable(Variable('pi'), Number(math.pi));
    contextModel.bindVariable(Variable('e'), Number(math.e));

    final evaluated = exp.evaluate(EvaluationType.REAL, contextModel);
    if (evaluated is! num || !evaluated.isFinite) {
      throw StateError('invalid result');
    }
    return evaluated.toDouble();
  }

  String _normalizeExpression(String expression) {
    return expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .trim();
  }

  _PreparedExpression _prepareExpressionWithAliases(
    String expression,
    Map<String, double> variables,
  ) {
    var prepared = expression;
    final aliasBindings = <String, double>{};

    final sortedEntries = variables.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    var aliasIndex = 0;
    for (final entry in sortedEntries) {
      final alias = '__v$aliasIndex';
      final pattern = RegExp(
        '(^|[^A-Za-z0-9_])(${RegExp.escape(entry.key)})(?![A-Za-z0-9_]|\\s*\\()',
      );
      final replaced = prepared.replaceAllMapped(
        pattern,
        (match) => '${match.group(1) ?? ''}$alias',
      );
      if (replaced != prepared) {
        prepared = replaced;
        aliasBindings[alias] = entry.value;
      }
      aliasIndex += 1;
    }

    return _PreparedExpression(
        expression: prepared, aliasBindings: aliasBindings);
  }

  String _formatResult(num result) {
    final rounded = (result * 100).roundToDouble() / 100;
    final parts = rounded.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    final formattedInteger = integerPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    var cleanDecimal = decimalPart;
    while (cleanDecimal.endsWith('0')) {
      cleanDecimal = cleanDecimal.substring(0, cleanDecimal.length - 1);
    }
    if (cleanDecimal.isEmpty) {
      return formattedInteger;
    }
    return '$formattedInteger,$cleanDecimal';
  }

  double? _convertUnit(double amount, String fromUnit, String toUnit) {
    final fromDefinition = _unitDefinitions[fromUnit];
    final toDefinition = _unitDefinitions[toUnit];
    if (fromDefinition == null || toDefinition == null) {
      return null;
    }
    if (fromDefinition.category != toDefinition.category) {
      return null;
    }
    final baseValue = fromDefinition.toBase(amount);
    return toDefinition.fromBase(baseValue);
  }

  void _insertAtCursor(String text) {
    final previousText = _controller.text;
    final selection = _controller.selection;
    final start = selection.start >= 0 ? selection.start : previousText.length;
    final end = selection.end >= 0 ? selection.end : previousText.length;
    final newText =
        '${previousText.substring(0, start)}$text${previousText.substring(end)}';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _focusNode.requestFocus();
  }

  void _applyTemplate(String template) {
    switch (template) {
      case 'currency':
        _insertAtCursor('100 usd to idr');
        break;
      case 'variable':
        _insertAtCursor('tax = 10/100');
        break;
      case 'unit':
        _insertAtCursor('10 km to mi');
        break;
      case 'math':
        _insertAtCursor('(120 + 80) * 0.15');
        break;
    }
  }

  void _clearAll() {
    _evaluationRunId++;
    _controller.clear();
    setState(() {
      _lineEvals = const [];
    });
    _focusNode.requestFocus();
  }

  List<_InlineResultMarker> _computeInlineResultMarkers({
    required BoxConstraints constraints,
    required TextStyle inputStyle,
    required TextStyle chipStyle,
    required TextScaler textScaler,
  }) {
    const leftPadding = 18.0;
    const rightPadding = 18.0;
    const topPadding = 18.0;
    final contentWidth = constraints.maxWidth - leftPadding - rightPadding;
    if (contentWidth <= 0) {
      return const [];
    }

    final fullText = _controller.text;
    final painter = TextPainter(
      text: TextSpan(
        text: fullText.isEmpty ? ' ' : fullText,
        style: inputStyle,
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: null,
    )..layout(maxWidth: contentWidth);

    final lines = fullText.split('\n');
    final markers = <_InlineResultMarker>[];
    var caretOffsetIndex = 0;

    for (var i = 0; i < lines.length && i < _lineEvals.length; i++) {
      final eval = _lineEvals[i];
      final text = _lineResultText(eval);
      if (text == null) {
        caretOffsetIndex += lines[i].length + 1;
        continue;
      }

      final caretOffset = painter.getOffsetForCaret(
        TextPosition(
            offset:
                math.min(caretOffsetIndex + lines[i].length, fullText.length)),
        Rect.zero,
      );

      final chipMetrics = _measureChip(text, chipStyle, textScaler);
      final rawLeft = leftPadding + caretOffset.dx + 10;
      final maxChipWidth = math.max(120.0, constraints.maxWidth * 0.52);
      final width = math.min(chipMetrics.width, maxChipWidth);
      final left = rawLeft.clamp(
        leftPadding,
        constraints.maxWidth - rightPadding - width,
      );

      final top = topPadding +
          caretOffset.dy +
          (painter.preferredLineHeight - chipMetrics.height) / 2 -
          _inputScrollOffset;

      markers.add(
        _InlineResultMarker(
          lineEval: eval,
          left: left,
          top: top,
          maxWidth: maxChipWidth,
        ),
      );

      caretOffsetIndex += lines[i].length + 1;
    }
    return markers;
  }

  String? _lineResultText(_LineEval eval) {
    if (eval.isEmpty) {
      return null;
    }
    if (eval.isLoading) {
      return '...';
    }
    if (eval.isError) {
      return eval.errorLabel;
    }
    return eval.value;
  }

  _ChipMetrics _measureChip(
      String text, TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout(maxWidth: 1000);
    return _ChipMetrics(width: painter.width, height: painter.height);
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF181B1F);
    const cardColor = Color(0xFF22272F);
    const textColor = Color(0xFFE6EDF3);
    const hintColor = Color(0xFF93A1B0);
    const resultColor = Color(0xFF5AC8FA);
    const errorColor = Color(0xFFFF5A5F);
    const toolbarColor = Color(0xFF101317);
    const templateMenuColor = Color(0xFF171D24);
    const templateMenuBorderColor = Color(0xFF2A3340);

    const inputStyle = TextStyle(
      fontSize: _editorFontSize,
      height: _editorLineHeight,
      fontWeight: FontWeight.w500,
      color: textColor,
      letterSpacing: -0.2,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_alt_outlined,
                          color: textColor, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'TypeCal Notes',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: const PopupMenuThemeData(
                            color: templateMenuColor,
                            surfaceTintColor: Colors.transparent,
                            shadowColor: Color(0x5C000000),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                              side: BorderSide(color: templateMenuBorderColor),
                            ),
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: 'Insert template',
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFFB8C2CC)),
                          offset: const Offset(0, 12),
                          menuPadding: const EdgeInsets.symmetric(vertical: 6),
                          constraints: const BoxConstraints(
                            minWidth: 224,
                            maxWidth: 252,
                          ),
                          onSelected: _applyTemplate,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'math',
                              height: 38,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: _TemplateMenuItem(
                                icon: Icons.functions_rounded,
                                label: 'Math example',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'currency',
                              height: 38,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: _TemplateMenuItem(
                                icon: Icons.currency_exchange_rounded,
                                label: 'Currency conversion',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'unit',
                              height: 38,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: _TemplateMenuItem(
                                icon: Icons.straighten_rounded,
                                label: 'Unit conversion',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'variable',
                              height: 38,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: _TemplateMenuItem(
                                icon: Icons.data_object_rounded,
                                label: 'Variable assignment',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _clearAll,
                        tooltip: 'Clear all',
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFB8C2CC)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                key: const ValueKey('input_area'),
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF2D3742)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const chipStyle = TextStyle(
                      color: resultColor,
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    );
                    final markers = _computeInlineResultMarkers(
                      constraints: constraints,
                      inputStyle: inputStyle,
                      chipStyle: chipStyle,
                      textScaler: MediaQuery.textScalerOf(context),
                    );

                    return Stack(
                      children: [
                        TextField(
                          key: const ValueKey('combined_editor'),
                          focusNode: _focusNode,
                          controller: _controller,
                          scrollController: _inputScrollController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enableSuggestions: false,
                          smartDashesType: SmartDashesType.disabled,
                          smartQuotesType: SmartQuotesType.disabled,
                          maxLines: null,
                          expands: true,
                          style: inputStyle,
                          cursorColor: const Color(0xFFF7FBFF),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                'Type naturally...\n2+2\nprice = 120*4\nprice usd to idr\n10 km to mi',
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 18,
                              height: 1.4,
                            ),
                            contentPadding: EdgeInsets.fromLTRB(18, 18, 18, 22),
                          ),
                        ),
                        IgnorePointer(
                          child: ClipRect(
                            child: Stack(
                              children: [
                                for (final marker in markers)
                                  Positioned(
                                    left: marker.left,
                                    top: marker.top,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: marker.maxWidth,
                                      ),
                                      child: _InlineLineResult(
                                        lineEval: marker.lineEval,
                                        resultColor: resultColor,
                                        errorColor: errorColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              decoration: BoxDecoration(
                color: toolbarColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A3038)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    _ToolbarButton(
                        label: '+', onTap: () => _insertAtCursor('+')),
                    _ToolbarButton(
                        label: '-', onTap: () => _insertAtCursor('-')),
                    _ToolbarButton(
                        label: '×', onTap: () => _insertAtCursor('×')),
                    _ToolbarButton(
                        label: '÷', onTap: () => _insertAtCursor('÷')),
                    _ToolbarButton(
                        label: '=', onTap: () => _insertAtCursor('=')),
                    _ToolbarButton(
                        label: 'sqrt()',
                        onTap: () => _insertAtCursor('sqrt()')),
                    _ToolbarButton(
                        label: 'var', onTap: () => _insertAtCursor('name = ')),
                    _ToolbarButton(
                        label: 'usd-idr',
                        onTap: () => _insertAtCursor('100 usd to idr')),
                    _ToolbarButton(
                        label: 'km-mi',
                        onTap: () => _insertAtCursor('10 km to mi')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD4DBE3),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateMenuItem extends StatelessWidget {
  const _TemplateMenuItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0x215AC8FA),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0x365AC8FA)),
          ),
          child: Icon(icon, size: 13, color: const Color(0xFF5AC8FA)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _LineEval {
  const _LineEval._({
    required this.value,
    required this.isError,
    required this.isEmpty,
    required this.isLoading,
    this.errorLabel = 'error',
  });

  final String? value;
  final bool isError;
  final bool isEmpty;
  final bool isLoading;
  final String errorLabel;

  const _LineEval.empty()
      : this._(
          value: null,
          isError: false,
          isEmpty: true,
          isLoading: false,
        );

  const _LineEval.loading(String label)
      : this._(
          value: null,
          isError: false,
          isEmpty: false,
          isLoading: true,
          errorLabel: label,
        );

  const _LineEval.error(String label)
      : this._(
          value: null,
          isError: true,
          isEmpty: false,
          isLoading: false,
          errorLabel: label,
        );

  const _LineEval.value(String v)
      : this._(
          value: v,
          isError: false,
          isEmpty: false,
          isLoading: false,
        );
}

class _InlineLineResult extends StatelessWidget {
  const _InlineLineResult({
    required this.lineEval,
    required this.resultColor,
    required this.errorColor,
  });

  final _LineEval lineEval;
  final Color resultColor;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    if (lineEval.isLoading) {
      return const Text(
        '...',
        style: TextStyle(
          color: Color(0xFF7FBDD9),
          fontSize: 16,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      );
    }

    final isError = lineEval.isError;
    final text = isError ? lineEval.errorLabel : '${lineEval.value}';

    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(
        color: isError ? errorColor : resultColor,
        fontSize: 16,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
    );
  }
}

class _InlineResultMarker {
  const _InlineResultMarker({
    required this.lineEval,
    required this.left,
    required this.top,
    required this.maxWidth,
  });

  final _LineEval lineEval;
  final double left;
  final double top;
  final double maxWidth;
}

class _ChipMetrics {
  const _ChipMetrics({required this.width, required this.height});

  final double width;
  final double height;
}

class _PreparedExpression {
  const _PreparedExpression({
    required this.expression,
    required this.aliasBindings,
  });

  final String expression;
  final Map<String, double> aliasBindings;
}

class _AsyncLineJob {
  const _AsyncLineJob.currency({
    required this.lineIndex,
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
  });

  final int lineIndex;
  final double amount;
  final String fromCurrency;
  final String toCurrency;
}

class _VariableAssignment {
  const _VariableAssignment({required this.name, required this.expression});

  final String name;
  final String expression;
}

class _CurrencyCommand {
  const _CurrencyCommand({
    required this.amountExpression,
    required this.fromCurrency,
    required this.toCurrency,
  });

  final String amountExpression;
  final String fromCurrency;
  final String toCurrency;
}

class _UnitConversionCommand {
  const _UnitConversionCommand({
    required this.amountExpression,
    required this.fromUnit,
    required this.toUnit,
  });

  final String amountExpression;
  final String fromUnit;
  final String toUnit;
}

enum _UnitCategory {
  length,
  mass,
  volume,
  temperature,
}

class _UnitDefinition {
  const _UnitDefinition({
    required this.category,
    required this.toBase,
    required this.fromBase,
  });

  final _UnitCategory category;
  final double Function(double) toBase;
  final double Function(double) fromBase;
}

class _CurrencyService {
  static const String _ratesKey = 'typecal_rates';
  static const String _ratesUpdatedAtKey = 'typecal_rates_updated_at';
  static const Duration _refreshInterval = Duration(hours: 6);

  Map<String, double> _rates = const {};
  DateTime? _updatedAt;
  Future<void>? _ongoingFetch;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRates = prefs.getString(_ratesKey);
    final rawUpdatedAt = prefs.getInt(_ratesUpdatedAtKey);

    if (rawRates != null) {
      try {
        final decoded = jsonDecode(rawRates);
        if (decoded is Map<String, dynamic>) {
          final parsed = <String, double>{};
          decoded.forEach((key, value) {
            if (value is num) {
              parsed[key.toUpperCase()] = value.toDouble();
            }
          });
          if (parsed.isNotEmpty) {
            _rates = parsed;
          }
        }
      } catch (_) {
        // Keep empty/default rates when persisted data is malformed.
      }
    }

    if (rawUpdatedAt != null) {
      _updatedAt = DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt);
    }

    await _refreshRatesIfNeeded();
  }

  Future<double?> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final fromCode = fromCurrency.toUpperCase();
    final toCode = toCurrency.toUpperCase();
    if (fromCode == toCode) {
      return amount;
    }

    await _refreshRatesIfNeeded();

    if (_rates.isEmpty) {
      return null;
    }

    final fromRate = fromCode == 'USD' ? 1.0 : _rates[fromCode];
    final toRate = toCode == 'USD' ? 1.0 : _rates[toCode];
    if (fromRate == null || toRate == null) {
      return null;
    }

    final amountInUsd = amount / fromRate;
    return amountInUsd * toRate;
  }

  Future<void> _refreshRatesIfNeeded() async {
    if (_ongoingFetch != null) {
      await _ongoingFetch;
      return;
    }

    final now = DateTime.now();
    final stale = _updatedAt == null ||
        now.difference(_updatedAt!) >= _refreshInterval ||
        _rates.isEmpty;
    if (!stale) {
      return;
    }

    _ongoingFetch = _fetchAndCacheRates();
    try {
      await _ongoingFetch;
    } finally {
      _ongoingFetch = null;
    }
  }

  Future<void> _fetchAndCacheRates() async {
    try {
      final uri = Uri.parse('https://api.exchangerate-api.com/v4/latest/USD');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final rates = decoded['rates'];
      if (rates is! Map<String, dynamic>) {
        return;
      }

      final parsed = <String, double>{};
      rates.forEach((key, value) {
        if (value is num) {
          parsed[key.toUpperCase()] = value.toDouble();
        }
      });
      if (parsed.isEmpty) {
        return;
      }

      _rates = parsed;
      _updatedAt = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ratesKey, jsonEncode(_rates));
      await prefs.setInt(
          _ratesUpdatedAtKey, _updatedAt!.millisecondsSinceEpoch);
    } catch (_) {
      // Ignore network/cache errors and keep existing cached rates.
    }
  }
}

double _identity(double v) => v;
double _divBy1000(double v) => v / 1000;
double _mulBy1000(double v) => v * 1000;
double _divBy100(double v) => v / 100;
double _mulBy100(double v) => v * 100;
double _inchToMeter(double v) => v * 0.0254;
double _meterToInch(double v) => v / 0.0254;
double _footToMeter(double v) => v * 0.3048;
double _meterToFoot(double v) => v / 0.3048;
double _yardToMeter(double v) => v * 0.9144;
double _meterToYard(double v) => v / 0.9144;
double _mileToMeter(double v) => v * 1609.344;
double _meterToMile(double v) => v / 1609.344;
double _mgToKg(double v) => v / 1000000;
double _kgToMg(double v) => v * 1000000;
double _gToKg(double v) => v / 1000;
double _kgToG(double v) => v * 1000;
double _ozToKg(double v) => v * 0.028349523125;
double _kgToOz(double v) => v / 0.028349523125;
double _lbToKg(double v) => v * 0.45359237;
double _kgToLb(double v) => v / 0.45359237;
double _mlToLiter(double v) => v / 1000;
double _literToMl(double v) => v * 1000;
double _cupToLiter(double v) => v * 0.2365882365;
double _literToCup(double v) => v / 0.2365882365;
double _pintToLiter(double v) => v * 0.473176473;
double _literToPint(double v) => v / 0.473176473;
double _quartToLiter(double v) => v * 0.946352946;
double _literToQuart(double v) => v / 0.946352946;
double _gallonToLiter(double v) => v * 3.785411784;
double _literToGallon(double v) => v / 3.785411784;
double _fahrenheitToCelsius(double v) => (v - 32) * (5 / 9);
double _celsiusToFahrenheit(double v) => (v * 9) / 5 + 32;
double _kelvinToCelsius(double v) => v - 273.15;
double _celsiusToKelvin(double v) => v + 273.15;
