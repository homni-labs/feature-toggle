/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.security;

import com.homni.togli.application.port.out.CallerProjectAccessPort;
import com.homni.togli.application.usecase.ResolveProjectAccessUseCase;
import com.homni.togli.domain.model.ProjectAccess;
import com.homni.togli.domain.model.ProjectId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * Resolves the currently authenticated caller's project access from the Spring Security context.
 * Delegates membership resolution to {@link ResolveProjectAccessUseCase}.
 */
@Component
public class CallerProjectAccessAdapter implements CallerProjectAccessPort {

    private static final Logger log = LoggerFactory.getLogger(CallerProjectAccessAdapter.class);

    private final ResolveProjectAccessUseCase resolveProjectAccess;

    /**
     * Creates a caller project access adapter.
     *
     * @param resolveProjectAccess the use case for membership-based access resolution
     */
    public CallerProjectAccessAdapter(ResolveProjectAccessUseCase resolveProjectAccess) {
        this.resolveProjectAccess = resolveProjectAccess;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public ProjectAccess resolve(ProjectId projectId) {
        ProjectAccessSource source =
                (ProjectAccessSource) SecurityContextHolder.getContext().getAuthentication();
        ProjectAccess access = source.resolveAccess(projectId, resolveProjectAccess);
        log.debug("Resolved project access: projectId={}, access={}", projectId.value, access);
        return access;
    }
}
