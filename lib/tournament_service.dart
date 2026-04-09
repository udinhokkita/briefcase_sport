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

    List<String> players = participants
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (players.length < 2) {
      players.add("BYE");
    }

    while (!_isPowerOfTwo(players.length)) {
      players.add("BYE");
    }

    players.shuffle();

    List<Map<String, dynamic>> matches;

    if (bracketType == "single") {
      matches = _generateSingle(players);
    } else {
      matches = _generateDouble(players);
    }

    final batch = _firestore.batch();

    batch.set(tournamentRef, {
      'name': name,
      'game': game,
      'participants': players,
      'participantsCount': players.length,
      'bracketType': bracketType,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),

      // 🔥 STATUS + TIME SYSTEM
      'status': 'upcoming',
      'startDate': Timestamp.now()
          .toDate()
          .add(const Duration(minutes: 5)), // 🔥 FIX buffer
    });

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

    // 🔥 SAFE TRIGGER (elak timing bug)
    Future.microtask(() {
      autoUpdateStatusByTime(tournamentId);
    });

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

    final matchesRef = _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches');

    final currentDoc = await matchesRef.doc(matchId).get();
    final currentData = currentDoc.data();

    if (currentData == null) return;

    final currentRound = currentData['round'];

    // UPDATE CURRENT
    await currentDoc.reference.update({
      'winner': winner,
      'status': 'completed',
    });

    // AUTO MOVE NEXT ROUND
    final currentRoundQuery = await matchesRef
        .where('round', isEqualTo: currentRound)
        .orderBy('matchNumber')
        .get();

    final currentMatches = currentRoundQuery.docs;

    final index = currentMatches.indexWhere((doc) => doc.id == matchId);

    if (index != -1) {
      final nextRound = currentRound + 1;

      final nextRoundQuery = await matchesRef
          .where('round', isEqualTo: nextRound)
          .orderBy('matchNumber')
          .get();

      final nextMatches = nextRoundQuery.docs;

      if (nextMatches.isNotEmpty) {
        final nextMatchIndex = index ~/ 2;

        if (nextMatchIndex < nextMatches.length) {
          final nextMatch = nextMatches[nextMatchIndex];
          final nextData = nextMatch.data();

          if ((nextData['player1'] ?? '').isEmpty) {
            await nextMatch.reference.update({
              'player1': winner,
            });
          } else {
            await nextMatch.reference.update({
              'player2': winner,
            });
          }
        }
      }
    }

    // AUTO STATUS
    final allMatches = await matchesRef.get();

    bool allCompleted = true;
    bool anyCompleted = false;

    for (var doc in allMatches.docs) {
      final status = doc['status'];

      if (status != 'completed') {
        allCompleted = false;
      } else {
        anyCompleted = true;
      }
    }

    String newStatus;

    if (allCompleted) {
      newStatus = "completed";
    } else if (anyCompleted) {
      newStatus = "ongoing";
    } else {
      newStatus = "upcoming";
    }

    await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .update({
      'status': newStatus,
    });
  }

  // ================= AUTO TIME SYSTEM =================
  Future<void> autoUpdateStatusByTime(String tournamentId) async {
    final doc = await _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .get();

    final data = doc.data();
    if (data == null) return;

    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    if (startDate == null) return;

    final now = DateTime.now();

    final diff = startDate.difference(now).inSeconds;

    // 🔥 FIX UPCOMING BUG
    if (diff > 10) {
      await doc.reference.update({'status': 'upcoming'});
    } else {
      final matches = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .get();

      bool allCompleted = true;

      for (var m in matches.docs) {
        if (m['status'] != 'completed') {
          allCompleted = false;
          break;
        }
      }

      if (allCompleted) {
        await doc.reference.update({'status': 'completed'});
      } else {
        await doc.reference.update({'status': 'ongoing'});
      }
    }
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

    int lowerMatches = max(1, players.length ~/ 2);

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
    if (n <= 0) return false;
    return (n & (n - 1)) == 0;
  }
}