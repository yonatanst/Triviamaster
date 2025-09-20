import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<User> requireAnonSignIn() async {
    final cur = _auth.currentUser;
    if (cur != null) return cur;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  static Future<void> _ensureUserDoc(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;

    final rng = Random();
    final guestSuffix = rng.nextInt(9000) + 1000;
    await ref.set({
      'displayName': 'Guest$guestSuffix',
      'ratings': {
        'overall': 1200,
        'general': 1200,
        'science': 1200,
        'history': 1200,
        'geography': 1200,
        'sports': 1200,
        'movies': 1200,
        'music': 1200,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>> bootstrap() async {
    final user = await requireAnonSignIn();
    await _ensureUserDoc(user.uid);
    final doc = await _db.collection('users').doc(user.uid).get();
    return {
      'uid': user.uid,
      'displayName': doc.data()?['displayName'] ?? 'Guest',
      'ratings': Map<String, dynamic>.from(doc.data()?['ratings'] ?? {}),
    };
  }

  static Future<void> setDisplayName(String name) async {
    final uid = (_auth.currentUser ?? await requireAnonSignIn()).uid;
    await _db.collection('users').doc(uid).update({
      'displayName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<Map<String, dynamic>> userStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Caller should call bootstrap() first.
      return const Stream.empty();
    }
    return _db.collection('users').doc(uid).snapshots().map((d) {
      return {
        'displayName': d.data()?['displayName'] ?? 'Guest',
        'ratings': Map<String, dynamic>.from(d.data()?['ratings'] ?? {}),
      };
    });
  }
}
