/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.port.out;

import com.homni.togli.application.usecase.ClientStats;
import com.homni.togli.domain.model.ApiKeyClient;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.ProjectId;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Output port for persisting API key client usage tracking.
 */
public interface ApiKeyClientRepositoryPort {

    /**
     * Inserts or updates a client tracking entry (upsert on unique key).
     *
     * @param client the API key client to upsert
     */
    void upsert(ApiKeyClient client);

    /**
     * Finds all clients that have used a given API key.
     *
     * @param apiKeyId the API key identity
     * @return list of clients ordered by last seen descending
     */
    List<ApiKeyClient> findByApiKey(ApiKeyId apiKeyId);

    /**
     * Finds all clients within a project.
     *
     * @param projectId the project identity
     * @return list of clients ordered by last seen descending
     */
    List<ApiKeyClient> findByProject(ProjectId projectId);

    /**
     * Counts distinct clients for a given API key.
     *
     * @param apiKeyId the API key identity
     * @return total client count
     */
    long countByApiKey(ApiKeyId apiKeyId);

    /**
     * Returns aggregated usage stats (lastUsedAt + clientCount) for each given API key.
     *
     * @param apiKeyIds the API key identities to aggregate
     * @return map of API key UUID to its stats (missing keys have no entry)
     */
    Map<UUID, ClientStats> statsByApiKeys(List<ApiKeyId> apiKeyIds);
}
