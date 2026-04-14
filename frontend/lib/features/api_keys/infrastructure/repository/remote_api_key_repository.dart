import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:togli_app/app/config/app_config.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key.dart';
import 'package:togli_app/features/api_keys/domain/port/api_key_repository.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key_client.dart';
import 'package:togli_app/features/api_keys/infrastructure/dto/api_key_dto.dart';
import 'package:togli_app/features/api_keys/infrastructure/dto/api_key_client_dto.dart';
import 'package:togli_app/features/api_keys/infrastructure/mapper/api_key_mapper.dart';
import 'package:togli_app/features/api_keys/infrastructure/mapper/api_key_client_mapper.dart';

class RemoteApiKeyRepository implements ApiKeyRepository {
  RemoteApiKeyRepository({ApiKeyMapper? mapper})
      : _mapper = mapper ?? ApiKeyMapper();

  static const _timeout = Duration(seconds: 10);
  final ApiKeyMapper _mapper;

  @override
  FutureEither<PagedApiKeys> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/projects/${projectId.value}/api-keys',
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
          .map((e) => ApiKeyDto.fromJson(e as Map<String, dynamic>))
          .map(_mapper.toDomain)
          .toList();

      return Right(PagedApiKeys(
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
  FutureEither<ApiKeyCreated> issue({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? expiresAt,
  }) async {
    try {
      final Map<String, dynamic> body = {'name': name};
      if (expiresAt != null) body['expiresAt'] = expiresAt;

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}/api-keys',
            ),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = ApiKeyCreatedDto.fromJson(
        json['payload'] as Map<String, dynamic>,
      );

      return Right(_mapper.createdToDomain(dto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<void> revoke({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/api-keys/${apiKeyId.value}',
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
  FutureEither<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/api-keys/${apiKeyId.value}/permanently',
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
  FutureEither<List<ApiKeyClient>> getClients({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/api-keys/${apiKeyId.value}/clients',
            ),
            headers: _headers(accessToken),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as List<dynamic>;

      final clients = payload
          .map((e) => ApiKeyClientDto.fromJson(e as Map<String, dynamic>))
          .map(ApiKeyClientMapper.toDomain)
          .toList();

      return Right(clients);
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
