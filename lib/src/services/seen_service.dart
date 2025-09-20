/// Simple per-session "seen question IDs" tracker.
/// We group by category so each category can track uniqueness separately.
/// (Later we can persist to Firestore across sessions.)
class SeenService {
  static final Map<String, Set<String>> _seenByCategory = {};

  static List<String> getSeenIds(String category) {
    return List<String>.from(_seenByCategory[category]?.toList() ?? const []);
    // returning a copy so callers can't mutate internal set accidentally
  }

  static void markSeen(String category, String id) {
    final set = _seenByCategory.putIfAbsent(category, () => <String>{});
    set.add(id);
  }

  static void clearCategory(String category) {
    _seenByCategory.remove(category);
  }

  static void clearAll() {
    _seenByCategory.clear();
  }
}
