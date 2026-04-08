import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/members/domain/port/member_repository.dart';

class LoadMembersUseCase {
  final MemberRepository _repo;
  const LoadMembersUseCase(this._repo);

  FutureEither<PagedMembers> call({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  }) {
    return _repo.getAll(
      accessToken: accessToken,
      projectId: projectId,
      page: page,
      size: size,
    );
  }
}
