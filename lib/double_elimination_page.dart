import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoubleEliminationPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const DoubleEliminationPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<DoubleEliminationPage> createState() => _DoubleEliminationPageState();
}

class _DoubleEliminationPageState extends State<DoubleEliminationPage> {

  List<String> players = [];

  @override
  void initState() {
    super.initState();
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournamentId)
        .collection('players')
        .get();

    setState(() {
      players = snapshot.docs.map((e) => e['name'] as String).toList();
    });
  }

  int get totalRounds {
    if (players.isEmpty) return 0;
    return (log(players.length) / log(2)).ceil();
  }

  List<Widget> buildRounds() {
    List<Widget> columns = [];

    for (int round = 0; round < totalRounds; round++) {
      columns.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: buildMatches(round),
          ),
        ),
      );
    }

    return columns;
  }

  List<Widget> buildMatches(int round) {
    List<Widget> matches = [];

    int matchCount = (players.length / pow(2, round + 1)).ceil();

    for (int i = 0; i < matchCount; i++) {
      matches.add(
        Container(
          margin: EdgeInsets.only(
            top: i == 0 ? 20 : 40 * pow(2, round).toDouble(),
          ),
          width: 140,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Center(
            child: Text(
              getPlayerName(round, i),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return matches;
  }

  String getPlayerName(int round, int index) {
    if (round == 0) {
      int i = index * 2;
      if (i < players.length) return players[i];
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentName),
      ),
      body: players.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buildRounds(),
        ),
      ),
    );
  }
}