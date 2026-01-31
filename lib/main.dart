import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalcApp());
}

class CalcApp extends StatelessWidget {
  const CalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calc Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'SF Pro',
      ),
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
  final ScrollController _resultScrollController = ScrollController();

  List<_LineEval> _lineEvals = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);

    _inputScrollController.addListener(() {
      if (!_resultScrollController.hasClients ||
          !_inputScrollController.hasClients) {
        return;
      }
      final target = _inputScrollController.offset.clamp(
        _resultScrollController.position.minScrollExtent,
        _resultScrollController.position.maxScrollExtent,
      );
      if ((_resultScrollController.offset - target).abs() > 0.5) {
        _resultScrollController.jumpTo(target);
      }
    });

    _recomputeLineEvals();
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _focusNode.dispose();
    _inputScrollController.dispose();
    _resultScrollController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _recomputeLineEvals();
  }

  bool _looksLikeMathLine(String line) {
    final t = line.trim();
    if (t.isEmpty) return false;
    if (RegExp(r'[A-Za-z]').hasMatch(t)) return false;
    if (!RegExp(r'\d').hasMatch(t)) return false;
    return RegExp(r'^[0-9+\-*/%^().\s]+$').hasMatch(t);
  }

  String _normalizeExpression(String expr) {
    return expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .trim();
  }

  void _recomputeLineEvals() {
    final lines = _controller.text.split('\n');
    final next = <_LineEval>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        next.add(const _LineEval.empty());
        continue;
      }

      if (!_looksLikeMathLine(trimmed)) {
        next.add(const _LineEval.empty());
        continue;
      }

      final expr = _normalizeExpression(trimmed);
      try {
        final parser = Parser();
        final exp = parser.parse(expr);
        final cm = ContextModel();
        final doubleValue = exp.evaluate(EvaluationType.REAL, cm);
        next.add(_LineEval.value(_formatNumber(doubleValue)));
      } catch (_) {
        next.add(const _LineEval.error());
      }
    }

    setState(() {
      _lineEvals = next;
    });
  }

  String _formatNumber(num value) {
    // Display integers without .0, else up to 6 fractional digits trimmed
    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    final s = value.toStringAsFixed(6);
    return s
        .replaceFirst(RegExp(r"\.0+$"), '')
        .replaceFirst(RegExp(r"0+$"), '');
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF212225);
    const inputTextColor = Color(0xFFE1E4E7);
    const resultTextColor = Color(0xFF9CD14E);

    final inputStyle = const TextStyle(
      fontSize: 22,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: inputTextColor,
    );

    final resultBaseStyle = const TextStyle(
      fontSize: 22,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: resultTextColor,
    );

    final resultSpans = <InlineSpan>[];
    for (var i = 0; i < _lineEvals.length; i++) {
      final e = _lineEvals[i];
      final lineText = e.isEmpty ? '' : (e.isError ? '' : (e.value ?? ''));

      resultSpans.add(
        TextSpan(
          text: lineText,
          style: TextStyle(
            color: e.isError ? Colors.red[700] : resultTextColor,
          ),
        ),
      );
      if (i != _lineEvals.length - 1) {
        resultSpans.add(const TextSpan(text: '\n'));
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: GestureDetector(
                key: const ValueKey('input_area'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _focusNode.requestFocus(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  color: bgColor,
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _controller,
                    scrollController: _inputScrollController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    expands: true,
                    style: inputStyle,
                    cursorColor: inputTextColor,
                    decoration: const InputDecoration(
                      hintText: 'Tap to type …',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0x88E1E4E7)),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                key: const ValueKey('result_area'),
                padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                color: bgColor,
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: _resultScrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: RichText(
                              textAlign: TextAlign.right,
                              text: TextSpan(
                                style: resultBaseStyle,
                                children: resultSpans,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineEval {
  final String? value;
  final bool isError;
  final bool isEmpty;

  const _LineEval._(
      {required this.value, required this.isError, required this.isEmpty});

  const _LineEval.empty() : this._(value: null, isError: false, isEmpty: true);
  const _LineEval.error() : this._(value: null, isError: true, isEmpty: false);
  const _LineEval.value(String v)
      : this._(value: v, isError: false, isEmpty: false);
}
