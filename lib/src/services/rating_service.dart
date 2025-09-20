import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef IntPair = (int, int);

class RatingService {
  static Future<IntPair> applyRoundResults({
    required String category,
    required int currentRating,
    required int correctCount,
    required int totalCount,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      final del = _computeDelta(currentRating, correctCount, totalCount);
      return (del, del);
    }

    final fs = FirebaseFirestore.instance;
    final userRef = fs.collection('users').doc(uid);

    return await fs.runTransaction<IntPair>((tx) async {
      final snap = await tx.get(userRef);
      final data = (snap.data() ?? <String, dynamic>{});
      final ratings = Map<String, dynamic>.from(data['ratings'] ?? {});
      final overall = (ratings['overall'] is num) ? (ratings['overall'] as num).toInt() : 1200;
      final catStart = (ratings[category] is num) ? (ratings[category] as num).toInt() : currentRating;

      final catDelta = _computeDelta(catStart, correctCount, totalCount);
      final newCat = catStart + catDelta;

      final overallDelta = _computeDelta(overall, correctCount, totalCount);
      final newOverall = overall + overallDelta;

      ratings[category] = newCat;
      ratings['overall'] = newOverall;

      tx.set(userRef, {
        'ratings': ratings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return (catDelta, overallDelta);
    });
  }

  static int _computeDelta(int rating, int correct, int total) {
    if (total <= 0) return 0;
    final score = correct / total;
    const k = 24.0;
    const expected = 0.5;
    final delta = (k * (score - expected));
    return delta.round().clamp(-32, 32);
  }
}
