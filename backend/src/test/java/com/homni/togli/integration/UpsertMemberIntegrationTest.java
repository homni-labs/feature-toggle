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
import com.homni.togli.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.togli.application.usecase.CreateProjectUseCase;
import com.homni.togli.application.usecase.FindOrCreateUserUseCase;
import com.homni.togli.application.usecase.UpsertMemberUseCase;
import com.homni.togli.domain.exception.InsufficientPermissionException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.ProjectRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Integration tests for {@link UpsertMemberUseCase}.
 */
@DisplayName("UpsertMember (integration)")
class UpsertMemberIntegrationTest extends BaseIntegrationTest {

    @Autowired CreateProjectUseCase createProject;
    @Autowired FindOrCreateUserUseCase findOrCreateUser;
    @Autowired UpsertMemberUseCase upsertMember;
    @Autowired AppUserRepositoryPort users;
    @Autowired ProjectMembershipRepositoryPort memberships;

    AppUser admin;
    Project project;
    AppUser member;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        actAsAdmin(admin);
        project = createProject.execute(randomSlug(), "Project " + randomSuffix(), null, null);
        member = findOrCreateUser.execute(
                "oidc-" + UUID.randomUUID(),
                "member-" + randomSuffix().toLowerCase() + "@test.com", "Member");
    }

    @Test
    @DisplayName("adds new member to project in database")
    void addsNewMember() {
        ProjectMembership result = upsertMember.execute(project.id, member.id, ProjectRole.EDITOR);

        assertThat(result.projectId).isEqualTo(project.id);
        assertThat(result.userId).isEqualTo(member.id);
        assertThat(result.currentRole()).isEqualTo(ProjectRole.EDITOR);
        assertThat(memberships.findByProjectAndUser(project.id, member.id)).isPresent();
    }

    @Test
    @DisplayName("updates existing member role in database")
    void updatesRole() {
        upsertMember.execute(project.id, member.id, ProjectRole.READER);

        ProjectMembership updated = upsertMember.execute(project.id, member.id, ProjectRole.ADMIN);

        assertThat(updated.currentRole()).isEqualTo(ProjectRole.ADMIN);
        ProjectMembership fromDb = memberships.findByProjectAndUser(project.id, member.id).orElseThrow();
        assertThat(fromDb.currentRole()).isEqualTo(ProjectRole.ADMIN);
    }

    @Test
    @DisplayName("rejects upsert when caller has only EDITOR role")
    void rejectsInsufficientPermission() {
        AppUser editor = regularUser();
        actAsMember(editor, project.id, ProjectRole.EDITOR);

        assertThatThrownBy(() -> upsertMember.execute(project.id, member.id, ProjectRole.READER))
                .isInstanceOf(InsufficientPermissionException.class);
    }
}
