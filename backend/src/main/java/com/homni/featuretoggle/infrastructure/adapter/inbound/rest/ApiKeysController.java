/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest;

import com.homni.featuretoggle.application.usecase.ApiKeyPage;
import com.homni.featuretoggle.application.usecase.IssueApiKeyUseCase;
import com.homni.featuretoggle.application.usecase.ListApiKeysUseCase;
import com.homni.featuretoggle.application.usecase.RevokeApiKeyUseCase;
import com.homni.featuretoggle.domain.model.ApiKeyId;
import com.homni.featuretoggle.domain.model.IssuedApiKey;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter.ApiKeyPresenter;
import com.homni.generated.api.ApiKeysApi;
import com.homni.generated.model.ApiKeyCreatedSingleResponse;
import com.homni.generated.model.ApiKeyListResponse;
import com.homni.generated.model.IssueApiKeyRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.UUID;

/**
 * Handles API key management operations.
 */
@RestController
class ApiKeysController implements ApiKeysApi {

    private final IssueApiKeyUseCase issueApiKey;
    private final ListApiKeysUseCase listApiKeys;
    private final RevokeApiKeyUseCase revokeApiKey;
    private final ApiKeyPresenter presenter;

    /**
     * Creates the API keys controller.
     *
     * @param issueApiKey  the use case for issuing an API key
     * @param listApiKeys  the use case for listing API keys
     * @param revokeApiKey the use case for revoking an API key
     * @param presenter    maps domain objects to API response models
     */
    ApiKeysController(IssueApiKeyUseCase issueApiKey,
                      ListApiKeysUseCase listApiKeys,
                      RevokeApiKeyUseCase revokeApiKey,
                      ApiKeyPresenter presenter) {
        this.issueApiKey = issueApiKey;
        this.listApiKeys = listApiKeys;
        this.revokeApiKey = revokeApiKey;
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
}
