import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../services/rating_service.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _categories = const [
    'general','science','history','geography','sports','movies','music',
  ];
  String _selected = 'general';

  String _displayName = 'Guest';
  Map<String, int> _ratings = {
    'overall': 1200,
    'general': 1200,'science':1200,'history':1200,'geography':1200,'sports':1200,'movies':1200,'music':1200,
  };

  String? _lastCat;
  int _lastCatDelta = 0;
  Timer? _flashReset;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final boot = await UserService.bootstrap();
    setState(() {
      _displayName = (boot['displayName'] as String?) ?? 'Guest';
      final r = Map<String, dynamic>.from(boot['ratings'] ?? {});
      _ratings = {
        for (final e in r.entries) e.key: (e.value as num).toInt()
      };
      for (final c in _categories) {
        _ratings[c] = _ratings[c] ?? 1200;
      }
      _ratings['overall'] = _ratings['overall'] ?? 1200;
    });

    // live updates
    UserService.userStream().listen((u) {
      if (!mounted) return;
      final r = Map<String, dynamic>.from(u['ratings'] ?? {});
      setState(() {
        _displayName = u['displayName'] as String? ?? _displayName;
        for (final c in _categories) {
          _ratings[c] = (r[c] ?? _ratings[c] ?? 1200) as int;
        }
        _ratings['overall'] = (r['overall'] ?? _ratings['overall'] ?? 1200) as int;
      });
    });
  }

  int get _overall => _ratings['overall'] ?? 1200;

  Future<void> _startRound({required bool rated}) async {
    final start = _ratings[_selected] ?? 1200;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          category: _selected,
          questionLimit: rated ? 10 : null,
          startingRating: start,
          rated: rated,
        ),
      ),
    );
    if (!mounted || result == null) return;

    if (result['rated'] == true) {
      final cat = (result['category'] as String?) ?? _selected;
      final d = result['catDelta'] as int? ?? 0;
      setState(() {
        _lastCat = cat;
        _lastCatDelta = d;
      });
      _flashReset?.cancel();
      _flashReset = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _lastCat = null);
      });
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit display name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await UserService.setDisplayName(newName);
      setState(() => _displayName = newName);
    }
  }

  @override
  void dispose() {
    _flashReset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overall;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text('AI Trivia')),
            InkWell(
              onTap: _editName,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('Overall: $overall'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _categories.map((c) {
                final selected = c == _selected;
                final rating = _ratings[c] ?? 1200;
                final shouldFlash = _lastCat == c && _lastCatDelta != 0;
                return _CategoryChip(
                  label: c,
                  rating: rating,
                  selected: selected,
                  flashDelta: shouldFlash ? _lastCatDelta : 0,
                  onTap: () => setState(() => _selected = c),
                  vsync: this,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _BigTile(
              icon: Icons.play_arrow,
              title: 'Start 10-question Round',
              subtitle: 'Auto-advance after answer or when time is up',
              onTap: () => _startRound(rated: true),
            ),
            const SizedBox(height: 12),
            _BigTile(
              icon: Icons.all_inclusive,
              title: 'Practice Mode',
              subtitle: 'Endless questions, no rating change',
              onTap: () => _startRound(rated: false),
            ),
            const SizedBox(height: 12),
            _BigTile(
              icon: Icons.emoji_events_outlined,
              title: 'Leaderboard',
              subtitle: 'Overall or per-category',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const LeaderboardScreen(initialCategory: 'overall'),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----- UI bits -----

class _BigTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _BigTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final int rating;
  final bool selected;
  final int flashDelta; // 0=no flash, >0 green, <0 red
  final VoidCallback onTap;
  final TickerProvider vsync;

  const _CategoryChip({
    required this.label,
    required this.rating,
    required this.selected,
    required this.flashDelta,
    required this.onTap,
    required this.vsync,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: widget.vsync, duration: const Duration(milliseconds: 650));
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant _CategoryChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashDelta != 0 && oldWidget.flashDelta == 0) {
      _ac
        ..value = 0
        ..forward().whenComplete(() => _ac.reverse());
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label),
          const SizedBox(width: 8),
          _RatingBadge(value: widget.rating, delta: widget.flashDelta),
        ],
      ),
      selected: widget.selected,
      onSelected: (_) => widget.onTap(),
    );

    return ScaleTransition(scale: _pulse, child: base);
  }
}

class _RatingBadge extends StatelessWidget {
  final int value;
  final int delta;
  const _RatingBadge({required this.value, required this.delta});

  @override
  Widget build(BuildContext context) {
    final changed = delta != 0;
    final color = !changed
        ? Theme.of(context).colorScheme.secondary
        : (delta > 0 ? Colors.green : Colors.red);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (changed)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.75, end: 0.0),
            duration: const Duration(milliseconds: 700),
            builder: (context, value, _) => Container(
              width: 46,
              height: 22,
              decoration: BoxDecoration(
                color: color.withOpacity(value),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Text(
              changed ? '$value  ${delta > 0 ? '+$delta' : '$delta'}' : '$value',
              key: ValueKey('$value|$delta'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
