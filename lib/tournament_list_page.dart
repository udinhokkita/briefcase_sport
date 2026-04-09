import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_tournament_page.dart';
import 'single_elimination_page.dart';
import 'double_elimination_page.dart';
import 'mpl_bracket_page.dart';
import 'apply_admin_page.dart';

import 'profile_page.dart';
import 'notification_page.dart';
import 'search_user_page.dart'; // 🔥 TAMBAH

class TournamentListPage extends StatefulWidget {
  final bool isAdmin;

  const TournamentListPage({super.key, required this.isAdmin});

  @override
  State<TournamentListPage> createState() =>
      _TournamentListPageState();
}

class _TournamentListPageState
    extends State<TournamentListPage> {

  String selectedTab = "ongoing";

  Future<void> handleCreate(BuildContext context, String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final role = userDoc.data()?['role'] ?? 'user';

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
                        onPressed: () =>
                            Navigator.pop(context),
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
                              builder: (_) =>
                              const ApplyAdminPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          "Jadi Admin 🔥",
                          style: TextStyle(
                              color: Colors.black),
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const CreateTournamentPage(),
      ),
    );
  }

  Widget buildTab(String title, String value) {
    final isSelected = selectedTab == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = value;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color:
              isSelected ? Colors.cyan : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 60,
            color: isSelected
                ? Colors.cyan
                : Colors.transparent,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // 🔥 HEADER (SEARCH ADDED)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: const [
                      Icon(Icons.work_outline,
                          color: Colors.black),
                      SizedBox(width: 10),
                      Text(
                        "Briefcase",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [

                      // 🔍 SEARCH
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const SearchUserPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.search),
                      ),

                      // 🔔 NOTIFICATION
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const NotificationPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                            Icons.notifications_none),
                      ),

                      // 👤 PROFILE
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProfilePage(
                                    userId: uid,
                                    currentUserId: uid,
                                  ),
                            ),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 15,
                          backgroundColor:
                          Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // TABS
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: [
                buildTab("Ongoing", "ongoing"),
                buildTab("Upcoming", "upcoming"),
                buildTab("Complete", "completed"),
              ],
            ),

            const SizedBox(height: 10),

            // CREATE BUTTON
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      handleCreate(context, uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                      "Create Tournament 🏆"),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tournaments')
                    .where('uid', isEqualTo: uid)
                    .orderBy('createdAt',
                    descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                        child:
                        CircularProgressIndicator());
                  }

                  final allDocs =
                      snapshot.data!.docs;

                  final docs = allDocs.where((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;
                    final status =
                        data['status'] ?? 'ongoing';
                    return status == selectedTab;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tournaments",
                        style: TextStyle(
                            color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                    const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder:
                        (context, index) {

                      final data =
                      docs[index].data()
                      as Map<String, dynamic>;

                      final id = docs[index].id;
                      final name =
                          data['name'] ?? '';
                      final game =
                          data['game'] ??
                              'Custom Game';
                      final count =
                          data['participantsCount'] ??
                              0;
                      final fee =
                          data['fee'] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) {

                                if (data[
                                'bracketType'] ==
                                    'mpl') {
                                  return MplBracketPage(
                                    tournamentId: id,
                                    tournamentName:
                                    name,
                                  );
                                }

                                if (data[
                                'bracketType'] ==
                                    'double') {
                                  return DoubleEliminationPage(
                                    tournamentId: id,
                                    tournamentName:
                                    name,
                                  );
                                }

                                return SingleEliminationPage(
                                  tournamentId: id,
                                  tournamentName:
                                  name,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          margin:
                          const EdgeInsets.only(
                              bottom: 12),
                          padding:
                          const EdgeInsets.all(
                              16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(
                                15),
                            border: Border.all(
                                color: Colors.grey
                                    .shade300),
                          ),
                          child: Row(
                            children: [

                              const CircleAvatar(
                                radius: 10,
                                backgroundColor:
                                Colors.purpleAccent,
                              ),

                              const SizedBox(
                                  width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(name,
                                        style:
                                        const TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .bold)),
                                    Text(game),
                                    Text(
                                        "$count participants"),
                                  ],
                                ),
                              ),

                              Text(
                                "RM $fee",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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