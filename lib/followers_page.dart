import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 penting
import 'profile_page.dart';

class FollowersPage extends StatelessWidget {
  final String userId;

  const FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid; // 🔥 FIX

    return Scaffold(
      backgroundColor: const Color(0xFF070F1F),
      appBar: AppBar(
        title: const Text("Followers"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('follows')
            .where('followingId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final followerId = docs[index]['followerId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followerId)
                    .get(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();

                  final user =
                  snap.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['photoUrl'] != null
                          ? NetworkImage(user['photoUrl'])
                          : null,
                      child: user['photoUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user['name'] ?? '',
                        style: const TextStyle(color: Colors.white)),

                    // 🔥 FIX SINI
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            userId: followerId, // profile target
                            currentUserId:
                            currentUserId, // 🔥 user login sebenar
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}