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
import com.homni.featuretoggle.domain.exception.DomainAccessDeniedException;
import com.homni.featuretoggle.domain.model.ProjectAccess;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.domain.model.ProjectRole;
import com.homni.featuretoggle.domain.model.RoleBasedAccess;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;

/**
 * Authentication token for API key access.
 * Carries the project ID and role from the API key directly.
 */
public final class ApiKeyAuthentication extends AbstractAuthenticationToken
        implements ProjectAccessSource {

    public final ProjectId projectId;
    public final ProjectRole projectRole;
    private final String principal;

    /**
     * Creates an authenticated token for an API key.
     *
     * @param projectId   the project this key belongs to
     * @param projectRole the role this key grants
     * @param principal   the key identity string
     * @param authorities the granted authorities
     */
    public ApiKeyAuthentication(ProjectId projectId, ProjectRole projectRole,
                                String principal,
                                Collection<? extends GrantedAuthority> authorities) {
        super(authorities);
        this.projectId = projectId;
        this.projectRole = projectRole;
        this.principal = principal;
        setAuthenticated(true);
    }

    /** {@inheritDoc} */
    @Override
    public ProjectAccess resolveAccess(ProjectId requestProjectId,
                                       ResolveProjectAccessUseCase resolver) {
        if (!this.projectId.equals(requestProjectId)) {
            throw new DomainAccessDeniedException("API key belongs to project [id=%s] but request targets project [id=%s]".formatted(this.projectId.value, requestProjectId.value));
        }
        return new RoleBasedAccess(requestProjectId, this.projectRole);
    }

    /** {@inheritDoc} */
    @Override
    public Object getPrincipal() {
        return principal;
    }

    /** {@inheritDoc} */
    @Override
    public Object getCredentials() {
        return null;
    }
}
