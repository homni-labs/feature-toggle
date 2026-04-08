/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.exception;

import com.homni.featuretoggle.domain.model.Permission;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Thrown when a user lacks a required permission on a project.
 */
public final class InsufficientPermissionException extends DomainAccessDeniedException {

    /**
     * Creates exception for a missing project permission.
     *
     * @param projectId  the project identity
     * @param permission the missing permission
     */
    public InsufficientPermissionException(ProjectId projectId, Permission permission) {
        super("Insufficient permission '%s' on project [id=%s]".formatted(permission, projectId.value));
    }
}
