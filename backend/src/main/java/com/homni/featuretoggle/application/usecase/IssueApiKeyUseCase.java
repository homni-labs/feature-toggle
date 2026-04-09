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
import com.homni.featuretoggle.domain.model.IssuedApiKey;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.ProjectId;

import java.time.Instant;

/**
 * Issues a read-only API key bound to a project.
 */
public final class IssueApiKeyUseCase {

    private final ApiKeyRepositoryPort apiKeys;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param apiKeys      API key persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public IssueApiKeyUseCase(ApiKeyRepositoryPort apiKeys,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.apiKeys = apiKeys;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Issues a read-only API key for the project.
     *
     * @param projectId owning project identity
     * @param name      key name (1-255 chars)
     * @param expiresAt expiration, or {@code null}
     * @return the issued key with raw token
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws ProjectArchivedException if the project is archived
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if the name is invalid
     */
    public IssuedApiKey execute(ProjectId projectId, String name, Instant expiresAt) {
        callerAccess.resolve(projectId).ensure(Permission.MANAGE_MEMBERS);
        projects.findById(projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", projectId.value))
                .ensureNotArchived();
        IssuedApiKey issued = new IssuedApiKey(projectId, name, expiresAt);
        apiKeys.save(issued.apiKey);
        return issued;
    }
}
