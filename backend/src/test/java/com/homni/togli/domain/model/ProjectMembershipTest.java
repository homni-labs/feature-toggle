/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link ProjectMembership} aggregate.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("ProjectMembership")
class ProjectMembershipTest {

    @Test
    @DisplayName("creation assigns role and sets grantedAt")
    void creationAssignsRole() {
        ProjectId projectId = new ProjectId();
        UserId userId = new UserId();

        ProjectMembership membership = new ProjectMembership(projectId, userId, ProjectRole.EDITOR);

        assertThat(membership.id).isNotNull();
        assertThat(membership.projectId).isEqualTo(projectId);
        assertThat(membership.userId).isEqualTo(userId);
        assertThat(membership.currentRole()).isEqualTo(ProjectRole.EDITOR);
        assertThat(membership.grantedAt).isNotNull();
        assertThat(membership.lastModifiedAt()).isEmpty();
    }

    @Test
    @DisplayName("changeRole updates role and bumps updatedAt")
    void changeRoleUpdates() {
        ProjectMembership membership = new ProjectMembership(new ProjectId(), new UserId(), ProjectRole.READER);

        membership.changeRole(ProjectRole.ADMIN);

        assertThat(membership.currentRole()).isEqualTo(ProjectRole.ADMIN);
        assertThat(membership.lastModifiedAt()).isPresent();
    }

    @Test
    @DisplayName("changeRole rejects null")
    void changeRoleRejectsNull() {
        ProjectMembership membership = new ProjectMembership(new ProjectId(), new UserId(), ProjectRole.READER);

        assertThatThrownBy(() -> membership.changeRole(null))
                .isInstanceOf(NullPointerException.class);
    }
}
