import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/features/environments/domain/port/environment_repository.dart';

class LoadDefaultEnvironmentsUseCase {
  final EnvironmentRepository _repo;
  const LoadDefaultEnvironmentsUseCase(this._repo);

  FutureEither<List<String>> call({required String accessToken}) {
    return _repo.getDefaults(accessToken: accessToken);
  }
}
