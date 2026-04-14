/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.ApiKeyClientRepositoryPort;
import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.domain.model.ApiKeyClient;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;

import java.util.List;

/**
 * Lists clients that have used a specific API key.
 */
public final class ListApiKeyClientsUseCase {

    private final ApiKeyClientRepositoryPort clients;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param clients      API key client persistence port
     * @param callerAccess caller's project access resolver
     */
    public ListApiKeyClientsUseCase(ApiKeyClientRepositoryPort clients,
                                     CallerProjectAccessPort callerAccess) {
        this.clients = clients;
        this.callerAccess = callerAccess;
    }

    /**
     * Lists clients for a specific API key.
     *
     * @param projectId owning project identity
     * @param apiKeyId  the API key identity
     * @return list of clients ordered by last seen descending
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     */
    public List<ApiKeyClient> execute(ProjectId projectId, ApiKeyId apiKeyId) {
        callerAccess.resolve(projectId).ensure(Permission.MANAGE_MEMBERS);
        return clients.findByApiKey(apiKeyId);
    }
}
