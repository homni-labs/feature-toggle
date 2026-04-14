/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest;

import com.homni.togli.application.usecase.ApiKeyPage;
import com.homni.togli.application.usecase.DeleteApiKeyUseCase;
import com.homni.togli.application.usecase.IssueApiKeyUseCase;
import com.homni.togli.application.usecase.ListApiKeyClientsUseCase;
import com.homni.togli.application.usecase.ListApiKeysUseCase;
import com.homni.togli.application.usecase.ListProjectClientsUseCase;
import com.homni.togli.application.usecase.RevokeApiKeyUseCase;
import com.homni.togli.domain.model.ApiKeyClient;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.IssuedApiKey;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.infrastructure.adapter.inbound.rest.presenter.ApiKeyPresenter;
import com.homni.generated.api.ApiKeysApi;
import com.homni.generated.model.ApiKeyClientListResponse;
import com.homni.generated.model.ApiKeyCreatedSingleResponse;
import com.homni.generated.model.ApiKeyListResponse;
import com.homni.generated.model.IssueApiKeyRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Handles API key management operations.
 */
@RestController
class ApiKeysController implements ApiKeysApi {

    private final IssueApiKeyUseCase issueApiKey;
    private final ListApiKeysUseCase listApiKeys;
    private final RevokeApiKeyUseCase revokeApiKey;
    private final DeleteApiKeyUseCase deleteApiKey;
    private final ListApiKeyClientsUseCase listApiKeyClients;
    private final ListProjectClientsUseCase listProjectClients;
    private final ApiKeyPresenter presenter;

    /**
     * Creates the API keys controller.
     *
     * @param issueApiKey         the use case for issuing an API key
     * @param listApiKeys         the use case for listing API keys
     * @param revokeApiKey        the use case for revoking an API key
     * @param deleteApiKey        the use case for permanently deleting a revoked API key
     * @param listApiKeyClients   the use case for listing clients of a specific API key
     * @param listProjectClients  the use case for listing all clients in a project
     * @param presenter           maps domain objects to API response models
     */
    ApiKeysController(IssueApiKeyUseCase issueApiKey,
                      ListApiKeysUseCase listApiKeys,
                      RevokeApiKeyUseCase revokeApiKey,
                      DeleteApiKeyUseCase deleteApiKey,
                      ListApiKeyClientsUseCase listApiKeyClients,
                      ListProjectClientsUseCase listProjectClients,
                      ApiKeyPresenter presenter) {
        this.issueApiKey = issueApiKey;
        this.listApiKeys = listApiKeys;
        this.revokeApiKey = revokeApiKey;
        this.deleteApiKey = deleteApiKey;
        this.listApiKeyClients = listApiKeyClients;
        this.listProjectClients = listProjectClients;
        this.presenter = presenter;
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ApiKeyCreatedSingleResponse> issueApiKey(UUID projectId,
                                                                    IssueApiKeyRequest req) {
        Instant expiresAt = req.getExpiresAt() != null ? req.getExpiresAt().toInstant() : null;
        IssuedApiKey issued = issueApiKey.execute(new ProjectId(projectId), req.getName(), expiresAt);
        return ResponseEntity.ok(presenter.created(issued));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ApiKeyListResponse> listApiKeys(UUID projectId, Integer page, Integer size) {
        PaginationParams p = PaginationParams.of(page, size);
        ApiKeyPage result = listApiKeys.execute(new ProjectId(projectId), p.page(), p.size());
        return ResponseEntity.ok(presenter.list(result, p.page(), p.size()));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<Void> revokeApiKey(UUID projectId, UUID apiKeyId) {
        revokeApiKey.execute(new ApiKeyId(apiKeyId));
        return ResponseEntity.noContent().build();
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<Void> deleteApiKey(UUID projectId, UUID apiKeyId) {
        deleteApiKey.execute(new ApiKeyId(apiKeyId));
        return ResponseEntity.noContent().build();
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ApiKeyClientListResponse> listApiKeyClients(UUID projectId,
                                                                       UUID apiKeyId) {
        List<ApiKeyClient> result = listApiKeyClients.execute(
                new ProjectId(projectId), new ApiKeyId(apiKeyId));
        return ResponseEntity.ok(presenter.clientList(result));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<ApiKeyClientListResponse> listProjectClients(UUID projectId) {
        List<ApiKeyClient> result = listProjectClients.execute(new ProjectId(projectId));
        return ResponseEntity.ok(presenter.clientList(result));
    }
}
