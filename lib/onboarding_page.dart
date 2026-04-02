import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_navigation.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  List<String> selected = [];

  final sports = [
    "Futsal",
    "Badminton",
    "Football",
    "Basketball",
    "Volleyball"
  ];

  void toggle(String s) {
    setState(() {
      selected.contains(s) ? selected.remove(s) : selected.add(s);
    });
  }

  Future<void> save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'favoriteSports': selected,
      'onboardingDone': true,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UserNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Sports")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: sports.map((s) {
                return ListTile(
                  title: Text(s),
                  trailing: selected.contains(s)
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => toggle(s),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: save, child: const Text("Skip")),
              ElevatedButton(onPressed: save, child: const Text("Next")),
            ],
          ),
        ],
      ),
    );
  }
}