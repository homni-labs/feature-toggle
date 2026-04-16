/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.integration;

import com.homni.togli.application.port.out.ProjectMembershipRepositoryPort;
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.ProjectRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("ProjectMembershipJdbcAdapter")
class MembershipJdbcAdapterIntegrationTest extends BaseIntegrationTest {

    @Autowired ProjectMembershipRepositoryPort memberships;
    @Autowired ProjectRepositoryPort projects;
    @Autowired com.homni.togli.application.port.out.AppUserRepositoryPort users;

    private Project project;
    private AppUser user;

    @BeforeEach
    void setUp() {
        AppUser admin = adminUser();
        users.save(admin);
        actAsAdmin(admin);
        project = new Project(randomSlug(), "membership-test-" + randomSuffix(), null);
        projects.save(project);
        user = regularUser();
        users.save(user);
    }

    @Nested
    @DisplayName("findByProjectAndUser")
    class FindByProjectAndUser {

        @Test
        @DisplayName("finds membership for a specific project and user")
        void findsMembership() {
            ProjectMembership membership = new ProjectMembership(
                    project.id, user.id, ProjectRole.EDITOR);
            memberships.save(membership);

            Optional<ProjectMembership> found = memberships.findByProjectAndUser(project.id, user.id);
            assertThat(found).isPresent();
            assertThat(found.get().currentRole()).isEqualTo(ProjectRole.EDITOR);
        }

        @Test
        @DisplayName("returns empty for non-member")
        void returnsEmpty() {
            AppUser stranger = regularUser();
            Optional<ProjectMembership> found = memberships.findByProjectAndUser(project.id, stranger.id);
            assertThat(found).isEmpty();
        }
    }

    @Nested
    @DisplayName("findByProject (paginated with JOIN)")
    class FindByProject {

        @Test
        @DisplayName("returns members with user info from JOIN")
        void returnsMembersWithUserInfo() {
            ProjectMembership membership = new ProjectMembership(
                    project.id, user.id, ProjectRole.ADMIN);
            memberships.save(membership);

            List<ProjectMembership> page = memberships.findByProject(project.id, 0, 10);
            assertThat(page).hasSize(1);
            assertThat(page.get(0).email()).isPresent();
            assertThat(page.get(0).displayName()).isPresent().isNotEmpty();
        }

        @Test
        @DisplayName("paginates and counts correctly")
        void paginatesAndCounts() {
            AppUser user2 = regularUser();
            users.save(user2);
            memberships.save(new ProjectMembership(project.id, user.id, ProjectRole.EDITOR));
            memberships.save(new ProjectMembership(project.id, user2.id, ProjectRole.READER));

            List<ProjectMembership> firstPage = memberships.findByProject(project.id, 0, 1);
            assertThat(firstPage).hasSize(1);

            long total = memberships.countByProject(project.id);
            assertThat(total).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("deleteByProjectAndUser")
    class DeleteByProjectAndUser {

        @Test
        @DisplayName("deletes membership and confirms absence")
        void deletesMembership() {
            memberships.save(new ProjectMembership(project.id, user.id, ProjectRole.READER));

            memberships.deleteByProjectAndUser(project.id, user.id);

            assertThat(memberships.findByProjectAndUser(project.id, user.id)).isEmpty();
        }
    }
}
