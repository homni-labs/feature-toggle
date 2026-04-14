import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/toggles/domain/port/toggle_repository.dart';

class LoadTogglesUseCase {
  final ToggleRepository _repo;
  const LoadTogglesUseCase(this._repo);

  FutureEither<PagedToggles> call({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
    bool? enabled,
    String? environment,
  }) {
    return _repo.getAll(
      accessToken: accessToken,
      projectId: projectId,
      page: page,
      size: size,
      enabled: enabled,
      environment: environment,
    );
  }
}
