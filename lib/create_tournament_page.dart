import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTournamentPage extends StatefulWidget {
  const CreateTournamentPage({super.key});

  @override
  State<CreateTournamentPage> createState() =>
      _CreateTournamentPageState();
}

class _CreateTournamentPageState
    extends State<CreateTournamentPage> {
  final TextEditingController nameController =
  TextEditingController();

  int teamCount = 4;
  String bracketType = "single";

  List<TextEditingController> teamControllers = [];

  @override
  void initState() {
    super.initState();
    generateTeams();
  }

  void generateTeams() {
    teamControllers =
        List.generate(teamCount, (i) => TextEditingController());
  }

  void shuffleTeams() {
    final names =
    teamControllers.map((e) => e.text).toList();

    names.shuffle(Random());

    for (int i = 0; i < teamControllers.length; i++) {
      teamControllers[i].text = names[i];
    }

    setState(() {});
  }

  void clearAll() {
    nameController.clear();
    for (var c in teamControllers) {
      c.clear();
    }
  }

  // ================= SAVE =================
  Future<void> saveTournament() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMsg("User not logged in");
        return;
      }

      final name = nameController.text.trim();

      if (name.isEmpty) {
        showMsg("Enter tournament name");
        return;
      }

      List<String> players =
      teamControllers.map((e) => e.text.trim()).toList();

      if (players.any((e) => e.isEmpty)) {
        showMsg("Fill all team names");
        return;
      }

      // ADD BYE
      while ((players.length & (players.length - 1)) != 0) {
        players.add("BYE");
      }

      players.shuffle();

      final docRef = FirebaseFirestore.instance
          .collection('tournaments')
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      // SAVE TOURNAMENT
      batch.set(docRef, {
        'uid': user.uid,
        'name': name,
        'game': "Custom Game",
        'players': players,
        'participantsCount': players.length,
        'bracketType': bracketType, // 🔥 support mpl
        'createdAt': FieldValue.serverTimestamp(),
      });

      int totalRounds =
      (log(players.length) / log(2)).ceil();

      int matchNumber = 1;

      // ===== UPPER =====
      for (int i = 0; i < players.length; i += 2) {
        final matchRef =
        docRef.collection('matches').doc();

        batch.set(matchRef, {
          'round': 1,
          'matchNumber': matchNumber++,
          'player1': players[i],
          'player2': players[i + 1],
          'winner': '',
          'status': 'pending',
          'bracket': 'upper',
        });
      }

      int matchesInRound = players.length ~/ 2;

      for (int r = 2; r <= totalRounds; r++) {
        matchesInRound = matchesInRound ~/ 2;

        for (int i = 0; i < matchesInRound; i++) {
          final matchRef =
          docRef.collection('matches').doc();

          batch.set(matchRef, {
            'round': r,
            'matchNumber': matchNumber++,
            'player1': '',
            'player2': '',
            'winner': '',
            'status': 'pending',
            'bracket': 'upper',
          });
        }
      }

      // ===== LOWER (DOUBLE + MPL) =====
      if (bracketType == "double" || bracketType == "mpl") {
        int loserRounds = totalRounds - 1;

        for (int r = 1; r <= loserRounds; r++) {
          int matchCount =
          pow(2, loserRounds - r).toInt();

          for (int i = 0; i < matchCount; i++) {
            final matchRef =
            docRef.collection('matches').doc();

            batch.set(matchRef, {
              'round': r,
              'matchNumber': matchNumber++,
              'player1': '',
              'player2': '',
              'winner': '',
              'status': 'pending',
              'bracket': 'lower',
            });
          }
        }
      }

      await batch.commit();

      showMsg("Tournament Created ✅");

      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pop(context);
    } catch (e) {
      showMsg("Error: $e");
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI (UNCHANGED) =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // TITLE
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "ADD BRACKET",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // NAME
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "My Tournament",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TEAM COUNT
            const Text(
              "Number of teams",
              style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 15,
                itemBuilder: (context, index) {
                  int num = index + 2;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        teamCount = num;
                        generateTeams();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 60,
                      decoration: BoxDecoration(
                        color: teamCount == num
                            ? Colors.deepPurple
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "$num",
                          style: TextStyle(
                            fontSize: 20,
                            color: teamCount == num
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // TYPE (ADD MPL TANPA UBAH DESIGN)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      bracketType = "single";
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bracketType == "single"
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                  ),
                  child: const Text("Single"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      bracketType = "double";
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bracketType == "double"
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                  ),
                  child: const Text("Double"),
                ),
                const SizedBox(width: 10),

                // 🔥 MPL BUTTON (TAMBAH SAHAJA)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      bracketType = "mpl";
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bracketType == "mpl"
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                  ),
                  child: const Text("MPL"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // SEEDS
            Expanded(
              child: ListView.builder(
                itemCount: teamCount ~/ 2,
                itemBuilder: (context, i) {
                  int left = i;
                  int right = teamCount - 1 - i;

                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: teamControllers[left],
                            decoration: InputDecoration(
                              hintText: "Team ${left + 1}",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("VS"),
                        ),
                        Expanded(
                          child: TextField(
                            controller: teamControllers[right],
                            decoration: InputDecoration(
                              hintText: "Team ${right + 1}",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // BUTTONS
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  iconBtn(Icons.arrow_back, () {
                    Navigator.pop(context);
                  }),
                  iconBtn(Icons.close, clearAll),
                  iconBtn(Icons.shuffle, shuffleTeams),
                  iconBtn(Icons.remove_red_eye, () {
                    showMsg("Preview Coming Soon 👀");
                  }),
                  FloatingActionButton(
                    backgroundColor: Colors.deepPurple,
                    onPressed: saveTournament,
                    child: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.amber,
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}