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
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;

import java.util.List;

/**
 * Lists all API key clients within a project.
 */
public final class ListProjectClientsUseCase {

    private final ApiKeyClientRepositoryPort clients;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param clients      API key client persistence port
     * @param callerAccess caller's project access resolver
     */
    public ListProjectClientsUseCase(ApiKeyClientRepositoryPort clients,
                                      CallerProjectAccessPort callerAccess) {
        this.clients = clients;
        this.callerAccess = callerAccess;
    }

    /**
     * Lists all clients in a project.
     *
     * @param projectId the project identity
     * @return list of clients ordered by last seen descending
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     */
    public List<ApiKeyClient> execute(ProjectId projectId) {
        callerAccess.resolve(projectId).ensure(Permission.MANAGE_MEMBERS);
        return clients.findByProject(projectId);
    }
}
