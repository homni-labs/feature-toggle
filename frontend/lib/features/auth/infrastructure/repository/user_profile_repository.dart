import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:feature_toggle_app/app/config/app_config.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/features/auth/domain/model/user.dart';
import 'package:feature_toggle_app/features/auth/domain/port/auth_repository.dart';
import 'package:feature_toggle_app/features/auth/infrastructure/dto/user_dto.dart';
import 'package:feature_toggle_app/features/auth/infrastructure/mapper/user_mapper.dart';

class RemoteUserProfileRepository implements UserProfileRepository {
  final UserMapper _mapper;

  RemoteUserProfileRepository({UserMapper? mapper})
      : _mapper = mapper ?? UserMapper();

  static const _timeout = Duration(seconds: 10);

  @override
  Future<Either<Failure, User>> getCurrentUser(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: _headers(accessToken),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        return Left(_mapError(response));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>;
      return Right(_mapper.toDomain(UserDto.fromJson(payload)));
    } on Exception {
      return const Left(NetworkFailure());
    }
  }

  Failure _mapError(http.Response response) {
    return switch (response.statusCode) {
      401 => const AuthFailure(),
      403 => const ForbiddenFailure(),
      _ => const ServerFailure(),
    };
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
}
