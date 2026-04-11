import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/environments/domain/model/environment.dart';

class PagedEnvironments {
  final List<Environment> items;
  final int totalElements;
  final int page;
  final int size;
  final int totalPages;

  const PagedEnvironments({
    required this.items,
    required this.totalElements,
    required this.page,
    required this.size,
    required this.totalPages,
  });
}

abstract class EnvironmentRepository {
  FutureEither<PagedEnvironments> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  });

  FutureEither<Environment> create({
    required String accessToken,
    required ProjectId projectId,
    required String name,
  });

  FutureEither<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required EnvironmentId environmentId,
  });

  FutureEither<List<String>> getDefaults({
    required String accessToken,
  });
}
