import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).get().then((doc) {
      _controller.text = doc.data()?['displayName'] ?? 'Guest';
    });
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();
    final valid = RegExp(r'^[A-Za-z0-9 _-]{2,20}$');
    if (!valid.hasMatch(raw)) {
      setState(() => _error = 'Use 2–20 letters/numbers/spaces/_/-');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'displayName': raw,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Name updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Display Name')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: 'Display Name',
                helperText: '2–20 characters (A–Z, 0–9, space, _ , -)',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            _saving
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
          ],
        ),
      ),
    );
  }
}
