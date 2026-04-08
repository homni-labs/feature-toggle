/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.exception;

import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.UserId;

/**
 * Thrown when an operation requires project membership but the user is not a member.
 */
public final class NotProjectMemberException extends DomainAccessDeniedException {

    /**
     * Creates exception for a non-member accessing a project.
     *
     * @param projectId the project identity
     * @param userId    the user identity
     */
    public NotProjectMemberException(ProjectId projectId, UserId userId) {
        super("User [id=%s] is not a member of project [id=%s]".formatted(userId.value, projectId.value));
    }
}
