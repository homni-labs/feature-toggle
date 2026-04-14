/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.ApiKeyRepositoryPort;
import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.InvalidStateException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.Permission;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Permanently deletes a revoked API key from a project.
 * The key must already be revoked ({@code active=false}) before deletion.
 */
public final class DeleteApiKeyUseCase {

    private static final Logger log = LoggerFactory.getLogger(DeleteApiKeyUseCase.class);

    private final ApiKeyRepositoryPort apiKeys;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param apiKeys      API key persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public DeleteApiKeyUseCase(ApiKeyRepositoryPort apiKeys,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.apiKeys = apiKeys;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Permanently deletes a revoked API key.
     *
     * @param id API key identity
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the API key does not exist
     * @throws InvalidStateException if the API key is still active (not revoked)
     */
    public void execute(ApiKeyId id) {
        ApiKey apiKey = apiKeys.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("ApiKey", id.value));
        log.debug("Deleting API key permanently: id={}, project={}", id.value, apiKey.projectId.value);
        callerAccess.resolve(apiKey.projectId).ensure(Permission.MANAGE_MEMBERS);
        projects.findById(apiKey.projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", apiKey.projectId.value))
                .ensureNotArchived();
        if (apiKey.isActive()) {
            throw new InvalidStateException("API key must be revoked before deletion");
        }
        apiKeys.deleteById(id);
    }
}
