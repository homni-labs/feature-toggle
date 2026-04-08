import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/environments/domain/model/environment.dart';

abstract class EnvironmentRepository {
  FutureEither<List<Environment>> getAll({
    required String accessToken,
    required ProjectId projectId,
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
}
