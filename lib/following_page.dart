import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 penting
import 'profile_page.dart';

class FollowingPage extends StatelessWidget {
  final String userId;

  const FollowingPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid; // 🔥 FIX

    return Scaffold(
      backgroundColor: const Color(0xFF070F1F),
      appBar: AppBar(
        title: const Text("Following"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('follows')
            .where('followerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final followingId = docs[index]['followingId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followingId)
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
                            userId: followingId,
                            currentUserId: currentUserId,
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