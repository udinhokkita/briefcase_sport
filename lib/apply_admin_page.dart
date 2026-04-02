import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplyAdminPage extends StatefulWidget {
  const ApplyAdminPage({super.key});

  @override
  State<ApplyAdminPage> createState() => _ApplyAdminPageState();
}

class _ApplyAdminPageState extends State<ApplyAdminPage> {
  final codeController = TextEditingController();

  final String ADMIN_CODE = "ADMIN123";
  bool isLoading = false;

  Future<void> applyAdmin() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final code = codeController.text.trim();

    setState(() => isLoading = true);

    if (code == ADMIN_CODE) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'role': 'admin'});

      showMsg("🔥 Anda sekarang Admin!");
      Navigator.pop(context);
    } else {
      showMsg("❌ Code salah!");
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jadi Admin")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: codeController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: applyAdmin,
              child: const Text("Confirm"),
            )
          ],
        ),
      ),
    );
  }
}