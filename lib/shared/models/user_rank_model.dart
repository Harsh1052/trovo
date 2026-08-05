import 'package:equatable/equatable.dart';

/// Represents a Hunter's overall XP rank and badges.
class UserRankModel extends Equatable {
  const UserRankModel({
    required this.userId,
    required this.totalXp,
    required this.huntsCompleted,
    required this.guardianshipsHeld,
  });

  final String userId;
  final int totalXp;
  final int huntsCompleted;
  final int guardianshipsHeld;

  /// Rank title based on Total XP thresholds.
  String get rankTitle {
    if (totalXp >= 5000) return 'Legend of Surat 👑';
    if (totalXp >= 2500) return 'Treasure Master 💎';
    if (totalXp >= 1000) return 'City Detective 🕵️‍♂️';
    if (totalXp >= 300) return 'Scout Explorer 🧭';
    return 'Rookie Hunter 🎒';
  }

  factory UserRankModel.fromJson(Map<String, dynamic> json) {
    return UserRankModel(
      userId: json['userId'] as String? ?? '',
      totalXp: json['totalXp'] as int? ?? 0,
      huntsCompleted: json['huntsCompleted'] as int? ?? 0,
      guardianshipsHeld: json['guardianshipsHeld'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalXp': totalXp,
        'huntsCompleted': huntsCompleted,
        'guardianshipsHeld': guardianshipsHeld,
      };

  @override
  List<Object?> get props => [
        userId,
        totalXp,
        huntsCompleted,
        guardianshipsHeld,
      ];
}
