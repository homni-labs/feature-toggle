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
import com.homni.togli.application.port.out.ProjectRepositoryPort;
import com.homni.togli.application.usecase.ProjectListItem;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import com.homni.togli.domain.model.Project;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.ProjectSlug;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("ProjectJdbcAdapter — visibility, search, and pagination")
class ProjectJdbcAdapterIntegrationTest extends BaseIntegrationTest {

    @Autowired ProjectRepositoryPort projects;
    @Autowired AppUserRepositoryPort users;
    @Autowired ProjectMembershipRepositoryPort memberships;

    private AppUser admin;
    private AppUser member;

    @BeforeEach
    void setUp() {
        admin = adminUser();
        users.save(admin);
        member = regularUser();
        users.save(member);
    }

    @Nested
    @DisplayName("findPage visibility")
    class FindPageVisibility {

        @Test
        @DisplayName("platform admin sees all projects")
        void adminSeesAll() {
            Project p1 = new Project(randomSlug(), "visible-" + randomSuffix(), null);
            Project p2 = new Project(randomSlug(), "other-" + randomSuffix(), null);
            projects.save(p1);
            projects.save(p2);

            List<ProjectListItem> items = projects.findPage(
                    admin.id, true, null, null, 0, 100);
            assertThat(items).extracting(i -> i.project().id)
                    .contains(p1.id, p2.id);
        }

        @Test
        @DisplayName("member sees only projects they belong to")
        void memberSeesOwnProjects() {
            Project mine = new Project(randomSlug(), "mine-" + randomSuffix(), null);
            Project other = new Project(randomSlug(), "other-" + randomSuffix(), null);
            projects.save(mine);
            projects.save(other);
            memberships.save(new ProjectMembership(mine.id, member.id, ProjectRole.EDITOR));

            List<ProjectListItem> items = projects.findPage(
                    member.id, false, null, null, 0, 100);
            List<Object> projectIds = items.stream()
                    .map(i -> (Object) i.project().id).toList();
            assertThat(projectIds).contains(mine.id);
            assertThat(projectIds).doesNotContain(other.id);
        }
    }

    @Nested
    @DisplayName("findPage search and filter")
    class FindPageFilters {

        @Test
        @DisplayName("filters by search text on name")
        void searchByName() {
            String unique = "Unicorn" + randomSuffix();
            Project match = new Project(randomSlug(), unique, null);
            Project noMatch = new Project(randomSlug(), "boring-" + randomSuffix(), null);
            projects.save(match);
            projects.save(noMatch);

            List<ProjectListItem> items = projects.findPage(
                    admin.id, true, "unicorn", null, 0, 100);
            assertThat(items).extracting(i -> i.project().id).contains(match.id);
            assertThat(items).extracting(i -> i.project().id).doesNotContain(noMatch.id);
        }

        @Test
        @DisplayName("filters by archived flag")
        void filterArchived() {
            Project active = new Project(randomSlug(), "active-" + randomSuffix(), null);
            Project archived = new Project(randomSlug(), "archived-" + randomSuffix(), null);
            projects.save(active);
            archived.archive();
            projects.save(archived);

            List<ProjectListItem> onlyArchived = projects.findPage(
                    admin.id, true, null, true, 0, 100);
            assertThat(onlyArchived).extracting(i -> i.project().id).contains(archived.id);
            assertThat(onlyArchived).extracting(i -> i.project().id).doesNotContain(active.id);
        }
    }

    @Nested
    @DisplayName("findBySlug")
    class FindBySlug {

        @Test
        @DisplayName("finds project by slug")
        void findsProject() {
            ProjectSlug slug = randomSlug();
            Project project = new Project(slug, "slug-test", null);
            projects.save(project);

            Optional<Project> found = projects.findBySlug(slug);
            assertThat(found).isPresent();
            assertThat(found.get().name()).isEqualTo("slug-test");
        }

        @Test
        @DisplayName("returns empty for unknown slug")
        void returnsEmptyForUnknown() {
            Optional<Project> found = projects.findBySlug(new ProjectSlug("NONEXISTENT"));
            assertThat(found).isEmpty();
        }
    }
}
