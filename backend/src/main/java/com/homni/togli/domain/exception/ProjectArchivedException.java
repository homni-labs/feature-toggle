/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.exception;

import com.homni.togli.domain.model.ProjectId;

/**
 * Thrown when attempting to modify a project that has been archived.
 */
public final class ProjectArchivedException extends DomainConflictException {

    /**
     * Creates exception for modification of an archived project.
     *
     * @param id the archived project identity
     */
    public ProjectArchivedException(ProjectId id) {
        super("Project [id=%s] is archived and cannot be modified".formatted(id.value));
    }
}
