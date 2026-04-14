/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.security;

import com.homni.togli.application.usecase.ResolveProjectAccessUseCase;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.ProjectAccess;
import com.homni.togli.domain.model.ProjectId;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;

/**
 * Authentication token for OIDC (JWT) users.
 * Carries the loaded {@link AppUser} for the duration of the request.
 */
public final class AppUserAuthentication extends AbstractAuthenticationToken
        implements ProjectAccessSource {

    public final AppUser user;
    private final String principal;

    /**
     * Creates an authenticated token for an OIDC user.
     *
     * @param user        the loaded user (cached for the request)
     * @param principal   the OIDC subject
     * @param authorities the platform-level authorities
     */
    public AppUserAuthentication(AppUser user, String principal,
                                 Collection<? extends GrantedAuthority> authorities) {
        super(authorities);
        this.user = user;
        this.principal = principal;
        setAuthenticated(true);
    }

    /** {@inheritDoc} */
    @Override
    public ProjectAccess resolveAccess(ProjectId projectId, ResolveProjectAccessUseCase resolver) {
        return resolver.resolve(this.user, projectId);
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
