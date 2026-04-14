import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/members/domain/model/project_membership.dart';

class PagedMembers {
  final List<ProjectMembership> items;
  final int totalElements;
  final int page;
  final int size;
  final int totalPages;

  const PagedMembers({
    required this.items,
    required this.totalElements,
    required this.page,
    required this.size,
    required this.totalPages,
  });
}

abstract class MemberRepository {
  FutureEither<PagedMembers> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  });

  FutureEither<ProjectMembership> upsert({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
    required String role,
  });

  FutureEither<void> remove({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
  });
}
