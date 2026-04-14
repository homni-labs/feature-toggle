import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key_client.dart';

sealed class ApiKeyClientsState {
  const ApiKeyClientsState();
}

class ApiKeyClientsInitial extends ApiKeyClientsState {
  const ApiKeyClientsInitial();
}

class ApiKeyClientsLoading extends ApiKeyClientsState {
  const ApiKeyClientsLoading();
}

class ApiKeyClientsLoaded extends ApiKeyClientsState {
  final List<ApiKeyClient> clients;
  final List<ApiKeyClient> sdkClients;
  final List<ApiKeyClient> restClients;

  ApiKeyClientsLoaded(this.clients)
      : sdkClients = clients.where((c) => c.clientType == ClientType.sdk).toList(),
        restClients = clients.where((c) => c.clientType == ClientType.rest).toList();
}

class ApiKeyClientsError extends ApiKeyClientsState {
  final Failure failure;
  const ApiKeyClientsError(this.failure);
}
