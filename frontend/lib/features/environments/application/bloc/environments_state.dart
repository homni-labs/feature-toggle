import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/features/environments/domain/model/environment.dart';

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
  const EnvironmentsLoaded(this.environments);
}

class EnvironmentsError extends EnvironmentsState {
  final Failure failure;
  const EnvironmentsError(this.failure);
}
