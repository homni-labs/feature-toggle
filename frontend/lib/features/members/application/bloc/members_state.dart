import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/members/domain/model/project_membership.dart';

sealed class MembersState {
  const MembersState();
}

class MembersInitial extends MembersState {
  const MembersInitial();
}

class MembersLoading extends MembersState {
  const MembersLoading();
}

class MembersLoaded extends MembersState {
  final List<ProjectMembership> members;
  final int totalElements;
  final int page;
  final int totalPages;

  const MembersLoaded({
    required this.members,
    required this.totalElements,
    required this.page,
    required this.totalPages,
  });
}

class MembersError extends MembersState {
  final Failure failure;
  const MembersError(this.failure);
}
