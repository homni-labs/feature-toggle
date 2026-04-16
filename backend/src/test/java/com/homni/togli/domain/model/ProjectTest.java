/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.DomainValidationException;
import com.homni.togli.domain.exception.InvalidStateException;
import com.homni.togli.domain.exception.ProjectArchivedException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link Project} aggregate.
 *
 * <p>Covers constructor invariants, archive/unarchive state machine,
 * partial update with no-op detection, and the {@code ensureNotArchived} guard.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("Project")
class ProjectTest {

    @Nested
    @DisplayName("creation")
    class Creation {

        @Test
        @DisplayName("succeeds with valid slug, name and description")
        void succeedsWithValidData() {
            String name = randomName();
            String description = randomDescription();
            ProjectSlug slug = randomSlug();

            Project project = new Project(slug, name, description);

            assertThat(project.id).isNotNull();
            assertThat(project.slug).isEqualTo(slug);
            assertThat(project.name()).isEqualTo(name);
            assertThat(project.description()).contains(description);
            assertThat(project.isArchived()).isFalse();
            assertThat(project.createdAt).isNotNull();
            assertThat(project.lastModifiedAt()).isEmpty();
        }

        @Test
        @DisplayName("rejects blank name")
        void rejectsBlankName() {
            assertThatThrownBy(() -> new Project(randomSlug(), "  ", null))
                    .isInstanceOf(DomainValidationException.class);
        }

        @Test
        @DisplayName("rejects name exceeding 255 characters")
        void rejectsLongName() {
            String longName = randomName() + "x".repeat(256);

            assertThatThrownBy(() -> new Project(randomSlug(), longName, null))
                    .isInstanceOf(DomainValidationException.class);
        }
    }

    @Nested
    @DisplayName("archive / unarchive")
    class ArchiveUnarchive {

        @Test
        @DisplayName("archives an active project")
        void archivesActiveProject() {
            Project project = newProject();

            project.archive();

            assertThat(project.isArchived()).isTrue();
            assertThat(project.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("rejects archiving an already archived project")
        void rejectsDoubleArchive() {
            Project project = newProject();
            project.archive();

            assertThatThrownBy(project::archive)
                    .isInstanceOf(InvalidStateException.class);
        }

        @Test
        @DisplayName("unarchives an archived project")
        void unarchivesArchivedProject() {
            Project project = newProject();
            project.archive();

            project.unarchive();

            assertThat(project.isArchived()).isFalse();
        }

        @Test
        @DisplayName("rejects unarchiving an active project")
        void rejectsUnarchiveOnActive() {
            Project project = newProject();

            assertThatThrownBy(project::unarchive)
                    .isInstanceOf(InvalidStateException.class);
        }

        @Test
        @DisplayName("full cycle: active -> archived -> active")
        void fullCycle() {
            Project project = newProject();

            project.archive();
            assertThat(project.isArchived()).isTrue();

            project.unarchive();
            assertThat(project.isArchived()).isFalse();
        }
    }

    @Nested
    @DisplayName("ensureNotArchived")
    class EnsureNotArchived {

        @Test
        @DisplayName("passes silently for active project")
        void passesSilentlyForActiveProject() {
            Project project = newProject();

            project.ensureNotArchived();
        }

        @Test
        @DisplayName("throws ProjectArchivedException for archived project")
        void throwsForArchivedProject() {
            Project project = newProject();
            project.archive();

            assertThatThrownBy(project::ensureNotArchived)
                    .isInstanceOf(ProjectArchivedException.class);
        }
    }

    @Nested
    @DisplayName("update")
    class Update {

        @Test
        @DisplayName("renames project")
        void renamesProject() {
            Project project = newProject();
            String newName = randomName();

            project.update(newName, null);

            assertThat(project.name()).isEqualTo(newName);
            assertThat(project.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("updates description")
        void updatesDescription() {
            Project project = newProject();
            String newDesc = randomDescription();

            project.update(null, newDesc);

            assertThat(project.description()).contains(newDesc);
            assertThat(project.lastModifiedAt()).isPresent();
        }

        @Test
        @DisplayName("all-null is a no-op — updatedAt stays empty")
        void allNullIsNoOp() {
            Project project = newProject();

            project.update(null, null);

            assertThat(project.lastModifiedAt()).isEmpty();
        }

        @Test
        @DisplayName("same name is a no-op — updatedAt stays empty")
        void sameNameIsNoOp() {
            Project project = newProject();
            String currentName = project.name();

            project.update(currentName, null);

            assertThat(project.lastModifiedAt()).isEmpty();
        }

        @Test
        @DisplayName("rejects blank new name")
        void rejectsBlankNewName() {
            Project project = newProject();

            assertThatThrownBy(() -> project.update("  ", null))
                    .isInstanceOf(DomainValidationException.class);
        }
    }

    private static Project newProject() {
        return new Project(randomSlug(), randomName(), randomDescription());
    }
}
