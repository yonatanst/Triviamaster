import 'package:flutter/material.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  final String category;
  final int total;
  final int correct;
  final int score;
  final int avgMs;
  final int? deltaCat;
  final int? deltaOverall;

  const ResultsScreen({
    super.key,
    required this.category,
    required this.total,
    required this.correct,
    required this.score,
    required this.avgMs,
    this.deltaCat,
    this.deltaOverall,
  });

  @override
  Widget build(BuildContext context) {
    String d(int? v) {
      if (v == null) return '—';
      if (v == 0) return '±0';
      return v > 0 ? '+$v' : '$v';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Round complete!', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _kv('Category', category),
            _kv('Questions', '$total'),
            _kv('Correct', '$correct'),
            _kv('Accuracy', '${(correct / total * 100).toStringAsFixed(0)}%'),
            _kv('Score', '$score'),
            _kv('Avg time', '${(avgMs / 1000).toStringAsFixed(2)}s'),
            const Divider(height: 24),
            Text('Rating changes', style: Theme.of(context).textTheme.titleMedium),
            _kv('Category delta', d(deltaCat)),
            _kv('Overall delta', d(deltaOverall)),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.help_outline),
              label: const Text('Why did my rating change?'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Why did my rating change?'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('We use an Elo-style update:'),
                        SizedBox(height: 8),
                        Text('new = old + K × (actual − expected)'),
                        SizedBox(height: 8),
                        Text('K = 24, expected = 0.60. If you do better than expected, you gain rating; if not, you lose a little.'),
                        SizedBox(height: 8),
                        Text('Overall rating is the average across categories, so it moves a bit each round.'),
                      ],
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                );
              },
            ),
            const Spacer(),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (r) => false,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('Play again'),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
            Flexible(child: Text(v)),
          ],
        ),
      );
}
