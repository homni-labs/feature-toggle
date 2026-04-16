/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.application.port.out.AppUserRepositoryPort;
import com.homni.togli.application.usecase.FindOrCreateUserUseCase;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for {@link FindOrCreateUserUseCase}.
 */
@DisplayName("FindOrCreateUser (integration)")
class FindOrCreateUserIntegrationTest extends BaseIntegrationTest {

    @Autowired FindOrCreateUserUseCase findOrCreateUser;
    @Autowired AppUserRepositoryPort users;

    @Test
    @DisplayName("creates new user in database on first login")
    void createsNewUser() {
        String oidcSubject = "oidc-" + UUID.randomUUID();
        String email = "new-" + randomSuffix().toLowerCase() + "@test.com";

        AppUser user = findOrCreateUser.execute(oidcSubject, email, "New User");

        assertThat(user.id).isNotNull();
        assertThat(users.findByOidcSubject(oidcSubject)).isPresent();
    }

    @Test
    @DisplayName("returns existing user by OIDC subject")
    void returnsExistingBySubject() {
        String oidcSubject = "oidc-" + UUID.randomUUID();
        String email = "existing-" + randomSuffix().toLowerCase() + "@test.com";
        AppUser created = findOrCreateUser.execute(oidcSubject, email, "Existing");

        AppUser found = findOrCreateUser.execute(oidcSubject, email, "Existing");

        assertThat(found.id).isEqualTo(created.id);
    }

    @Test
    @DisplayName("binds OIDC subject to pre-provisioned user found by email")
    void bindsOidcToPreProvisionedUser() {
        String email = "provision-" + randomSuffix().toLowerCase() + "@test.com";
        AppUser preProvisioned = new AppUser(email, "Pre-Provisioned", PlatformRole.USER);
        users.save(preProvisioned);

        String oidcSubject = "oidc-" + UUID.randomUUID();
        AppUser bound = findOrCreateUser.execute(oidcSubject, email, "Pre-Provisioned");

        assertThat(bound.id).isEqualTo(preProvisioned.id);
        assertThat(bound.oidcSubject()).contains(oidcSubject);
    }

    @Test
    @DisplayName("promotes default admin email to PLATFORM_ADMIN")
    void promotesDefaultAdmin() {
        String oidcSubject = "oidc-" + UUID.randomUUID();

        AppUser admin = findOrCreateUser.execute(oidcSubject, "admin@test.local", "Admin");

        assertThat(admin.isPlatformAdmin()).isTrue();
    }
}
