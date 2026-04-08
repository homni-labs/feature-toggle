import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/features/api_keys/application/bloc/api_keys_state.dart';
import 'package:feature_toggle_app/features/api_keys/application/usecase/issue_api_key_usecase.dart';
import 'package:feature_toggle_app/features/api_keys/application/usecase/load_api_keys_usecase.dart';
import 'package:feature_toggle_app/features/api_keys/application/usecase/revoke_api_key_usecase.dart';
import 'package:feature_toggle_app/features/api_keys/domain/model/api_key.dart';

class ApiKeysCubit extends Cubit<ApiKeysState> {
  final LoadApiKeysUseCase _loadApiKeys;
  final IssueApiKeyUseCase _issueApiKey;
  final RevokeApiKeyUseCase _revokeApiKey;

  static const _pageSize = 10;

  ApiKeysCubit({
    required LoadApiKeysUseCase loadApiKeys,
    required IssueApiKeyUseCase issueApiKey,
    required RevokeApiKeyUseCase revokeApiKey,
  })  : _loadApiKeys = loadApiKeys,
        _issueApiKey = issueApiKey,
        _revokeApiKey = revokeApiKey,
        super(const ApiKeysInitial());

  Future<void> load({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
  }) async {
    emit(const ApiKeysLoading());
    final result = await _loadApiKeys(
      accessToken: accessToken,
      projectId: projectId,
      page: page,
      size: _pageSize,
    );
    result.fold(
      (f) => emit(ApiKeysError(f)),
      (paged) => emit(ApiKeysLoaded(
        apiKeys: paged.items,
        totalElements: paged.totalElements,
        page: paged.page,
        totalPages: paged.totalPages,
      )),
    );
  }

  Future<void> issue({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? expiresAt,
  }) async {
    final result = await _issueApiKey(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
      expiresAt: expiresAt,
    );
    result.fold(
      (f) => emit(ApiKeysError(f)),
      (created) => emit(ApiKeyIssued(created)),
    );
  }

  void addIssuedToList(ApiKeyCreated created, ProjectId projectId) {
    final current = state;
    final apiKey = ApiKey(
      id: created.id,
      projectId: projectId,
      projectName: created.projectName,
      name: created.name,
      role: ProjectRole.reader,
      maskedToken: '${created.rawToken.substring(0, 8)}...',
      active: true,
      createdAt: created.createdAt,
      expiresAt: created.expiresAt,
    );
    if (current is ApiKeysLoaded) {
      final list = [apiKey, ...current.apiKeys];
      if (list.length > _pageSize) list.removeLast();
      emit(ApiKeysLoaded(
        apiKeys: list,
        totalElements: current.totalElements + 1,
        page: current.page,
        totalPages: ((current.totalElements + 1) / _pageSize).ceil(),
      ));
    }
  }

  Future<void> revoke({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  }) async {
    final result = await _revokeApiKey(
      accessToken: accessToken,
      projectId: projectId,
      apiKeyId: apiKeyId,
    );
    result.fold(
      (f) => emit(ApiKeysError(f)),
      (_) {
        final current = state;
        if (current is ApiKeysLoaded) {
          final list = current.apiKeys
              .where((k) => k.id != apiKeyId)
              .toList();
          emit(ApiKeysLoaded(
            apiKeys: list,
            totalElements: current.totalElements - 1,
            page: current.page,
            totalPages: (current.totalElements - 1) > 0
                ? ((current.totalElements - 1) / _pageSize).ceil()
                : 0,
          ));
        }
      },
    );
  }
}
