/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.domain.model.ApiKey;
import com.homni.featuretoggle.domain.model.ApiKeyId;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.TokenHash;

import java.util.List;
import java.util.Optional;

/**
 * Output port for persisting API keys scoped to a project.
 */
public interface ApiKeyRepositoryPort {

    /**
     * Saves an API key (insert or update).
     *
     * @param apiKey the API key to save
     */
    void save(ApiKey apiKey);

    /**
     * Finds an API key by identity.
     *
     * @param id API key identity
     * @return the API key if found, or empty
     */
    Optional<ApiKey> findById(ApiKeyId id);

    /**
     * Finds an API key by token hash.
     *
     * @param tokenHash SHA-256 hash of the raw token
     * @return the API key if found, or empty
     */
    Optional<ApiKey> findByTokenHash(TokenHash tokenHash);

    /**
     * Lists API keys for a project with pagination.
     *
     * @param projectId owning project identity
     * @param offset    rows to skip
     * @param limit     max rows to return
     * @return the matching API keys
     */
    List<ApiKey> findAllByProject(ProjectId projectId, int offset, int limit);

    /**
     * Counts API keys in a project.
     *
     * @param projectId owning project identity
     * @return total API key count
     */
    long countByProject(ProjectId projectId);

    /**
     * Deletes an API key by identity.
     *
     * @param id API key identity
     */
    void deleteById(ApiKeyId id);
}
