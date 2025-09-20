import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  final String initialCategory; // 'overall' or a category
  const LeaderboardScreen({super.key, required this.initialCategory});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late String _category;
  String? _errorText;
  List<Map<String, dynamic>>? _fallbackList; // client-sorted fallback

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  Future<void> _runFallbackOnce() async {
    try {
      setState(() {
        _errorText = null;
        _fallbackList = null;
      });
      final snap = await FirebaseFirestore.instance.collection('users').limit(200).get();
      final rows = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final name = (data['displayName'] ?? 'Player') as String;
        final ratings = Map<String, dynamic>.from(data['ratings'] ?? {});
        final r = (ratings[_category] ?? ratings['overall'] ?? 1200);
        rows.add({'name': name, 'rating': (r as num).toInt()});
      }
      rows.sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));
      setState(() => _fallbackList = rows.take(50).toList());
    } catch (e) {
      setState(() => _errorText = 'Fallback failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = const ['overall','general','science','history','geography','sports','movies','music'];

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: cats.map((c) => ChoiceChip(
              label: Text(c),
              selected: _category == c,
              onSelected: (_) {
                setState(() {
                  _category = c;
                  _errorText = null;
                  _fallbackList = null;
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('ratings.${_category}', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                // If live stream errors, show action + allow fallback load.
                if (snap.hasError) {
                  return _FallbackError(
                    error: snap.error,
                    onTryFallback: _runFallbackOnce,
                    fallbackList: _fallbackList,
                  );
                }

                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData) {
                  // No snapshot (often permissions) – show fallback CTA
                  return _FallbackError(
                    error: 'No data (possibly rules/permissions).',
                    onTryFallback: _runFallbackOnce,
                    fallbackList: _fallbackList,
                  );
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No players yet for this category.'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _runFallbackOnce,
                          child: const Text('Try fallback load'),
                        ),
                        if (_fallbackList != null && _fallbackList!.isNotEmpty)
                          Expanded(child: _FallbackList(list: _fallbackList!)),
                      ],
                    ),
                  );
                }

                // Normal live list
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final name = (d['displayName'] ?? 'Player') as String;
                    final rating = ((d['ratings']?[_category]) ?? (d['ratings']?['overall']) ?? 1200) as num;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${i+1}')),
                      title: Text(name),
                      trailing: Text('${rating.toInt()}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackError extends StatelessWidget {
  final Object? error;
  final VoidCallback onTryFallback;
  final List<Map<String, dynamic>>? fallbackList;

  const _FallbackError({
    required this.error,
    required this.onTryFallback,
    required this.fallbackList,
  });

  @override
  Widget build(BuildContext context) {
    final hasFallback = fallbackList != null && fallbackList!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 28),
          const SizedBox(height: 8),
          Text(
            'Live leaderboard query failed.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '$error',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onTryFallback,
            child: const Text('Load once (fallback)'),
          ),
          if (hasFallback) ...[
            const SizedBox(height: 12),
            Expanded(child: _FallbackList(list: fallbackList!)),
          ],
        ],
      ),
    );
  }
}

class _FallbackList extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  const _FallbackList({required this.list});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final row = list[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${i+1}')),
          title: Text(row['name'] as String),
          trailing: Text('${row['rating']}'),
        );
      },
    );
  }
}
