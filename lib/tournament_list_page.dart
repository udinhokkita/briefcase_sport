import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_tournament_page.dart';
import 'single_elimination_page.dart';
import 'double_elimination_page.dart'; // pastikan ada
import 'mpl_bracket_page.dart'; // 🔥 tambah ini
import 'apply_admin_page.dart';

class TournamentListPage extends StatelessWidget {
  final bool isAdmin;

  const TournamentListPage({super.key, required this.isAdmin});

  Future<void> handleCreate(BuildContext context, String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final role = userDoc.data()?['role'] ?? 'user';

    // ❌ NOT ADMIN → POPUP
    if (role != 'admin') {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFF0B1220),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Admin Required",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Untuk create tournament, anda perlu jadi admin dahulu.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ApplyAdminPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          "Jadi Admin 🔥",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
      return;
    }

    // ✅ ADMIN → CREATE PAGE
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTournamentPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tournaments')
              .where('uid', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {

            // ================= LOADING =================
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final hasData =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            // ================= EMPTY UI =================
            if (!hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "BRACKETS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "No tournaments",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Let's create the first tournament",
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 30),

                    // 🔥 BUTTON CENTER
                    SizedBox(
                      width: 220,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => handleCreate(context, uid),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "CREATE NEW",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // ================= ADA DATA =================
            final docs = snapshot.data!.docs;

            return Column(
              children: [
                // 🔥 BUTTON ATAS
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => handleCreate(context, uid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Create Tournament 🏆"),
                    ),
                  ),
                ),

                // 🔥 LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final data =
                      docs[index].data() as Map<String, dynamic>;

                      final id = docs[index].id;
                      final name = data['name'] ?? '';
                      final game = data['game'] ?? '';
                      final count =
                          data['participantsCount'] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) {
                                // 🔥 ADD MPL SUPPORT (SAHAJA TAMBAH)
                                if (data['bracketType'] == 'mpl') {
                                  return MplBracketPage(
                                    tournamentId: id,
                                    tournamentName: name,
                                  );
                                }

                                if (data['bracketType'] == 'double') {
                                  return DoubleEliminationPage(
                                    tournamentId: id,
                                    tournamentName: name,
                                  );
                                }

                                return SingleEliminationPage(
                                  tournamentId: id,
                                  tournamentName: name,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1220),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: const Color(0xFF1F2937)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Colors.orange),
                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.bold)),
                                    Text(game,
                                        style: const TextStyle(
                                            color:
                                            Colors.white54)),
                                    Text("$count participants",
                                        style: const TextStyle(
                                            color:
                                            Colors.white38)),
                                  ],
                                ),
                              ),

                              const Icon(Icons.more_vert,
                                  color: Colors.white54),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}