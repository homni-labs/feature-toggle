import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:togli_app/app/config/app_config.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/environments/domain/model/environment.dart';
import 'package:togli_app/features/environments/domain/port/environment_repository.dart';
import 'package:togli_app/features/environments/infrastructure/dto/environment_dto.dart';
import 'package:togli_app/features/environments/infrastructure/mapper/environment_mapper.dart';

class RemoteEnvironmentRepository implements EnvironmentRepository {
  RemoteEnvironmentRepository({EnvironmentMapper? mapper})
      : _mapper = mapper ?? EnvironmentMapper();

  static const _timeout = Duration(seconds: 10);
  final EnvironmentMapper _mapper;

  @override
  FutureEither<PagedEnvironments> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final Map<String, String> params = {
        'page': '$page',
        'size': '$size',
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/projects/${projectId.value}/environments',
      ).replace(queryParameters: params);

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
          .map((e) => EnvironmentDto.fromJson(e as Map<String, dynamic>))
          .map(_mapper.toDomain)
          .toList();

      return Right(PagedEnvironments(
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
  FutureEither<Environment> create({
    required String accessToken,
    required ProjectId projectId,
    required String name,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}/environments',
            ),
            headers: _headers(accessToken),
            body: jsonEncode({'name': name}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = EnvironmentDto.fromJson(
        json['payload'] as Map<String, dynamic>,
      );

      return Right(_mapper.toDomain(dto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required EnvironmentId environmentId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/environments/${environmentId.value}',
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

  @override
  FutureEither<List<String>> getDefaults({
    required String accessToken,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/environments/defaults'),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as List<dynamic>;
      return Right(payload.cast<String>());
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
