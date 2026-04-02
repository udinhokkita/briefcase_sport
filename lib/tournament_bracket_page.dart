import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'tournament_service.dart';

class TournamentBracketPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;

  TournamentBracketPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  final TournamentService service = TournamentService();

  void chooseWinner(
      BuildContext context,
      String matchId,
      String player1,
      String player2,
      ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Select Winner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(player1),
                onTap: () async {
                  await service.updateMatchWinner(
                    tournamentId: tournamentId,
                    matchId: matchId,
                    winner: player1,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(player2),
                onTap: () async {
                  await service.updateMatchWinner(
                    tournamentId: tournamentId,
                    matchId: matchId,
                    winner: player2,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No matches found'));
          }

          docs.sort((a, b) {
            final aData = a.data();
            final bData = b.data();

            final roundCompare =
            (aData['round'] ?? 0).compareTo(bData['round'] ?? 0);

            if (roundCompare != 0) return roundCompare;

            return (aData['matchNumber'] ?? 0)
                .compareTo(bData['matchNumber'] ?? 0);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final round = data['round'] ?? 1;
              final matchNumber = data['matchNumber'] ?? 1;
              final player1 = data['player1'] ?? '';
              final player2 = data['player2'] ?? '';
              final winner = data['winner'] ?? '';
              final status = data['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('Round $round - Match $matchNumber'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('$player1 vs $player2'),
                      const SizedBox(height: 6),
                      Text('Winner: ${winner.isEmpty ? '-' : winner}'),
                      Text('Status: $status'),
                    ],
                  ),
                  trailing: status == 'completed'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : IconButton(
                    icon: const Icon(Icons.emoji_events),
                    onPressed: () {
                      chooseWinner(
                        context,
                        doc.id,
                        player1,
                        player2,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}