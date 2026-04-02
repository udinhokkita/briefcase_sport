class TournamentModel {
  final String id;
  final String name;
  final String game;
  final List<String> participants;
  final DateTime createdAt;

  TournamentModel({
    required this.id,
    required this.name,
    required this.game,
    required this.participants,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'game': game,
      'participants': participants,
      'participantsCount': participants.length,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TournamentModel.fromMap(String id, Map<String, dynamic> map) {
    return TournamentModel(
      id: id,
      name: map['name'] ?? '',
      game: map['game'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}