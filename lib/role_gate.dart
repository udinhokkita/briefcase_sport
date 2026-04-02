import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'onboarding_page.dart';
import 'user_navigation.dart';
import 'admin_navigation.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  Future<Widget> getPage() async {
    final user = FirebaseAuth.instance.currentUser;

    // 🔒 kalau user null (safety)
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User tidak login")),
      );
    }

    final uid = user.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // 🔥 kalau doc tak wujud (fallback)
      if (!doc.exists) {
        return const UserNavigation();
      }

      final data = doc.data() as Map<String, dynamic>;

      final role = data['role'] ?? 'user';
      final onboardingDone = data['onboardingDone'] ?? false;

      // 🔥 FIRST TIME USER → ONBOARDING
      if (!onboardingDone) {
        return const OnboardingPage();
      }

      // 🔥 CHECK ROLE
      if (role == 'admin') {
        return const AdminNavigation();
      } else {
        return const UserNavigation();
      }
    } catch (e) {
      return const Scaffold(
        body: Center(child: Text("Error loading user")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getPage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF070F1F),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text("No data")),
          );
        }

        return snapshot.data as Widget;
      },
    );
  }
}