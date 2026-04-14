import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';
import 'package:togli_app/features/projects/domain/port/project_repository.dart';

class CreateProjectUseCase {
  final ProjectRepository _repo;
  const CreateProjectUseCase(this._repo);

  FutureEither<Project> call({
    required String accessToken,
    required String slug,
    required String name,
    String? description,
    List<String>? environments,
  }) {
    return _repo.create(
      accessToken: accessToken,
      slug: slug,
      name: name,
      description: description,
      environments: environments,
    );
  }
}
