import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/domain/port/toggle_repository.dart';

class DeleteToggleUseCase {
  final ToggleRepository _repo;
  const DeleteToggleUseCase(this._repo);

  FutureEither<void> call({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
  }) {
    return _repo.delete(
      accessToken: accessToken,
      projectId: projectId,
      toggleId: toggleId,
    );
  }
}
