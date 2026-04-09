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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController gameController = TextEditingController();
  final TextEditingController feeController = TextEditingController();

  int teamCount = 4;
  String bracketType = "single";

  List<TextEditingController> teamControllers = [];

  DateTime? selectedStartTime;
  bool startNow = true;

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
    final names = teamControllers.map((e) => e.text).toList();
    names.shuffle(Random());

    for (int i = 0; i < teamControllers.length; i++) {
      teamControllers[i].text = names[i];
    }

    setState(() {});
  }

  void clearAll() {
    nameController.clear();
    gameController.clear();
    feeController.clear();

    for (var c in teamControllers) {
      c.clear();
    }
  }

  Future<void> pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedStartTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      startNow = false;
    });
  }

  Future<void> saveTournament() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        showMsg("User not logged in");
        return;
      }

      final name = nameController.text.trim();
      final game = gameController.text.trim();
      final feeText = feeController.text.trim();
      final fee = double.tryParse(feeText) ?? 0;

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

      // 🔥 POWER OF 2
      while ((players.length & (players.length - 1)) != 0) {
        players.add("BYE");
      }

      players.shuffle();

      final docRef = FirebaseFirestore.instance
          .collection('tournaments')
          .doc();

      final batch = FirebaseFirestore.instance.batch();

      final startDate = startNow
          ? Timestamp.now()
          : Timestamp.fromDate(selectedStartTime!);

      batch.set(docRef, {
        'uid': user.uid,
        'name': name,
        'game': game,
        'players': players,
        'participantsCount': players.length,
        'bracketType': bracketType,
        'createdAt': FieldValue.serverTimestamp(),
        'fee': fee,
        'status': 'upcoming',
        'startDate': startDate,
      });

      // ================= FIX UTAMA =================
      int totalRounds = (log(players.length) / log(2)).ceil();
      int matchNumber = 1;

      // ROUND 1
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

      // NEXT ROUNDS
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
      // ===========================================

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                  MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [

                    const SizedBox(height: 20),

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

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: "My Tournament",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: gameController,
                        decoration: const InputDecoration(
                          hintText: "Game",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: feeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "RM Fee",
                          prefixText: "RM ",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              startNow = true;
                            });
                          },
                          child: const Text("Start Now"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: pickStartTime,
                          child: const Text("Pick Time"),
                        ),
                      ],
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
                              margin:
                              const EdgeInsets.symmetric(horizontal: 8),
                              width: 60,
                              decoration: BoxDecoration(
                                color: teamCount == num
                                    ? Colors.deepPurple
                                    : Colors.grey.shade200,
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Center(child: Text("$num")),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    ListView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
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
                                  controller:
                                  teamControllers[left],
                                  decoration: InputDecoration(
                                    hintText:
                                    "Team ${left + 1}",
                                    border:
                                    OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding:
                                EdgeInsets.symmetric(horizontal: 10),
                                child: Text("VS"),
                              ),
                              Expanded(
                                child: TextField(
                                  controller:
                                  teamControllers[right],
                                  decoration: InputDecoration(
                                    hintText:
                                    "Team ${right + 1}",
                                    border:
                                    OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  iconBtn(Icons.arrow_back, () {
                    Navigator.pop(context);
                  }),
                  iconBtn(Icons.close, clearAll),
                  iconBtn(Icons.shuffle, shuffleTeams),
                  FloatingActionButton(
                    backgroundColor: Colors.deepPurple,
                    onPressed: saveTournament,
                    child:
                    const Icon(Icons.arrow_forward),
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