import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament_service.dart';

class DoubleEliminationPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;

  const DoubleEliminationPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    final TournamentService service = TournamentService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tournamentName),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.getMatches(tournamentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // ================= GROUP =================
          Map<int, List<Map<String, dynamic>>> upperRounds = {};
          Map<int, List<Map<String, dynamic>>> lowerRounds = {};

          for (var doc in docs) {
            final data = doc.data();
            final round = data['round'] ?? 1;
            final bracket = data['bracket'] ?? 'upper';

            if (bracket == 'upper') {
              upperRounds.putIfAbsent(round, () => []);
              upperRounds[round]!.add(data);
            } else {
              lowerRounds.putIfAbsent(round, () => []);
              lowerRounds[round]!.add(data);
            }
          }

          final upperKeys = upperRounds.keys.toList()..sort();
          final lowerKeys = lowerRounds.keys.toList()..sort();

          return InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.5,
            maxScale: 2.5,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [

                    // ================= UPPER =================
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        "UPPER BRACKET",
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: upperKeys.map((round) {
                        final matches = upperRounds[round]!;

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: matches.map((m) {
                              return _card(m);
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 60),

                    // ================= LOWER =================
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        "LOWER BRACKET",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lowerKeys.map((round) {
                        final matches = lowerRounds[round]!;

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: matches.map((m) {
                              return _card(m);
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= CARD (SAME DESIGN) =================
  Widget _card(Map<String, dynamic> match) {
    final p1 = match['player1'] ?? '';
    final p2 = match['player2'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _player(p1),
          const Divider(height: 1, color: Colors.black),
          _player(p2),
        ],
      ),
    );
  }

  Widget _player(String name) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}