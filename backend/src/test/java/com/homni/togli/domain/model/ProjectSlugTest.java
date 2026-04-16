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
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static com.homni.togli.domain.model.TestFixtures.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for the {@link ProjectSlug} value object.
 *
 * <p>No mocks, no Spring context — pure domain logic.
 */
@DisplayName("ProjectSlug")
class ProjectSlugTest {

    @Test
    @DisplayName("normalizes to uppercase")
    void normalizesToUppercase() {
        String raw = "my-project-" + randomSuffix().toLowerCase();

        ProjectSlug slug = new ProjectSlug(raw);

        assertThat(slug.value()).isEqualTo(raw.toUpperCase());
    }

    @Test
    @DisplayName("rejects slug shorter than 2 characters")
    void rejectsTooShort() {
        assertThatThrownBy(() -> new ProjectSlug("A"))
                .isInstanceOf(DomainValidationException.class);
    }

    @Test
    @DisplayName("rejects slug longer than 50 characters")
    void rejectsTooLong() {
        String longSlug = "A" + "B".repeat(50);

        assertThatThrownBy(() -> new ProjectSlug(longSlug))
                .isInstanceOf(DomainValidationException.class);
    }

    @Test
    @DisplayName("rejects slug starting with digit")
    void rejectsStartingWithDigit() {
        assertThatThrownBy(() -> new ProjectSlug("1INVALID"))
                .isInstanceOf(DomainValidationException.class);
    }

    @Test
    @DisplayName("rejects slug with spaces")
    void rejectsSpaces() {
        assertThatThrownBy(() -> new ProjectSlug("MY PROJECT"))
                .isInstanceOf(DomainValidationException.class);
    }

    @Test
    @DisplayName("accepts hyphens and underscores")
    void acceptsHyphensAndUnderscores() {
        ProjectSlug slug = new ProjectSlug("MY-PROJECT_V2");

        assertThat(slug.value()).isEqualTo("MY-PROJECT_V2");
    }
}
