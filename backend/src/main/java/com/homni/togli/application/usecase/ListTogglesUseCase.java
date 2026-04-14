/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.application.usecase;

import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.application.port.out.FeatureToggleRepositoryPort;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;

import java.util.List;

/**
 * Lists feature toggles for a project with filtering and pagination.
 */
public final class ListTogglesUseCase {

    private final FeatureToggleRepositoryPort toggles;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param toggles      toggle persistence port
     * @param callerAccess caller's project access resolver
     */
    public ListTogglesUseCase(FeatureToggleRepositoryPort toggles,
                               CallerProjectAccessPort callerAccess) {
        this.toggles = toggles;
        this.callerAccess = callerAccess;
    }

    /**
     * Lists toggles in a project with optional filters.
     *
     * @param projectId   owning project identity
     * @param enabled     enabled filter, or {@code null}
     * @param environment environment filter, or {@code null}
     * @param page        zero-based page number
     * @param size        page size
     * @return a page of matching toggles
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks READ_TOGGLES
     */
    public TogglePage execute(ProjectId projectId, Boolean enabled, String environment,
                              int page, int size) {
        callerAccess.resolve(projectId).ensure(Permission.READ_TOGGLES);
        int offset = page * size;
        List<FeatureToggle> items = toggles.findAllByProject(projectId, enabled, environment,
                offset, size);
        long totalElements = toggles.countByProject(projectId, enabled, environment);
        return new TogglePage(items, totalElements);
    }
}
