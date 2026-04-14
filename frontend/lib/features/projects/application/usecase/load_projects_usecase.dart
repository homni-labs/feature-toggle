import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';
import 'package:togli_app/features/projects/domain/port/project_repository.dart';

class LoadProjectsUseCase {
  final ProjectRepository _repo;
  const LoadProjectsUseCase(this._repo);

  FutureEither<ProjectsPage> call({
    required String accessToken,
    String? searchText,
    bool? archived,
    int page = 0,
    int size = 6,
  }) {
    return _repo.getAll(
      accessToken: accessToken,
      searchText: searchText,
      archived: archived,
      page: page,
      size: size,
    );
  }
}
