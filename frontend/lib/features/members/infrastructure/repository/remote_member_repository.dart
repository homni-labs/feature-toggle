import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:togli_app/app/config/app_config.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/members/domain/model/project_membership.dart';
import 'package:togli_app/features/members/domain/port/member_repository.dart';
import 'package:togli_app/features/members/infrastructure/dto/project_membership_dto.dart';
import 'package:togli_app/features/members/infrastructure/mapper/membership_mapper.dart';

class RemoteMemberRepository implements MemberRepository {
  RemoteMemberRepository({MembershipMapper? mapper})
      : _mapper = mapper ?? MembershipMapper();

  static const _timeout = Duration(seconds: 10);
  final MembershipMapper _mapper;

  @override
  FutureEither<PagedMembers> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/projects/${projectId.value}/members',
      ).replace(queryParameters: {'page': '$page', 'size': '$size'});

      final response = await http
          .get(uri, headers: _headers(accessToken))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as List<dynamic>;
      final pagination = json['pagination'] as Map<String, dynamic>;

      final items = payload
          .map(
            (e) => ProjectMembershipDto.fromJson(e as Map<String, dynamic>),
          )
          .map(_mapper.toDomain)
          .toList();

      return Right(PagedMembers(
        items: items,
        totalElements: pagination['totalElements'] as int,
        page: pagination['page'] as int,
        size: pagination['size'] as int,
        totalPages: pagination['totalPages'] as int,
      ));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<ProjectMembership> upsert({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
    required String role,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/members/${userId.value}',
            ),
            headers: _headers(accessToken),
            body: jsonEncode({'role': role}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = ProjectMembershipDto.fromJson(
        json['payload'] as Map<String, dynamic>,
      );

      return Right(_mapper.toDomain(dto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<void> remove({
    required String accessToken,
    required ProjectId projectId,
    required UserId userId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/members/${userId.value}',
            ),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);

      if (response.statusCode != 204) {
        return Left(_mapError(response));
      }

      return const Right(null);
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Failure _mapError(http.Response response) {
    String? message;
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>?;
      message = payload?['message'] as String?;
    } catch (_) {}
    return switch (response.statusCode) {
      401 => const AuthFailure(),
      403 => const ForbiddenFailure(),
      404 => NotFoundFailure(message ?? 'Not found'),
      409 => ConflictFailure(message ?? 'Conflict'),
      >= 400 && < 500 => ValidationFailure(message ?? 'Validation error'),
      _ => const ServerFailure(),
    };
  }
}
