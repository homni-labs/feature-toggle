/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.usecase.ResolveProjectAccessUseCase;
import com.homni.togli.domain.exception.DomainAccessDeniedException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformAdminAccess;
import com.homni.togli.domain.model.ProjectAccess;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.RoleBasedAccess;
import com.homni.togli.infrastructure.security.ApiKeyAuthentication;
import com.homni.togli.infrastructure.security.AppUserAuthentication;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for authentication token implementations:
 * {@link ApiKeyAuthentication} and {@link AppUserAuthentication}.
 */
@DisplayName("Authentication tokens")
class AuthenticationTokenTest {

    @Nested
    @DisplayName("ApiKeyAuthentication")
    class ApiKeyAuth {

        private final ProjectId projectId = new ProjectId();

        @Test
        @DisplayName("resolves RoleBasedAccess for matching project")
        void resolvesAccessForMatchingProject() {
            ApiKeyAuthentication auth = new ApiKeyAuthentication(
                    projectId, ProjectRole.READER, "apikey:test",
                    List.of(new SimpleGrantedAuthority("ROLE_READER")));

            ProjectAccess access = auth.resolveAccess(projectId, null);

            assertThat(access).isInstanceOf(RoleBasedAccess.class);
        }

        @Test
        @DisplayName("throws when project ID does not match")
        void throwsForMismatchedProject() {
            ApiKeyAuthentication auth = new ApiKeyAuthentication(
                    projectId, ProjectRole.READER, "apikey:test",
                    List.of(new SimpleGrantedAuthority("ROLE_READER")));
            ProjectId otherProject = new ProjectId();

            assertThatThrownBy(() -> auth.resolveAccess(otherProject, null))
                    .isInstanceOf(DomainAccessDeniedException.class)
                    .hasMessageContaining("API key belongs to project");
        }

        @Test
        @DisplayName("returns principal and null credentials")
        void returnsPrincipalAndCredentials() {
            ApiKeyAuthentication auth = new ApiKeyAuthentication(
                    projectId, ProjectRole.READER, "apikey:my-key",
                    List.of(new SimpleGrantedAuthority("ROLE_READER")));

            assertThat(auth.getPrincipal()).isEqualTo("apikey:my-key");
            assertThat(auth.getCredentials()).isNull();
            assertThat(auth.isAuthenticated()).isTrue();
        }
    }

    @Nested
    @DisplayName("AppUserAuthentication")
    class AppUserAuth {

        @Test
        @DisplayName("delegates access resolution to use case")
        void delegatesToResolver() {
            AppUser user = new AppUser("oidc-sub", "test@test.local", "User");
            AppUserAuthentication auth = new AppUserAuthentication(
                    user, "oidc-sub",
                    List.of(new SimpleGrantedAuthority("ROLE_USER")));

            ProjectId projectId = new ProjectId();
            ResolveProjectAccessUseCase resolver = mock(ResolveProjectAccessUseCase.class);
            when(resolver.resolve(user, projectId)).thenReturn(new PlatformAdminAccess());

            ProjectAccess access = auth.resolveAccess(projectId, resolver);

            assertThat(access).isInstanceOf(PlatformAdminAccess.class);
        }

        @Test
        @DisplayName("returns principal and null credentials")
        void returnsPrincipalAndCredentials() {
            AppUser user = new AppUser("oidc-sub", "test@test.local", "User");
            AppUserAuthentication auth = new AppUserAuthentication(
                    user, "oidc-sub",
                    List.of(new SimpleGrantedAuthority("ROLE_USER")));

            assertThat(auth.getPrincipal()).isEqualTo("oidc-sub");
            assertThat(auth.getCredentials()).isNull();
            assertThat(auth.isAuthenticated()).isTrue();
            assertThat(auth.user).isSameAs(user);
        }
    }
}
