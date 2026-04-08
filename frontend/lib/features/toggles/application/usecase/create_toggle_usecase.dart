import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:feature_toggle_app/features/toggles/domain/port/toggle_repository.dart';

class CreateToggleUseCase {
  final ToggleRepository _repo;
  const CreateToggleUseCase(this._repo);

  FutureEither<FeatureToggle> call({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? description,
    required List<String> environments,
  }) {
    return _repo.create(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
      description: description,
      environments: environments,
    );
  }
}
