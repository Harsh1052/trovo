import 'package:equatable/equatable.dart';

enum PromotionZone { promotion, safe, demotion }

/// Member of a 20-Player Weekly League cohort.
class LeagueMemberModel extends Equatable {
  const LeagueMemberModel({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.weeklyXp,
    required this.rankPosition,
    this.leagueTier = 'Emerald',
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final int weeklyXp;
  final int rankPosition;
  final String leagueTier;

  /// Promotion/Demotion zone based on rank position (1..20).
  PromotionZone get zone {
    if (rankPosition <= 3) return PromotionZone.promotion;
    if (rankPosition >= 18) return PromotionZone.demotion;
    return PromotionZone.safe;
  }

  factory LeagueMemberModel.fromJson(Map<String, dynamic> json) {
    return LeagueMemberModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Hunter',
      photoUrl: json['photoUrl'] as String?,
      weeklyXp: json['weeklyXp'] as int? ?? 0,
      rankPosition: json['rankPosition'] as int? ?? 1,
      leagueTier: json['leagueTier'] as String? ?? 'Emerald',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'weeklyXp': weeklyXp,
        'rankPosition': rankPosition,
        'leagueTier': leagueTier,
      };

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        weeklyXp,
        rankPosition,
        leagueTier,
      ];
}
