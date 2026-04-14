import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/environments/domain/model/environment.dart';

sealed class EnvironmentsState {
  const EnvironmentsState();
}

class EnvironmentsInitial extends EnvironmentsState {
  const EnvironmentsInitial();
}

class EnvironmentsLoading extends EnvironmentsState {
  const EnvironmentsLoading();
}

class EnvironmentsLoaded extends EnvironmentsState {
  final List<Environment> environments;
  final int totalElements;
  final int page;
  final int totalPages;

  const EnvironmentsLoaded({
    required this.environments,
    required this.totalElements,
    required this.page,
    required this.totalPages,
  });

  EnvironmentsLoaded copyWith({
    List<Environment>? environments,
    int? totalElements,
    int? page,
    int? totalPages,
  }) {
    return EnvironmentsLoaded(
      environments: environments ?? this.environments,
      totalElements: totalElements ?? this.totalElements,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class EnvironmentsError extends EnvironmentsState {
  final Failure failure;
  const EnvironmentsError(this.failure);
}
