import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';

class SearchUserPage extends StatefulWidget {
  const SearchUserPage({super.key});

  @override
  State<SearchUserPage> createState() => _SearchUserPageState();
}

class _SearchUserPageState extends State<SearchUserPage> {
  String searchText = "";
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F1F),
      appBar: AppBar(
        title: const Text("Search User"),
        backgroundColor: const Color(0xFF070F1F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  searchText = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search user...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon:
                const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF0B1220),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                  const BorderSide(color: Color(0xFF1F2937)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide:
                  const BorderSide(color: Color(0xFF1F2937)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ❌ KOSONG SEBELUM SEARCH
            if (searchText.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    "Start typing to search 🔍",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )

            // ✅ ADA SEARCH
            else
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs.where((doc) {
                      final name =
                      (doc['name'] ?? "").toString().toLowerCase();
                      return name.contains(searchText);
                    }).toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          "No user found ❌",
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userId = user.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1220),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: const Color(0xFF1F2937)),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.person,
                                  color: Colors.white),
                            ),
                            title: Text(
                              user['name'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // ❌ EMAIL DAH BUANG

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(
                                    userId: userId,
                                    currentUserId: currentUserId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}