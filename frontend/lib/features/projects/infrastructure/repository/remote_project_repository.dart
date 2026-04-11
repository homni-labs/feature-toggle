import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:feature_toggle_app/app/config/app_config.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';
import 'package:feature_toggle_app/features/projects/domain/port/project_repository.dart';
import 'package:feature_toggle_app/features/projects/infrastructure/dto/project_dto.dart';
import 'package:feature_toggle_app/features/projects/infrastructure/mapper/project_mapper.dart';

class RemoteProjectRepository implements ProjectRepository {
  RemoteProjectRepository({ProjectMapper? mapper})
      : _mapper = mapper ?? ProjectMapper();

  static const _timeout = Duration(seconds: 10);
  final ProjectMapper _mapper;

  @override
  FutureEither<ProjectsPage> getAll({
    required String accessToken,
    String? searchText,
    bool? archived,
    int page = 0,
    int size = 6,
  }) async {
    try {
      final Map<String, String> params = {
        'page': '$page',
        'size': '$size',
      };
      if (searchText != null && searchText.isNotEmpty) {
        params['q'] = searchText;
      }
      if (archived != null) params['archived'] = '$archived';

      final uri = Uri.parse('${ApiConfig.baseUrl}/projects')
          .replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _headers(accessToken))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final pageDto = ProjectsPageDto.fromJson(json);
      return Right(_mapper.toDomainPage(pageDto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<Project> getBySlug({
    required String accessToken,
    required String slug,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/projects/by-slug/$slug'),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = ProjectDto.fromJson(json['payload'] as Map<String, dynamic>);
      return Right(_mapper.toDomain(dto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<Project> create({
    required String accessToken,
    required String slug,
    required String name,
    String? description,
    List<String>? environments,
  }) async {
    try {
      final Map<String, dynamic> body = {'slug': slug, 'name': name};
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      // null = use server defaults; non-null (incl. empty []) is sent as-is
      // so the backend can distinguish "use defaults" from "opt out".
      if (environments != null) {
        body['environments'] = environments;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/projects'),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = ProjectDto.fromJson(json['payload'] as Map<String, dynamic>);

      return Right(_mapper.toDomain(dto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<Project> update({
    required String accessToken,
    required ProjectId projectId,
    String? name,
    String? description,
    bool? archived,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (archived != null) body['archived'] = archived;

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/projects/${projectId.value}'),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = ProjectDto.fromJson(json['payload'] as Map<String, dynamic>);

      return Right(_mapper.toDomain(dto));
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
