class MatchModel {
  final String id;
  final int round;
  final int matchNumber;
  final String player1;
  final String player2;
  final String winner;
  final String status;
  final String bracket;

  MatchModel({
    this.id = '',
    required this.round,
    required this.matchNumber,
    required this.player1,
    required this.player2,
    required this.winner,
    required this.status,
    required this.bracket,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map, String id) {
    return MatchModel(
      id: id,
      round: map['round'] ?? 1,
      matchNumber: map['matchNumber'] ?? 1,
      player1: map['player1'] ?? '',
      player2: map['player2'] ?? '',
      winner: map['winner'] ?? '',
      status: map['status'] ?? 'pending',
      bracket: map['bracket'] ?? 'WB',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'round': round,
      'matchNumber': matchNumber,
      'player1': player1,
      'player2': player2,
      'winner': winner,
      'status': status,
      'bracket': bracket,
    };
  }
}