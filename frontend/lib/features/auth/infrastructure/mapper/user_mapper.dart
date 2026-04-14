import 'package:togli_app/core/domain/value_objects/email.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/core/domain/value_objects/platform_role.dart';
import 'package:togli_app/features/auth/domain/model/user.dart';
import 'package:togli_app/features/auth/infrastructure/dto/user_dto.dart';

class UserMapper {
  User toDomain(UserDto dto) {
    return User(
      id: UserId(dto.id),
      oidcSubject: dto.oidcSubject,
      email: Email(dto.email),
      name: dto.name,
      platformRole: PlatformRole.from(dto.platformRole),
      active: dto.active,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: dto.updatedAt != null ? DateTime.parse(dto.updatedAt!) : null,
    );
  }
}
