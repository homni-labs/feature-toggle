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
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.FeatureToggleId;
import com.homni.togli.domain.model.Permission;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Deletes a feature toggle from a project.
 */
public final class DeleteToggleUseCase {

    private static final Logger log = LoggerFactory.getLogger(DeleteToggleUseCase.class);

    private final FeatureToggleRepositoryPort toggles;
    private final ProjectRepositoryPort projects;
    private final CallerProjectAccessPort callerAccess;

    /**
     * @param toggles      toggle persistence port
     * @param projects     project persistence port
     * @param callerAccess caller's project access resolver
     */
    public DeleteToggleUseCase(FeatureToggleRepositoryPort toggles,
                               ProjectRepositoryPort projects,
                               CallerProjectAccessPort callerAccess) {
        this.toggles = toggles;
        this.projects = projects;
        this.callerAccess = callerAccess;
    }

    /**
     * Deletes a feature toggle.
     *
     * @param id toggle identity
     * @throws com.homni.togli.domain.exception.InsufficientPermissionException if access lacks WRITE_TOGGLES
     * @throws ProjectArchivedException if the project is archived
     * @throws EntityNotFoundException if the toggle does not exist
     */
    public void execute(FeatureToggleId id) {
        FeatureToggle toggle = toggles.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Toggle", id.value));
        log.debug("Deleting toggle: id={}, project={}", id.value, toggle.projectId.value);
        callerAccess.resolve(toggle.projectId).ensure(Permission.WRITE_TOGGLES);
        projects.findById(toggle.projectId)
                .orElseThrow(() -> new EntityNotFoundException("Project", toggle.projectId.value))
                .ensureNotArchived();
        toggles.deleteById(id);
    }
}
