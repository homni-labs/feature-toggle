/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.application.port.out.CallerProjectAccessPort;
import com.homni.featuretoggle.application.port.out.EnvironmentRepositoryPort;
import com.homni.featuretoggle.domain.model.Environment;
import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.ProjectId;

import java.util.List;

/**
 * Lists environments for a project with pagination.
 */
public final class ListEnvironmentsUseCase {

    private final EnvironmentRepositoryPort environments;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param environments environment persistence port
     * @param callerAccess caller's project access resolver
     */
    public ListEnvironmentsUseCase(EnvironmentRepositoryPort environments,
                                    CallerProjectAccessPort callerAccess) {
        this.environments = environments;
        this.callerAccess = callerAccess;
    }

    /**
     * Lists environments in a project with pagination.
     *
     * @param projectId owning project identity
     * @param page      zero-based page number
     * @param size      page size
     * @return a page of environments
     * @throws com.homni.featuretoggle.domain.exception.InsufficientPermissionException if access lacks READ_TOGGLES
     */
    public EnvironmentPage execute(ProjectId projectId, int page, int size) {
        callerAccess.resolve(projectId).ensure(Permission.READ_TOGGLES);
        int offset = page * size;
        List<Environment> items = environments.findAllByProject(projectId, offset, size);
        long totalElements = environments.countByProject(projectId);
        return new EnvironmentPage(items, totalElements);
    }
}
