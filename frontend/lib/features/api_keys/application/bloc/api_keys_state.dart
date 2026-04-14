import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key.dart';

sealed class ApiKeysState {
  const ApiKeysState();
}

class ApiKeysInitial extends ApiKeysState {
  const ApiKeysInitial();
}

class ApiKeysLoading extends ApiKeysState {
  const ApiKeysLoading();
}

class ApiKeysLoaded extends ApiKeysState {
  final List<ApiKey> apiKeys;
  final int totalElements;
  final int page;
  final int totalPages;

  const ApiKeysLoaded({
    required this.apiKeys,
    required this.totalElements,
    required this.page,
    required this.totalPages,
  });
}

class ApiKeyIssued extends ApiKeysState {
  final ApiKeyCreated created;
  const ApiKeyIssued(this.created);
}

class ApiKeysError extends ApiKeysState {
  final Failure failure;
  const ApiKeysError(this.failure);
}
