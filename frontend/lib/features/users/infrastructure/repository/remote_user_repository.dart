import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:feature_toggle_app/app/config/app_config.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/auth/domain/model/user.dart';
import 'package:feature_toggle_app/features/auth/infrastructure/dto/user_dto.dart';
import 'package:feature_toggle_app/features/auth/infrastructure/mapper/user_mapper.dart';
import 'package:feature_toggle_app/features/users/domain/port/user_repository.dart';

class RemoteUserRepository implements UserRepository {
  RemoteUserRepository({UserMapper? mapper})
      : _mapper = mapper ?? UserMapper();

  static const _timeout = Duration(seconds: 10);
  final UserMapper _mapper;

  @override
  FutureEither<PagedUsers> getAll({
    required String accessToken,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users').replace(
        queryParameters: {'page': '$page', 'size': '$size'},
      );

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
          .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
          .map(_mapper.toDomain)
          .toList();

      return Right(PagedUsers(
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
  FutureEither<User> update({
    required String accessToken,
    required UserId userId,
    String? platformRole,
    bool? active,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (platformRole != null) body['platformRole'] = platformRole;
      if (active != null) body['active'] = active;

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/users/${userId.value}'),
            headers: _headers(accessToken),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dto = UserDto.fromJson(json['payload'] as Map<String, dynamic>);

      return Right(_mapper.toDomain(dto));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  @override
  FutureEither<List<User>> search({
    required String accessToken,
    required String query,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/search').replace(
        queryParameters: {'q': query},
      );

      final response = await http
          .get(uri, headers: _headers(accessToken))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as List<dynamic>;
      final users = payload
          .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
          .map(_mapper.toDomain)
          .toList();

      return Right(users);
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
