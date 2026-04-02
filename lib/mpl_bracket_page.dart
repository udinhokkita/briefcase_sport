import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MplBracketPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;

  const MplBracketPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(tournamentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .doc(tournamentId)
            .collection('matches')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          final matches = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

          return Stack(
            children: [
              InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(1500),
                minScale: 0.1,
                maxScale: 2.0,
                child: SizedBox(
                  width: 3000, // Lebar besar untuk muat semua round
                  height: 2000,
                  child: Stack(
                    children: [
                      // 1. LUKIS GARISAN PENYAMBUNG
                      CustomPaint(
                        size: const Size(3000, 2000),
                        painter: BracketLinePainter(matches: matches),
                      ),

                      // 2. LUKIS KAD MATCH
                      ...matches.map((data) {
                        final int round = (data['round'] ?? 1) as int;
                        final int matchNum = (data['matchNumber'] ?? 1) as int;

                        // Pengiraan Posisi Dinamik
                        double x = (round - 1) * 320.0 + 80;
                        double initialSpacing = 120.0;
                        double y = (matchNum - 1) * (initialSpacing * (1 << (round - 1)) * 2)
                            + (initialSpacing * (1 << (round - 1))) - 40;

                        return Positioned(
                          left: x,
                          top: y,
                          child: _buildMatchCard(data, round),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Floating Share Button
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text("SHARE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> data, int round) {
    // Round 5 biasanya Final (ikut data anda)
    bool isFinal = round == 5;

    return Row(
      children: [
        Container(
          width: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(4),
            border: isFinal ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
            children: [
              _playerTile(data['player1'] ?? 'TBD', data['score1']?.toString() ?? ''),
              const Divider(height: 1, color: Colors.black),
              _playerTile(data['player2'] ?? 'TBD', data['score2']?.toString() ?? ''),
            ],
          ),
        ),
        if (isFinal) ...[
          const SizedBox(width: 10),
          const Text("🏆", style: TextStyle(fontSize: 24)),
        ]
      ],
    );
  }

  Widget _playerTile(String name, String score) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              name.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Container(
          width: 30,
          height: 35,
          alignment: Alignment.center,
          color: const Color(0xFF333333),
          child: Text(score, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }
}

// --- LOGIK LUKISAN GARISAN MELENGKUNG ---
class BracketLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> matches;
  BracketLinePainter({required this.matches});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var match in matches) {
      final int round = (match['round'] ?? 1) as int;
      final int matchNum = (match['matchNumber'] ?? 1) as int;

      // Hanya lukis garisan jika bukan Final (cth: Round < 5)
      if (round < 5 && matchNum % 2 != 0) {
        double cardWidth = 160;
        double cardHeight = 70;
        double xOffset = 320.0;
        double initialSpacing = 120.0;

        // Koordinat Match Atas
        double startX = (round - 1) * xOffset + 80 + cardWidth;
        double startY = (matchNum - 1) * (initialSpacing * (1 << (round - 1)) * 2)
            + (initialSpacing * (1 << (round - 1)));

        // Koordinat Match Bawah
        double partnerY = startY + (initialSpacing * (1 << (round - 1)) * 2);

        // Titik Pertemuan (Match di Round Seterusnya)
        double endX = startX + (xOffset - cardWidth);
        double endY = (startY + partnerY) / 2;

        var path = Path();

        // Garisan dari Atas ke Tengah
        path.moveTo(startX, startY);
        path.cubicTo(startX + 50, startY, startX + 50, endY, endX, endY);

        // Garisan dari Bawah ke Tengah
        path.moveTo(startX, partnerY);
        path.cubicTo(startX + 50, partnerY, startX + 50, endY, endX, endY);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}