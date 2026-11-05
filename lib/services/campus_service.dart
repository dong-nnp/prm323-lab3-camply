import '../models/activity_models.dart';

/// Backend account actions; implementations must throw when the server has not confirmed success.
abstract interface class CampusService {
  Future<void> saveInterests(Set<String> interestIds);

  /// Return a refreshed account wallet after claiming, not an old operation-receipt balance.
  Future<MilestoneClaimResult> claimEventMilestone({
    required String milestoneId,
    required int expectedVersion,
  });
}
