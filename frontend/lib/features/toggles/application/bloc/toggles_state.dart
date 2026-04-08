import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';

sealed class TogglesState {
  const TogglesState();
}

class TogglesInitial extends TogglesState {
  const TogglesInitial();
}

class TogglesLoading extends TogglesState {
  const TogglesLoading();
}

class TogglesLoaded extends TogglesState {
  final List<FeatureToggle> toggles;
  final int totalElements;
  final int page;
  final int totalPages;
  final bool? filterEnabled;
  final String? filterEnvironment;

  const TogglesLoaded({
    required this.toggles,
    required this.totalElements,
    required this.page,
    required this.totalPages,
    this.filterEnabled,
    this.filterEnvironment,
  });

  TogglesLoaded copyWith({
    List<FeatureToggle>? toggles,
    int? totalElements,
    int? page,
    int? totalPages,
    bool? filterEnabled,
    String? filterEnvironment,
    bool clearFilters = false,
  }) {
    return TogglesLoaded(
      toggles: toggles ?? this.toggles,
      totalElements: totalElements ?? this.totalElements,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      filterEnabled: clearFilters ? null : (filterEnabled ?? this.filterEnabled),
      filterEnvironment: clearFilters ? null : (filterEnvironment ?? this.filterEnvironment),
    );
  }
}

class TogglesError extends TogglesState {
  final Failure failure;
  const TogglesError(this.failure);
}
