import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:feature_toggle_app/app/config/app_config.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:feature_toggle_app/features/toggles/domain/port/toggle_repository.dart';
import 'package:feature_toggle_app/features/toggles/infrastructure/dto/feature_toggle_dto.dart';
import 'package:feature_toggle_app/features/toggles/infrastructure/mapper/toggle_mapper.dart';

class RemoteToggleRepository implements ToggleRepository {
  RemoteToggleRepository({ToggleMapper? mapper})
      : _mapper = mapper ?? ToggleMapper();

  static const _timeout = Duration(seconds: 10);
  final ToggleMapper _mapper;

  @override
  FutureEither<PagedToggles> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
    bool? enabled,
    String? environment,
  }) async {
    try {
      final Map<String, String> params = {
        'page': '$page',
        'size': '$size',
      };
      if (enabled != null) params['enabled'] = '$enabled';
      if (environment != null) params['environment'] = environment;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/projects/${projectId.value}/toggles',
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
          .map((e) => FeatureToggleDto.fromJson(e as Map<String, dynamic>))
          .map(_mapper.toDomain)
          .toList();

      return Right(PagedToggles(
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
  FutureEither<FeatureToggle> create({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? description,
    required List<String> environments,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'environments': environments,
      };
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}/toggles',
            ),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = FeatureToggleDto.fromJson(
        json['payload'] as Map<String, dynamic>,
      );

      return Right(_mapper.toDomain(dto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<FeatureToggle> update({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
    String? name,
    String? description,
    List<String>? environments,
    Map<String, bool>? environmentStates,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (environments != null) body['environments'] = environments;
      if (environmentStates != null && environmentStates.isNotEmpty) {
        body['environmentStates'] = environmentStates;
      }

      final response = await http
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/toggles/${toggleId.value}',
            ),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = FeatureToggleDto.fromJson(
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
    required ToggleId toggleId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/projects/${projectId.value}'
              '/toggles/${toggleId.value}',
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
