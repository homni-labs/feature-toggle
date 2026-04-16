/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("ProjectInfo")
class ProjectInfoTest {

    @Test
    @DisplayName("creates with valid data")
    void createsWithValidData() {
        String id = UUID.randomUUID().toString();
        Instant now = Instant.now();

        ProjectInfo info = new ProjectInfo(id, "MY-SLUG", "My Project",
                Optional.of("desc"), false, now, Optional.empty());

        assertThat(info.id).isEqualTo(id);
        assertThat(info.slug).isEqualTo("MY-SLUG");
        assertThat(info.name).isEqualTo("My Project");
        assertThat(info.description).contains("desc");
        assertThat(info.archived).isFalse();
    }

    @Test
    @DisplayName("rejects blank id")
    void rejectsBlankId() {
        assertThatThrownBy(() -> new ProjectInfo("  ", "slug", "name",
                Optional.empty(), false, Instant.now(), Optional.empty()))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("rejects blank slug")
    void rejectsBlankSlug() {
        assertThatThrownBy(() -> new ProjectInfo("id", "  ", "name",
                Optional.empty(), false, Instant.now(), Optional.empty()))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("null description becomes empty Optional")
    void nullDescriptionBecomesEmpty() {
        ProjectInfo info = new ProjectInfo("id", "slug", "name",
                null, false, Instant.now(), null);

        assertThat(info.description).isEmpty();
        assertThat(info.updatedAt).isEmpty();
    }
}
