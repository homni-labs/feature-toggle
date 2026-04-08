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

  FutureEither<FeatureToggle> update({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
    String? name,
    String? description,
    List<String>? environments,
    bool? enabled,
  });

  FutureEither<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
  });
}
