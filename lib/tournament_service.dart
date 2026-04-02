import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= CREATE =================
  Future<String> createTournament({
    required String name,
    required String game,
    required List<String> participants,
    required String bracketType,
  }) async {
    final tournamentRef = _firestore.collection('tournaments').doc();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // CLEAN DATA
    List<String> players = participants
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // ADD BYE
    while (!_isPowerOfTwo(players.length)) {
      players.add("BYE");
    }

    players.shuffle();

    // SELECT BRACKET
    List<Map<String, dynamic>> matches;

    if (bracketType == "single") {
      matches = _generateSingle(players);
    } else {
      // double + mpl
      matches = _generateDouble(players);
    }

    final batch = _firestore.batch();

    // SAVE TOURNAMENT
    batch.set(tournamentRef, {
      'name': name,
      'game': game,
      'participants': players,
      'participantsCount': players.length,
      'bracketType': bracketType,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // SAVE MATCHES
    for (var m in matches) {
      final ref = tournamentRef.collection('matches').doc();
      batch.set(ref, m);
    }

    await batch.commit();

    return tournamentRef.id;
  }

  // ================= GET MATCHES =================
  Stream<QuerySnapshot<Map<String, dynamic>>> getMatches(
      String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .orderBy('round')
        .snapshots();
  }

  // ================= UPDATE MATCH WINNER =================
  Future<void> updateMatchWinner({
    required String tournamentId,
    required String matchId,
    required String winner,
  }) async {
    await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId)
        .update({
      'winner': winner,
      'status': 'completed',
    });
  }

  // ================= SINGLE =================
  List<Map<String, dynamic>> _generateSingle(List<String> players) {
    List<Map<String, dynamic>> matches = [];

    int round = 1;
    int matchNumber = 1;

    List<String> current = List.from(players);

    while (current.length > 1) {
      List<String> nextRound = [];

      for (int i = 0; i < current.length; i += 2) {
        matches.add({
          'round': round,
          'matchNumber': matchNumber++,
          'player1': current[i],
          'player2': current[i + 1],
          'winner': '',
          'status': 'pending',
          'bracket': 'upper',
        });

        nextRound.add('');
      }

      current = nextRound;
      round++;
    }

    return matches;
  }

  // ================= DOUBLE / MPL =================
  List<Map<String, dynamic>> _generateDouble(List<String> players) {
    List<Map<String, dynamic>> matches = [];

    int matchNumber = 1;

    // ===== UPPER =====
    int round = 1;
    List<String> current = List.from(players);

    while (current.length > 1) {
      List<String> nextRound = [];

      for (int i = 0; i < current.length; i += 2) {
        matches.add({
          'round': round,
          'matchNumber': matchNumber++,
          'player1': current[i],
          'player2': current[i + 1],
          'winner': '',
          'status': 'pending',
          'bracket': 'upper',
        });

        nextRound.add('');
      }

      current = nextRound;
      round++;
    }

    // ===== LOWER =====
    int lowerMatches = players.length ~/ 2;

    for (int i = 0; i < lowerMatches; i++) {
      matches.add({
        'round': 1,
        'matchNumber': matchNumber++,
        'player1': '',
        'player2': '',
        'winner': '',
        'status': 'pending',
        'bracket': 'lower',
      });
    }

    return matches;
  }

  // ================= HELPER =================
  bool _isPowerOfTwo(int n) {
    return (n & (n - 1)) == 0;
  }
}