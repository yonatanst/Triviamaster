import 'dart:async';
import 'package:flutter/material.dart';
import 'package:triviamaster/src/services/question_service.dart';

class GameScreen extends StatefulWidget {
  final String category;
  final int startingRating;
  final int? questionLimit;
  final bool rated;

  const GameScreen({
    super.key,
    required this.category,
    required this.startingRating,
    this.questionLimit,
    this.rated = true,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _perQuestionSeconds = 20;

  int _currentIndex = 0;
  int _score = 0;
  late int _currentRating;

  Map<String, dynamic>? _currentQ;
  bool _loading = false;

  final Set<String> _seen = <String>{};

  bool _isAdvancing = false; // prevents double-advance inside a question
  bool _navigating = false;  // prevents double navigation at round end

  Timer? _timer;
  int _timeLeft = _perQuestionSeconds;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.startingRating;
    _loadNextQuestion(first: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _totalQuestions => widget.questionLimit ?? 10;

  Future<void> _loadNextQuestion({bool first = false}) async {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _timeLeft = _perQuestionSeconds;
    });

    try {
      final data = await QuestionService.nextQuestion(
        uid: 'guest', // plug your auth uid here if available
        rating: _currentRating,
        category: widget.category,
        seenKeys: _seen.toList(),
      );

      final key = (data['key'] as String?) ??
          '${data['category']}:${data['text']}';

      _seen.add(key);
      setState(() {
        _currentQ = data;
        _loading = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_timeLeft <= 1) {
          t.cancel();
          _onTimeout();
        } else {
          setState(() => _timeLeft--);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load question: $e')),
      );
    }
  }

  void _onTimeout() {
    if (!mounted) return;
    _advance();
  }

  void _onAnswer(int index) {
    if (!mounted || _currentQ == null) return;
    final correct = index == (_currentQ!['answerIndex'] as int);
    if (correct) _score++;
    _advance();
  }

  Future<void> _advance() async {
    if (_isAdvancing) return;
    _isAdvancing = true;
    _timer?.cancel();

    final isLast = _currentIndex + 1 >= _totalQuestions;
    if (isLast) {
      if (_navigating) return;
      _navigating = true;

      // Navigate on the next frame to avoid !_debugLocked
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _ResultsScreen(
              category: widget.category,
              total: _totalQuestions,
              score: _score,
              startRating: widget.startingRating,
            ),
          ),
        );
      });
      return;
    }

    setState(() {
      _currentIndex++;
    });
    await _loadNextQuestion();
    _isAdvancing = false;
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQ;
    return Scaffold(
      appBar: AppBar(
        title: Text('Play — ${widget.category}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(child: Text('$_timeLeft s')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading || q == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    children: [
                      Chip(label: Text('Q ${_currentIndex + 1} / $_totalQuestions')),
                      Chip(label: Text('Rating: $_currentRating')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q['text'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...List<Widget>.generate(
                    (q['options'] as List).length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                        onPressed: () => _onAnswer(i),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(q['options'][i] as String),
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

class _ResultsScreen extends StatelessWidget {
  final String category;
  final int total;
  final int score;
  final int startRating;

  const _ResultsScreen({
    required this.category,
    required this.total,
    required this.score,
    required this.startRating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Category: $category'),
            const SizedBox(height: 8),
            Text('Score: $score / $total'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
