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
import com.homni.togli.application.usecase.UpdateUserUseCase;
import com.homni.togli.domain.exception.CannotModifySelfException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration tests for {@link UpdateUserUseCase}.
 */
@DisplayName("UpdateUser (integration)")
class UpdateUserIntegrationTest extends BaseIntegrationTest {

    @Autowired FindOrCreateUserUseCase findOrCreateUser;
    @Autowired UpdateUserUseCase updateUser;
    @Autowired AppUserRepositoryPort users;

    AppUser caller;
    AppUser target;

    @BeforeEach
    void setUp() {
        caller = findOrCreateUser.execute(
                "oidc-" + UUID.randomUUID(),
                "caller-" + randomSuffix().toLowerCase() + "@test.com", "Caller");
        caller.promoteToPlatformAdmin();
        users.save(caller);
        actAsAdmin(caller);

        target = findOrCreateUser.execute(
                "oidc-" + UUID.randomUUID(),
                "target-" + randomSuffix().toLowerCase() + "@test.com", "Target");
    }

    @Test
    @DisplayName("promotes user to PLATFORM_ADMIN in database")
    void promotesUser() {
        AppUser updated = updateUser.execute(target.id, PlatformRole.PLATFORM_ADMIN, null);

        assertThat(updated.isPlatformAdmin()).isTrue();
        AppUser fromDb = users.findById(target.id).orElseThrow();
        assertThat(fromDb.isPlatformAdmin()).isTrue();
    }

    @Test
    @DisplayName("disables user in database")
    void disablesUser() {
        AppUser updated = updateUser.execute(target.id, null, false);

        assertThat(updated.isActive()).isFalse();
        AppUser fromDb = users.findById(target.id).orElseThrow();
        assertThat(fromDb.isActive()).isFalse();
    }

    @Test
    @DisplayName("rejects self-modification")
    void rejectsSelfModification() {
        assertThatThrownBy(() -> updateUser.execute(caller.id, PlatformRole.USER, null))
                .isInstanceOf(CannotModifySelfException.class);
    }
}
