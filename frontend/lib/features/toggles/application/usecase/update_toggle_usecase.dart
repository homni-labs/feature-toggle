import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:feature_toggle_app/features/toggles/domain/port/toggle_repository.dart';

class UpdateToggleUseCase {
  final ToggleRepository _repo;
  const UpdateToggleUseCase(this._repo);

  FutureEither<FeatureToggle> call({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
    String? name,
    String? description,
    List<String>? environments,
    Map<String, bool>? environmentStates,
  }) {
    return _repo.update(
      accessToken: accessToken,
      projectId: projectId,
      toggleId: toggleId,
      name: name,
      description: description,
      environments: environments,
      environmentStates: environmentStates,
    );
  }
}
