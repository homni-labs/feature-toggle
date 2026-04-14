import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/api_keys/application/bloc/api_key_clients_state.dart';
import 'package:togli_app/features/api_keys/application/usecase/load_api_key_clients_usecase.dart';

class ApiKeyClientsCubit extends Cubit<ApiKeyClientsState> {
  final LoadApiKeyClientsUseCase _loadClients;

  ApiKeyClientsCubit({required LoadApiKeyClientsUseCase loadClients})
      : _loadClients = loadClients,
        super(const ApiKeyClientsInitial());

  Future<void> load(String accessToken, ProjectId projectId, ApiKeyId apiKeyId) async {
    emit(const ApiKeyClientsLoading());
    final result = await _loadClients(
      accessToken: accessToken,
      projectId: projectId,
      apiKeyId: apiKeyId,
    );
    result.fold(
      (failure) => emit(ApiKeyClientsError(failure)),
      (clients) => emit(ApiKeyClientsLoaded(clients)),
    );
  }
}
