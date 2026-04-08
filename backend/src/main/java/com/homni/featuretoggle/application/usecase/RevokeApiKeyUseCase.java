/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.ApiKeyRepositoryPort;
import com.homni.featuretoggle.application.port.out.CallerProjectAccessPort;
import com.homni.featuretoggle.application.port.out.ProjectRepositoryPort;
import com.homni.featuretoggle.domain.exception.EntityNotFoundException;
import com.homni.featuretoggle.domain.exception.ProjectArchivedException;
import com.homni.featuretoggle.domain.model.ApiKey;
import com.homni.featuretoggle.domain.model.ApiKeyId;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Revokes an API key within a project.
 */
public final class RevokeApiKeyUseCase {

    private final ApiKeyRepositoryPort apiKeys;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param apiKeys      API key persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public RevokeApiKeyUseCase(ApiKeyRepositoryPort apiKeys,
                                ProjectRepositoryPort projects,
                                CallerProjectAccessPort callerAccess) {
        this.apiKeys = apiKeys;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Revokes an API key.
     *
     * @param id API key identity
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the API key does not exist
     * @throws com.homni.featuretoggle.domain.exception.InvalidStateException if already revoked
     */
    public void execute(ApiKeyId id) {
        ApiKey apiKey = apiKeys.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("ApiKey", id.value));
        callerAccess.resolve(apiKey.projectId).ensure(Permission.MANAGE_MEMBERS);
        ensureProjectNotArchived(apiKey.projectId);
        apiKey.revoke();
        apiKeys.save(apiKey);
    }

    private void ensureProjectNotArchived(ProjectId projectId) {
        Project project = projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value));
        if (project.isArchived()) {
            throw new ProjectArchivedException(projectId);
        }
    }
}
