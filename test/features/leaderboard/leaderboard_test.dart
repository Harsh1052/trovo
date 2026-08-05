import 'package:flutter_test/flutter_test.dart';
import 'package:huntermania/shared/models/guardian_record_model.dart';
import 'package:huntermania/shared/models/league_member_model.dart';
import 'package:huntermania/shared/models/user_rank_model.dart';

void main() {
  group('Leaderboard Models', () {
    test('GuardianRecordModel formats time correctly', () {
      final guardian = GuardianRecordModel(
        huntId: 'hunt_surat_01',
        guardianUserId: 'user_123',
        guardianName: 'Surat King',
        bestTimeSeconds: 765, // 12m 45s
        setAt: DateTime.now(),
      );

      expect(guardian.formattedTime, '12m 45s');
    });

    test('LeagueMemberModel computes promotion zone for top 3 ranks', () {
      const topMember = LeagueMemberModel(
        userId: 'u1',
        displayName: 'Aarav',
        weeklyXp: 1200,
        rankPosition: 2,
      );

      expect(topMember.zone, PromotionZone.promotion);
    });

    test('UserRankModel computes correct status rank titles', () {
      const rookie = UserRankModel(
        userId: 'u1',
        totalXp: 150,
        huntsCompleted: 1,
        guardianshipsHeld: 0,
      );
      expect(rookie.rankTitle, contains('Rookie Hunter'));

      const legend = UserRankModel(
        userId: 'u2',
        totalXp: 5500,
        huntsCompleted: 10,
        guardianshipsHeld: 3,
      );
      expect(legend.rankTitle, contains('Legend of Surat'));
    });
  });
}
