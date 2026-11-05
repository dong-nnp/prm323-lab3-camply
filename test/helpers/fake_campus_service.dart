import 'package:prm393_lab03/models/activity_models.dart';
import 'package:prm393_lab03/services/campus_service.dart';

class FakeCampusService implements CampusService {
  Future<void> Function(Set<String>)? onSave;
  Future<MilestoneClaimResult> Function(String, int)? onClaim;
  int saveCalls = 0, claimCalls = 0;

  @override
  Future<void> saveInterests(Set<String> interestIds) async {
    saveCalls++;
    await onSave?.call(interestIds);
  }

  @override
  Future<MilestoneClaimResult> claimEventMilestone({
    required String milestoneId,
    required int expectedVersion,
  }) async {
    claimCalls++;
    if (onClaim == null) throw StateError('No claim test fixture');
    return onClaim!(milestoneId, expectedVersion);
  }
}
