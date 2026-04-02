import 'dart:math';
import 'package:flutter/material.dart';

class LinePainter extends CustomPainter {
  final List matches;
  final double startX;
  final double startY;
  final double columnGap;
  final double rowGap;
  final double cardWidth;
  final double cardHeight;

  LinePainter(
      this.matches,
      this.startX,
      this.startY,
      this.columnGap,
      this.rowGap,
      this.cardWidth,
      this.cardHeight,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;

    Map<int, List> grouped = {};

    for (var m in matches) {
      grouped.putIfAbsent(m['round'], () => []).add(m);
    }

    grouped.forEach((round, list) {
      if (!grouped.containsKey(round + 1)) return;

      final nextList = grouped[round + 1]!;

      for (int i = 0; i < list.length; i++) {
        final match = list[i];

        double x1 = startX + (round - 1) * columnGap + cardWidth;
        double y1 =
            startY + i * rowGap * pow(2, round - 1) + cardHeight / 2;

        int parentIndex = i ~/ 2;

        double x2 = startX + round * columnGap;
        double y2 = startY +
            parentIndex * rowGap * pow(2, round) +
            cardHeight / 2;

        double midX = (x1 + x2) / 2;

        // horizontal
        canvas.drawLine(Offset(x1, y1), Offset(midX, y1), paint);

        // vertical
        canvas.drawLine(Offset(midX, y1), Offset(midX, y2), paint);

        // horizontal
        canvas.drawLine(Offset(midX, y2), Offset(x2, y2), paint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}