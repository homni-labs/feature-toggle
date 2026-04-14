import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/auth/domain/model/user.dart';

class PagedUsers {
  final List<User> items;
  final int totalElements;
  final int page;
  final int size;
  final int totalPages;

  const PagedUsers({
    required this.items,
    required this.totalElements,
    required this.page,
    required this.size,
    required this.totalPages,
  });
}

abstract class UserRepository {
  FutureEither<PagedUsers> getAll({
    required String accessToken,
    int page = 0,
    int size = 20,
  });

  FutureEither<User> update({
    required String accessToken,
    required UserId userId,
    String? platformRole,
    bool? active,
  });

  FutureEither<List<User>> search({
    required String accessToken,
    required String query,
  });
}
