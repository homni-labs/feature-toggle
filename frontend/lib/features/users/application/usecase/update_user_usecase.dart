import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/auth/domain/model/user.dart';
import 'package:feature_toggle_app/features/users/domain/port/user_repository.dart';

class UpdateUserUseCase {
  final UserRepository _repo;
  const UpdateUserUseCase(this._repo);

  FutureEither<User> call({
    required String accessToken,
    required UserId userId,
    String? platformRole,
    bool? active,
  }) {
    return _repo.update(
      accessToken: accessToken,
      userId: userId,
      platformRole: platformRole,
      active: active,
    );
  }
}
