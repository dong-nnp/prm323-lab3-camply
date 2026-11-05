import '../models/activity_models.dart';
import '../services/campus_service.dart';

class CampusRepository {
  const CampusRepository(this._service);
  final CampusService _service;

  Future<void> saveInterests(Set<String> interestIds) =>
      _service.saveInterests(interestIds);
  Future<MilestoneClaimResult> claimEventMilestone(
    String milestoneId,
    int version,
  ) => _service.claimEventMilestone(
    milestoneId: milestoneId,
    expectedVersion: version,
  );
}
