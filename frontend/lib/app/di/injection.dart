import 'package:get_it/get_it.dart';

import 'package:feature_toggle_app/features/auth/domain/port/auth_repository.dart';
import 'package:feature_toggle_app/features/auth/infrastructure/repository/auth_service.dart';
import 'package:feature_toggle_app/features/auth/infrastructure/repository/user_profile_repository.dart';
import 'package:feature_toggle_app/features/auth/infrastructure/storage/token_storage.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';

import 'package:feature_toggle_app/features/projects/domain/port/project_repository.dart';
import 'package:feature_toggle_app/features/projects/infrastructure/repository/remote_project_repository.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/load_projects_usecase.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/create_project_usecase.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/update_project_usecase.dart';
import 'package:feature_toggle_app/features/projects/application/bloc/projects_cubit.dart';
import 'package:feature_toggle_app/features/projects/application/bloc/project_settings_cubit.dart';

import 'package:feature_toggle_app/features/toggles/domain/port/toggle_repository.dart';
import 'package:feature_toggle_app/features/toggles/infrastructure/repository/remote_toggle_repository.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/load_toggles_usecase.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/create_toggle_usecase.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/update_toggle_usecase.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/delete_toggle_usecase.dart';
import 'package:feature_toggle_app/features/toggles/application/bloc/toggles_cubit.dart';

import 'package:feature_toggle_app/features/environments/domain/port/environment_repository.dart';
import 'package:feature_toggle_app/features/environments/infrastructure/repository/remote_environment_repository.dart';
import 'package:feature_toggle_app/features/environments/application/usecase/load_environments_usecase.dart';
import 'package:feature_toggle_app/features/environments/application/usecase/load_default_environments_usecase.dart';
import 'package:feature_toggle_app/features/environments/application/usecase/create_environment_usecase.dart';
import 'package:feature_toggle_app/features/environments/application/usecase/delete_environment_usecase.dart';
import 'package:feature_toggle_app/features/environments/application/bloc/environments_cubit.dart';

import 'package:feature_toggle_app/features/members/domain/port/member_repository.dart';
import 'package:feature_toggle_app/features/members/infrastructure/repository/remote_member_repository.dart';
import 'package:feature_toggle_app/features/members/application/usecase/load_members_usecase.dart';
import 'package:feature_toggle_app/features/members/application/usecase/upsert_member_usecase.dart';
import 'package:feature_toggle_app/features/members/application/usecase/remove_member_usecase.dart';
import 'package:feature_toggle_app/features/members/application/bloc/members_cubit.dart';

import 'package:feature_toggle_app/features/api_keys/domain/port/api_key_repository.dart';
import 'package:feature_toggle_app/features/api_keys/infrastructure/repository/remote_api_key_repository.dart';
import 'package:feature_toggle_app/features/api_keys/application/usecase/load_api_keys_usecase.dart';
import 'package:feature_toggle_app/features/api_keys/application/usecase/issue_api_key_usecase.dart';
import 'package:feature_toggle_app/features/api_keys/application/usecase/revoke_api_key_usecase.dart';
import 'package:feature_toggle_app/features/api_keys/application/usecase/delete_api_key_usecase.dart';
import 'package:feature_toggle_app/features/api_keys/application/bloc/api_keys_cubit.dart';

import 'package:feature_toggle_app/features/users/domain/port/user_repository.dart';
import 'package:feature_toggle_app/features/users/infrastructure/repository/remote_user_repository.dart';
import 'package:feature_toggle_app/features/users/application/usecase/load_users_usecase.dart';
import 'package:feature_toggle_app/features/users/application/usecase/update_user_usecase.dart';
import 'package:feature_toggle_app/features/users/application/usecase/search_users_usecase.dart';
import 'package:feature_toggle_app/features/users/application/bloc/users_cubit.dart';

final sl = GetIt.instance;

void configureDependencies() {
  // ── Auth ──────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => OidcAuthRepository());
  sl.registerLazySingleton<TokenStorage>(() => WebTokenStorage());
  sl.registerLazySingleton<UserProfileRepository>(
    () => RemoteUserProfileRepository(),
  );
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      authRepo: sl<AuthRepository>(),
      profileRepo: sl<UserProfileRepository>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  // ── Projects ──────────────────────────────────────────────────
  sl.registerLazySingleton<ProjectRepository>(() => RemoteProjectRepository());
  sl.registerFactory(() => LoadProjectsUseCase(sl<ProjectRepository>()));
  sl.registerFactory(() => CreateProjectUseCase(sl<ProjectRepository>()));
  sl.registerFactory(() => UpdateProjectUseCase(sl<ProjectRepository>()));
  sl.registerFactory(
    () => ProjectsCubit(
      loadProjects: sl<LoadProjectsUseCase>(),
      createProject: sl<CreateProjectUseCase>(),
      updateProject: sl<UpdateProjectUseCase>(),
    ),
  );
  sl.registerFactory(
    () => ProjectSettingsCubit(updateProject: sl<UpdateProjectUseCase>()),
  );

  // ── Toggles ───────────────────────────────────────────────────
  sl.registerLazySingleton<ToggleRepository>(() => RemoteToggleRepository());
  sl.registerFactory(() => LoadTogglesUseCase(sl<ToggleRepository>()));
  sl.registerFactory(() => CreateToggleUseCase(sl<ToggleRepository>()));
  sl.registerFactory(() => UpdateToggleUseCase(sl<ToggleRepository>()));
  sl.registerFactory(() => DeleteToggleUseCase(sl<ToggleRepository>()));
  sl.registerFactory(
    () => TogglesCubit(
      loadToggles: sl<LoadTogglesUseCase>(),
      createToggle: sl<CreateToggleUseCase>(),
      updateToggle: sl<UpdateToggleUseCase>(),
      deleteToggle: sl<DeleteToggleUseCase>(),
    ),
  );

  // ── Environments ──────────────────────────────────────────────
  sl.registerLazySingleton<EnvironmentRepository>(
    () => RemoteEnvironmentRepository(),
  );
  sl.registerFactory(() => LoadEnvironmentsUseCase(sl<EnvironmentRepository>()));
  sl.registerFactory(
    () => LoadDefaultEnvironmentsUseCase(sl<EnvironmentRepository>()),
  );
  sl.registerFactory(() => CreateEnvironmentUseCase(sl<EnvironmentRepository>()));
  sl.registerFactory(() => DeleteEnvironmentUseCase(sl<EnvironmentRepository>()));
  sl.registerFactory(
    () => EnvironmentsCubit(
      loadEnvironments: sl<LoadEnvironmentsUseCase>(),
      createEnvironment: sl<CreateEnvironmentUseCase>(),
      deleteEnvironment: sl<DeleteEnvironmentUseCase>(),
    ),
  );

  // ── Members ───────────────────────────────────────────────────
  sl.registerLazySingleton<MemberRepository>(() => RemoteMemberRepository());
  sl.registerFactory(() => LoadMembersUseCase(sl<MemberRepository>()));
  sl.registerFactory(() => UpsertMemberUseCase(sl<MemberRepository>()));
  sl.registerFactory(() => RemoveMemberUseCase(sl<MemberRepository>()));
  sl.registerFactory(
    () => MembersCubit(
      loadMembers: sl<LoadMembersUseCase>(),
      upsertMember: sl<UpsertMemberUseCase>(),
      removeMember: sl<RemoveMemberUseCase>(),
    ),
  );

  // ── API Keys ──────────────────────────────────────────────────
  sl.registerLazySingleton<ApiKeyRepository>(() => RemoteApiKeyRepository());
  sl.registerFactory(() => LoadApiKeysUseCase(sl<ApiKeyRepository>()));
  sl.registerFactory(() => IssueApiKeyUseCase(sl<ApiKeyRepository>()));
  sl.registerFactory(() => RevokeApiKeyUseCase(sl<ApiKeyRepository>()));
  sl.registerFactory(() => DeleteApiKeyUseCase(sl<ApiKeyRepository>()));
  sl.registerFactory(
    () => ApiKeysCubit(
      loadApiKeys: sl<LoadApiKeysUseCase>(),
      issueApiKey: sl<IssueApiKeyUseCase>(),
      revokeApiKey: sl<RevokeApiKeyUseCase>(),
      deleteApiKey: sl<DeleteApiKeyUseCase>(),
    ),
  );

  // ── Users ─────────────────────────────────────────────────────
  sl.registerLazySingleton<UserRepository>(() => RemoteUserRepository());
  sl.registerFactory(() => LoadUsersUseCase(sl<UserRepository>()));
  sl.registerFactory(() => UpdateUserUseCase(sl<UserRepository>()));
  sl.registerFactory(() => SearchUsersUseCase(sl<UserRepository>()));
  sl.registerFactory(
    () => UsersCubit(
      loadUsers: sl<LoadUsersUseCase>(),
      updateUser: sl<UpdateUserUseCase>(),
    ),
  );
}
