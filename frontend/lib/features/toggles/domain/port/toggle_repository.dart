import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';

class PagedToggles {
  final List<FeatureToggle> items;
  final int totalElements;
  final int page;
  final int size;
  final int totalPages;

  const PagedToggles({
    required this.items,
    required this.totalElements,
    required this.page,
    required this.size,
    required this.totalPages,
  });
}

abstract class ToggleRepository {
  FutureEither<PagedToggles> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
    bool? enabled,
    String? environment,
  });

  FutureEither<FeatureToggle> create({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? description,
    required List<String> environments,
  });

  /// Updates a toggle. The optional [environmentStates] map flips the
  /// enabled flag for each listed env independently — pass a one-entry map
  /// for an inline switch click on a single env, a multi-entry map for bulk
  /// form-style edits. Envs not listed are left untouched.
  FutureEither<FeatureToggle> update({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
    String? name,
    String? description,
    List<String>? environments,
    Map<String, bool>? environmentStates,
  });

  FutureEither<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
  });
}
