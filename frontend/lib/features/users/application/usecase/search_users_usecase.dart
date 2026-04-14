import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/features/auth/domain/model/user.dart';
import 'package:togli_app/features/users/domain/port/user_repository.dart';

class SearchUsersUseCase {
  final UserRepository _repo;
  const SearchUsersUseCase(this._repo);

  FutureEither<List<User>> call({
    required String accessToken,
    required String query,
  }) {
    return _repo.search(accessToken: accessToken, query: query);
  }
}
