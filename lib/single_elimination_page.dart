import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'tournament_service.dart';

class SingleEliminationPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;

  const SingleEliminationPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  static const double cardWidth = 240;
  static const double estimatedCardHeight = 130;
  static const double verticalGap = 28;
  static const double columnWidth = 340;
  static const double titleSpace = 48;

  @override
  Widget build(BuildContext context) {
    final TournamentService service = TournamentService();

    return Scaffold(
      appBar: AppBar(
        title: Text(tournamentName),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.getMatches(tournamentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No bracket found'),
            );
          }

          final matchesByRound =
          <int, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

          for (final doc in docs) {
            final data = doc.data();
            final round = (data['round'] ?? 1) as int;
            matchesByRound.putIfAbsent(round, () => []).add(doc);
          }

          final roundNumbers = matchesByRound.keys.toList()..sort();

          for (final round in roundNumbers) {
            matchesByRound[round]!.sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              return (aData['matchNumber'] ?? 0)
                  .compareTo(bData['matchNumber'] ?? 0);
            });
          }

          final topPositionsByRound = <int, List<double>>{};
          double totalCanvasHeight = 0;

          for (int i = 0; i < roundNumbers.length; i++) {
            final round = roundNumbers[i];
            final matches = matchesByRound[round]!;

            if (i == 0) {
              final positions = <double>[];
              for (int index = 0; index < matches.length; index++) {
                positions.add(index * (estimatedCardHeight + verticalGap));
              }
              topPositionsByRound[round] = positions;
            } else {
              final prevRound = roundNumbers[i - 1];
              final prevPositions = topPositionsByRound[prevRound]!;
              final positions = <double>[];

              for (int index = 0; index < matches.length; index++) {
                final firstPrev = index * 2;
                final secondPrev = firstPrev + 1;

                if (secondPrev < prevPositions.length) {
                  final prevCenter1 =
                      prevPositions[firstPrev] + (estimatedCardHeight / 2);
                  final prevCenter2 =
                      prevPositions[secondPrev] + (estimatedCardHeight / 2);
                  final center = (prevCenter1 + prevCenter2) / 2;
                  positions.add(center - (estimatedCardHeight / 2));
                } else if (firstPrev < prevPositions.length) {
                  positions.add(prevPositions[firstPrev]);
                } else {
                  positions.add(0);
                }
              }

              topPositionsByRound[round] = positions;
            }

            final roundPositions = topPositionsByRound[round]!;
            if (roundPositions.isNotEmpty) {
              final maxBottom =
                  roundPositions.last + estimatedCardHeight + titleSpace + 60;
              if (maxBottom > totalCanvasHeight) {
                totalCanvasHeight = maxBottom;
              }
            }
          }

          final totalCanvasWidth = (roundNumbers.length * columnWidth) + 80;

          return ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
              },
            ),
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 2.0,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: totalCanvasWidth,
                height: totalCanvasHeight,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(totalCanvasWidth, totalCanvasHeight),
                      painter: BracketLinesPainter(
                        roundNumbers: roundNumbers,
                        topPositionsByRound: topPositionsByRound,
                        columnWidth: columnWidth,
                        cardWidth: cardWidth,
                        cardHeight: estimatedCardHeight,
                        titleSpace: titleSpace,
                      ),
                    ),
                    for (int i = 0; i < roundNumbers.length; i++) ...[
                      Positioned(
                        left: i * columnWidth,
                        top: 0,
                        child: Text(
                          _getRoundTitle(roundNumbers[i], roundNumbers.length),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...List.generate(
                        matchesByRound[roundNumbers[i]]!.length,
                            (index) {
                          final doc = matchesByRound[roundNumbers[i]]![index];
                          final top = topPositionsByRound[roundNumbers[i]]![index];

                          return Positioned(
                            left: i * columnWidth,
                            top: top + titleSpace,
                            child: MatchCard(
                              doc: doc,
                              tournamentId: tournamentId,
                              width: cardWidth,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getRoundTitle(int round, int totalRounds) {
    if (totalRounds == 1) return 'Final';
    if (round == totalRounds) return 'Final';
    if (round == totalRounds - 1) return 'Semi Final';
    return 'Round $round';
  }
}

class MatchCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String tournamentId;
  final double width;

  const MatchCard({
    super.key,
    required this.doc,
    required this.tournamentId,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final TournamentService service = TournamentService();
    final data = doc.data();

    final matchNumber = data['matchNumber'] ?? 1;
    final player1 = data['player1'] ?? '';
    final player2 = data['player2'] ?? '';
    final winner = data['winner'] ?? '';
    final status = data['status'] ?? 'pending';

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Match $matchNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                _playerRow(
                  name: player1,
                  isWinner: winner == player1 && winner.isNotEmpty,
                ),
                const SizedBox(height: 8),
                _playerRow(
                  name: player2,
                  isWinner: winner == player2 && winner.isNotEmpty,
                ),
              ],
            ),
          ),
          Positioned(
            right: -6,
            top: 50,
            child: status == 'completed'
                ? Container(
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 18,
              ),
            )
                : Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.emoji_events,
                  color: Colors.orange,
                  size: 20,
                ),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (player1.isEmpty || player2.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match ini belum lengkap lagi'),
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF111827),
                        title: const Text(
                          'Select Winner',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text(
                                player1,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () async {
                                await service.updateMatchWinner(
                                  tournamentId: tournamentId,
                                  matchId: doc.id,
                                  winner: player1,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            ListTile(
                              title: Text(
                                player2,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () async {
                                await service.updateMatchWinner(
                                  tournamentId: tournamentId,
                                  matchId: doc.id,
                                  winner: player2,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerRow({
    required String name,
    required bool isWinner,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner ? const Color(0xFF14532D) : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWinner ? const Color(0xFF22C55E) : const Color(0xFF374151),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name.isEmpty ? 'TBD' : name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isWinner)
            const Icon(
              Icons.check,
              color: Color(0xFF22C55E),
              size: 18,
            ),
        ],
      ),
    );
  }
}

class BracketLinesPainter extends CustomPainter {
  final List<int> roundNumbers;
  final Map<int, List<double>> topPositionsByRound;
  final double columnWidth;
  final double cardWidth;
  final double cardHeight;
  final double titleSpace;

  const BracketLinesPainter({
    required this.roundNumbers,
    required this.topPositionsByRound,
    required this.columnWidth,
    required this.cardWidth,
    required this.cardHeight,
    required this.titleSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < roundNumbers.length - 1; i++) {
      final currentRound = roundNumbers[i];
      final nextRound = roundNumbers[i + 1];

      final currentPositions = topPositionsByRound[currentRound] ?? [];
      final nextPositions = topPositionsByRound[nextRound] ?? [];

      for (int j = 0; j < currentPositions.length; j += 2) {
        if ((j ~/ 2) >= nextPositions.length) continue;
        if (j + 1 >= currentPositions.length) continue;

        final x1 = (i * columnWidth) + cardWidth;
        final xMid = (i * columnWidth) + cardWidth + 32;
        final x2 = ((i + 1) * columnWidth) - 20;

        final y1 = currentPositions[j] + titleSpace + (cardHeight / 2);
        final y2 = currentPositions[j + 1] + titleSpace + (cardHeight / 2);
        final yMid = (y1 + y2) / 2;
        final yNext = nextPositions[j ~/ 2] + titleSpace + (cardHeight / 2);

        canvas.drawLine(Offset(x1, y1), Offset(xMid, y1), paint);
        canvas.drawLine(Offset(x1, y2), Offset(xMid, y2), paint);
        canvas.drawLine(Offset(xMid, y1), Offset(xMid, y2), paint);
        canvas.drawLine(Offset(xMid, yMid), Offset(x2, yMid), paint);
        canvas.drawLine(Offset(x2, yMid), Offset(x2, yNext), paint);
        canvas.drawLine(
          Offset(x2, yNext),
          Offset((i + 1) * columnWidth, yNext),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}