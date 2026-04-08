/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.security;

import com.homni.featuretoggle.application.usecase.ResolveProjectAccessUseCase;
import com.homni.featuretoggle.domain.model.ProjectAccess;
import com.homni.featuretoggle.domain.model.ProjectId;

/**
 * Each authentication type resolves project access in its own way.
 * JWT users go through membership lookup; API keys carry the project role directly.
 */
public sealed interface ProjectAccessSource
        permits AppUserAuthentication, ApiKeyAuthentication {

    /**
     * Resolves the project access level for this authentication.
     *
     * @param projectId the target project
     * @param resolver  the use-case for membership-based resolution
     * @return the resolved project access
     */
    ProjectAccess resolveAccess(ProjectId projectId, ResolveProjectAccessUseCase resolver);
}
