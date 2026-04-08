import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';
import 'package:feature_toggle_app/features/projects/domain/port/project_repository.dart';

class LoadProjectsUseCase {
  final ProjectRepository _repo;
  const LoadProjectsUseCase(this._repo);

  FutureEither<List<Project>> call({required String accessToken}) {
    return _repo.getAll(accessToken: accessToken);
  }
}
