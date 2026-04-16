/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.InsufficientPermissionException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatNoException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link RoleBasedAccess} strategy.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("RoleBasedAccess")
class RoleBasedAccessTest {

    private final ProjectId projectId = new ProjectId();

    @Test
    @DisplayName("ADMIN has all permissions")
    void adminHasAllPermissions() {
        RoleBasedAccess access = new RoleBasedAccess(projectId, ProjectRole.ADMIN);

        for (Permission permission : Permission.values()) {
            assertThatNoException().isThrownBy(() -> access.ensure(permission));
        }
    }

    @Test
    @DisplayName("EDITOR has READ and WRITE but not MANAGE_MEMBERS")
    void editorHasReadAndWrite() {
        RoleBasedAccess access = new RoleBasedAccess(projectId, ProjectRole.EDITOR);

        assertThatNoException().isThrownBy(() -> access.ensure(Permission.READ_TOGGLES));
        assertThatNoException().isThrownBy(() -> access.ensure(Permission.WRITE_TOGGLES));
        assertThatThrownBy(() -> access.ensure(Permission.MANAGE_MEMBERS))
                .isInstanceOf(InsufficientPermissionException.class);
    }

    @Test
    @DisplayName("READER has only READ")
    void readerHasOnlyRead() {
        RoleBasedAccess access = new RoleBasedAccess(projectId, ProjectRole.READER);

        assertThatNoException().isThrownBy(() -> access.ensure(Permission.READ_TOGGLES));
        assertThatThrownBy(() -> access.ensure(Permission.WRITE_TOGGLES))
                .isInstanceOf(InsufficientPermissionException.class);
        assertThatThrownBy(() -> access.ensure(Permission.MANAGE_MEMBERS))
                .isInstanceOf(InsufficientPermissionException.class);
    }
}
