import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/members/domain/port/member_repository.dart';

class RemoveMemberUseCase {
  final MemberRepository _repo;
  const RemoveMemberUseCase(this._repo);

  FutureEither<void> call({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
  }) {
    return _repo.remove(
      accessToken: accessToken,
      projectId: projectId,
      userId: userId,
    );
  }
}
