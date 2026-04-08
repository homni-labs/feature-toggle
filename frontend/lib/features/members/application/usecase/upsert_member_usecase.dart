import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/members/domain/model/project_membership.dart';
import 'package:feature_toggle_app/features/members/domain/port/member_repository.dart';

class UpsertMemberUseCase {
  final MemberRepository _repo;
  const UpsertMemberUseCase(this._repo);

  FutureEither<ProjectMembership> call({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
    required String role,
  }) {
    return _repo.upsert(
      accessToken: accessToken,
      projectId: projectId,
      userId: userId,
      role: role,
    );
  }
}
