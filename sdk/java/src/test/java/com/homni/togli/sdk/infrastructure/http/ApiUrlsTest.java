/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.http;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("ApiUrls")
class ApiUrlsTest {

    @Test
    @DisplayName("builds project-by-slug URL")
    void buildsProjectBySlugUrl() {
        ApiUrls urls = new ApiUrls("http://api.example.com");

        assertThat(urls.projectBySlug("MY-PROJECT"))
                .isEqualTo("http://api.example.com/projects/by-slug/MY-PROJECT");
    }

    @Test
    @DisplayName("builds toggles URL with pagination")
    void buildsTogglesUrl() {
        ApiUrls urls = new ApiUrls("http://api.example.com");

        assertThat(urls.toggles("proj-id", 0, 20))
                .isEqualTo("http://api.example.com/projects/proj-id/toggles?page=0&size=20");
    }

    @Test
    @DisplayName("builds single toggle URL")
    void buildsSingleToggleUrl() {
        ApiUrls urls = new ApiUrls("http://api.example.com");

        assertThat(urls.toggle("proj-id", "toggle-id"))
                .isEqualTo("http://api.example.com/projects/proj-id/toggles/toggle-id");
    }

    @Test
    @DisplayName("builds environments URL with pagination")
    void buildsEnvironmentsUrl() {
        ApiUrls urls = new ApiUrls("http://api.example.com");

        assertThat(urls.environments("proj-id", 1, 50))
                .isEqualTo("http://api.example.com/projects/proj-id/environments?page=1&size=50");
    }

    @Test
    @DisplayName("trims trailing slash from base URL")
    void trimsTrailingSlash() {
        ApiUrls urls = new ApiUrls("http://api.example.com/");

        assertThat(urls.projectBySlug("test"))
                .isEqualTo("http://api.example.com/projects/by-slug/test");
    }

    @Test
    @DisplayName("rejects blank base URL")
    void rejectsBlankBaseUrl() {
        assertThatThrownBy(() -> new ApiUrls("  "))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
