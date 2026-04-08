import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/features/users/domain/port/user_repository.dart';

class LoadUsersUseCase {
  final UserRepository _repo;
  const LoadUsersUseCase(this._repo);

  FutureEither<PagedUsers> call({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) {
    return _repo.getAll(accessToken: accessToken, page: page, size: size);
  }
}
