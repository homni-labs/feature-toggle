/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.port.out;

import com.homni.featuretoggle.domain.model.ProjectAccess;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Resolves the caller's access level for a project.
 */
public interface CallerProjectAccessPort {

    /**
     * Resolves access for the current caller.
     *
     * @param projectId target project identity
     * @return the resolved project access
     * @throws com.homni.featuretoggle.domain.exception.NotProjectMemberException if the caller has no access
     */
    ProjectAccess resolve(ProjectId projectId);
}
