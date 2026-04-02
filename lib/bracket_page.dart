import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament_service.dart';

class BracketPage extends StatelessWidget {
  final String tournamentId;
  final Map<String, dynamic> data;

  const BracketPage({
    super.key,
    required this.tournamentId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? "Single Elimination";

    return Scaffold(
      backgroundColor: const Color(0xFF070F1F),
      appBar: AppBar(
        title: Text(data['name'] ?? ''),
        backgroundColor: Colors.transparent,
      ),
      body: type == "Single Elimination"
          ? SingleEliminationBracket(
        tournamentId: tournamentId,
        isLoser: false,
      )
          : DoubleEliminationBracket(tournamentId: tournamentId),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 DOUBLE ELIMINATION
////////////////////////////////////////////////////////////

class DoubleEliminationBracket extends StatelessWidget {
  final String tournamentId;

  const DoubleEliminationBracket({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Winner Bracket",
            style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: SingleEliminationBracket(
            tournamentId: tournamentId,
            isLoser: false,
          ),
        ),

        const Divider(color: Colors.white24),

        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Loser Bracket",
            style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: SingleEliminationBracket(
            tournamentId: tournamentId,
            isLoser: true,
          ),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 SINGLE ELIMINATION CORE
////////////////////////////////////////////////////////////

class SingleEliminationBracket extends StatelessWidget {
  final String tournamentId;
  final bool isLoser;

  const SingleEliminationBracket({
    super.key,
    required this.tournamentId,
    required this.isLoser,
  });

  static const double cardWidth = 250;
  static const double cardHeight = 140;
  static const double columnWidth = 360;
  static const double verticalGap = 30;
  static const double titleSpace = 60;

  @override
  Widget build(BuildContext context) {
    final service = TournamentService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.getMatches(tournamentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = snapshot.data!.docs.where((doc) {
          final bracket = doc['bracket'] ?? 'winner';
          return isLoser ? bracket == 'loser' : bracket == 'winner';
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
              child: Text("No matches",
                  style: TextStyle(color: Colors.white)));
        }

        final matchesByRound =
        <int, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

        for (final doc in filtered) {
          final round = (doc['round'] ?? 1) as int;
          matchesByRound.putIfAbsent(round, () => []).add(doc);
        }

        final rounds = matchesByRound.keys.toList()..sort();

        final positions = <int, List<double>>{};
        double canvasHeight = 0;

        for (int i = 0; i < rounds.length; i++) {
          final round = rounds[i];
          final matches = matchesByRound[round]!;

          if (i == 0) {
            positions[round] = List.generate(
                matches.length,
                    (index) => index * (cardHeight + verticalGap));
          } else {
            final prev = positions[rounds[i - 1]]!;
            final list = <double>[];

            for (int j = 0; j < matches.length; j++) {
              final y1 = prev[j * 2] + cardHeight / 2;
              final y2 = prev[j * 2 + 1] + cardHeight / 2;
              list.add((y1 + y2) / 2 - cardHeight / 2);
            }

            positions[round] = list;
          }

          canvasHeight =
              positions[round]!.last + cardHeight + 120;
        }

        final canvasWidth = rounds.length * columnWidth + 100;

        return InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 2,
          child: SizedBox(
            width: canvasWidth,
            height: canvasHeight,
            child: Stack(
              children: [

                /// 🔥 DRAW LINES
                CustomPaint(
                  size: Size(canvasWidth, canvasHeight),
                  painter: BracketPainter(
                    rounds,
                    positions,
                    columnWidth,
                    cardWidth,
                    cardHeight,
                    titleSpace,
                  ),
                ),

                /// 🔥 DRAW CARDS
                for (int i = 0; i < rounds.length; i++) ...[
                  Positioned(
                    left: i * columnWidth,
                    top: 10,
                    child: Text(
                      "Round ${i + 1}",
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  ...List.generate(
                    matchesByRound[rounds[i]]!.length,
                        (index) {
                      final doc =
                      matchesByRound[rounds[i]]![index];

                      return Positioned(
                        left: i * columnWidth,
                        top: positions[rounds[i]]![index] +
                            titleSpace,
                        child: MatchCard(
                          doc: doc,
                          tournamentId: tournamentId,
                        ),
                      );
                    },
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 MATCH CARD
////////////////////////////////////////////////////////////

class MatchCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String tournamentId;

  const MatchCard({
    super.key,
    required this.doc,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    final service = TournamentService();
    final data = doc.data();

    final p1 = data['player1'] ?? '';
    final p2 = data['player2'] ?? '';
    final winner = data['winner'] ?? '';

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111C44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [

          _player(p1, winner == p1),
          const SizedBox(height: 6),
          _player(p2, winner == p2),

          const SizedBox(height: 8),

          IconButton(
            icon: const Icon(Icons.emoji_events,
                color: Colors.orange),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF111C44),
                  title: const Text("Select Winner",
                      style: TextStyle(color: Colors.white)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(p1,
                            style:
                            const TextStyle(color: Colors.white)),
                        onTap: () {
                          service.updateMatchWinner(
                              tournamentId: tournamentId,
                              matchId: doc.id,
                              winner: p1);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: Text(p2,
                            style:
                            const TextStyle(color: Colors.white)),
                        onTap: () {
                          service.updateMatchWinner(
                              tournamentId: tournamentId,
                              matchId: doc.id,
                              winner: p2);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _player(String name, bool win) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: win ? Colors.green : Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name.isEmpty ? "TBD" : name,
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                win ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (win)
            const Icon(Icons.check, color: Colors.white),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 LINE DRAW
////////////////////////////////////////////////////////////

class BracketPainter extends CustomPainter {
  final List<int> rounds;
  final Map<int, List<double>> pos;
  final double colWidth;
  final double cardWidth;
  final double cardHeight;
  final double titleSpace;

  BracketPainter(this.rounds, this.pos, this.colWidth,
      this.cardWidth, this.cardHeight, this.titleSpace);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    for (int i = 0; i < rounds.length - 1; i++) {
      final current = pos[rounds[i]]!;
      final next = pos[rounds[i + 1]]!;

      for (int j = 0; j < current.length; j += 2) {
        final x1 = i * colWidth + cardWidth;
        final x2 = (i + 1) * colWidth;

        final y1 = current[j] + titleSpace + cardHeight / 2;
        final y2 = current[j + 1] + titleSpace + cardHeight / 2;
        final yMid = (y1 + y2) / 2;

        final yNext =
            next[j ~/ 2] + titleSpace + cardHeight / 2;

        canvas.drawLine(Offset(x1, y1), Offset(x1 + 30, y1), paint);
        canvas.drawLine(Offset(x1, y2), Offset(x1 + 30, y2), paint);
        canvas.drawLine(
            Offset(x1 + 30, y1), Offset(x1 + 30, y2), paint);
        canvas.drawLine(
            Offset(x1 + 30, yMid), Offset(x2, yMid), paint);
        canvas.drawLine(
            Offset(x2, yMid), Offset(x2, yNext), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}