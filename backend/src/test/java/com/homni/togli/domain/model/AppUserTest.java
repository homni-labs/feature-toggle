/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.InvalidStateException;
import com.homni.togli.domain.exception.NotProjectMemberException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link AppUser} aggregate.
 *
 * <p>Covers creation defaults, role promotion/demotion state machine,
 * active/disabled lifecycle, OIDC subject binding, and project access resolution.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("AppUser")
class AppUserTest {

    @Nested
    @DisplayName("creation")
    class Creation {

        @Test
        @DisplayName("new user starts as active USER with OIDC subject")
        void newUserIsActiveUser() {
            String oidcSubject = randomOidcSubject();
            String email = randomEmail();
            String displayName = randomName();

            AppUser user = new AppUser(oidcSubject, email, displayName);

            assertThat(user.id).isNotNull();
            assertThat(user.email.value()).isEqualTo(email.toLowerCase());
            assertThat(user.platformRole()).isEqualTo(PlatformRole.USER);
            assertThat(user.isActive()).isTrue();
            assertThat(user.oidcSubject()).contains(oidcSubject);
            assertThat(user.displayName()).contains(displayName);
            assertThat(user.canAuthenticate()).isTrue();
        }

        @Test
        @DisplayName("pre-provisioned user has no OIDC subject and can bind later")
        void preProvisionedUserCanBindOidc() {
            AppUser user = new AppUser(randomEmail(), randomName(), PlatformRole.USER);

            assertThat(user.oidcSubject()).isEmpty();
            assertThat(user.canBindOidc()).isTrue();
        }
    }

    @Nested
    @DisplayName("role transitions")
    class RoleTransitions {

        @Test
        @DisplayName("promotes USER to PLATFORM_ADMIN")
        void promotesToAdmin() {
            AppUser user = newUser();

            user.promoteToPlatformAdmin();

            assertThat(user.isPlatformAdmin()).isTrue();
            assertThat(user.platformRole()).isEqualTo(PlatformRole.PLATFORM_ADMIN);
            assertThat(user.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("rejects promoting already PLATFORM_ADMIN")
        void rejectsDoublePromotion() {
            AppUser user = newUser();
            user.promoteToPlatformAdmin();

            assertThatThrownBy(user::promoteToPlatformAdmin)
                    .isInstanceOf(InvalidStateException.class);
        }

        @Test
        @DisplayName("demotes PLATFORM_ADMIN to USER")
        void demotesToUser() {
            AppUser user = newUser();
            user.promoteToPlatformAdmin();

            user.demoteToUser();

            assertThat(user.isPlatformAdmin()).isFalse();
            assertThat(user.platformRole()).isEqualTo(PlatformRole.USER);
        }

        @Test
        @DisplayName("rejects demoting already USER")
        void rejectsDemotionOfUser() {
            AppUser user = newUser();

            assertThatThrownBy(user::demoteToUser)
                    .isInstanceOf(InvalidStateException.class);
        }

        @Test
        @DisplayName("full cycle: USER -> ADMIN -> USER")
        void fullRoleCycle() {
            AppUser user = newUser();

            user.promoteToPlatformAdmin();
            assertThat(user.isPlatformAdmin()).isTrue();

            user.demoteToUser();
            assertThat(user.isPlatformAdmin()).isFalse();
        }
    }

    @Nested
    @DisplayName("active / disabled")
    class ActiveDisabled {

        @Test
        @DisplayName("disables an active user")
        void disablesActiveUser() {
            AppUser user = newUser();

            user.disable();

            assertThat(user.isActive()).isFalse();
            assertThat(user.canAuthenticate()).isFalse();
            assertThat(user.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("rejects disabling already disabled user")
        void rejectsDoubleDisable() {
            AppUser user = newUser();
            user.disable();

            assertThatThrownBy(user::disable)
                    .isInstanceOf(InvalidStateException.class);
        }

        @Test
        @DisplayName("activates a disabled user")
        void activatesDisabledUser() {
            AppUser user = newUser();
            user.disable();

            user.activate();

            assertThat(user.isActive()).isTrue();
            assertThat(user.canAuthenticate()).isTrue();
        }

        @Test
        @DisplayName("rejects activating already active user")
        void rejectsDoubleActivate() {
            AppUser user = newUser();

            assertThatThrownBy(user::activate)
                    .isInstanceOf(InvalidStateException.class);
        }
    }

    @Nested
    @DisplayName("bindOidcSubject")
    class BindOidcSubject {

        @Test
        @DisplayName("binds OIDC subject to pre-provisioned user")
        void bindsSubject() {
            AppUser user = new AppUser(randomEmail(), randomName(), PlatformRole.USER);
            String subject = randomOidcSubject();

            user.bindOidcSubject(subject);

            assertThat(user.oidcSubject()).contains(subject);
            assertThat(user.canBindOidc()).isFalse();
            assertThat(user.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("rejects binding when OIDC subject already bound")
        void rejectsDoubleBind() {
            AppUser user = newUser();

            assertThatThrownBy(() -> user.bindOidcSubject(randomOidcSubject()))
                    .isInstanceOf(InvalidStateException.class);
        }
    }

    @Nested
    @DisplayName("accessFor")
    class AccessFor {

        @Test
        @DisplayName("PLATFORM_ADMIN gets PlatformAdminAccess regardless of membership")
        void adminGetsPlatformAccess() {
            AppUser admin = newUser();
            admin.promoteToPlatformAdmin();

            ProjectAccess access = admin.accessFor(new ProjectId(), Optional.empty());

            assertThat(access).isInstanceOf(PlatformAdminAccess.class);
        }

        @Test
        @DisplayName("USER with membership gets RoleBasedAccess")
        void userWithMembershipGetsRoleAccess() {
            AppUser user = newUser();
            ProjectId projectId = new ProjectId();
            ProjectMembership membership = new ProjectMembership(projectId, user.id, ProjectRole.EDITOR);

            ProjectAccess access = user.accessFor(projectId, Optional.of(membership));

            assertThat(access).isInstanceOf(RoleBasedAccess.class);
        }

        @Test
        @DisplayName("USER without membership throws NotProjectMemberException")
        void userWithoutMembershipThrows() {
            AppUser user = newUser();
            ProjectId projectId = new ProjectId();

            assertThatThrownBy(() -> user.accessFor(projectId, Optional.empty()))
                    .isInstanceOf(NotProjectMemberException.class);
        }
    }

    private static AppUser newUser() {
        return new AppUser(randomOidcSubject(), randomEmail(), randomName());
    }
}
