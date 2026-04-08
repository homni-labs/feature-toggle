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
import com.homni.featuretoggle.domain.model.ApiKey;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.ProjectId;

import java.util.List;

/**
 * Lists API keys for a project with pagination.
 */
public final class ListApiKeysUseCase {

    private final ApiKeyRepositoryPort apiKeys;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param apiKeys      API key persistence port
     * @param callerAccess caller's project access resolver
     */
    public ListApiKeysUseCase(ApiKeyRepositoryPort apiKeys,
                               CallerProjectAccessPort callerAccess) {
        this.apiKeys = apiKeys;
        this.callerAccess = callerAccess;
    }

    /**
     * Lists API keys for a project.
     *
     * @param projectId owning project identity
     * @param page      zero-based page number
     * @param size      page size
     * @return a page of API keys
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks MANAGE_MEMBERS
     */
    public ApiKeyPage execute(ProjectId projectId, int page, int size) {
        callerAccess.resolve(projectId).ensure(Permission.MANAGE_MEMBERS);
        int offset = page * size;
        List<ApiKey> items = apiKeys.findAllByProject(projectId, offset, size);
        long totalElements = apiKeys.countByProject(projectId);
        return new ApiKeyPage(items, totalElements);
    }
}
