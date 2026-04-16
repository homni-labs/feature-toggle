/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.domain.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("Pagination")
class PaginationTest {

    @Test
    @DisplayName("creates with valid values")
    void createsWithValidValues() {
        Pagination pagination = new Pagination(0, 20, 100, 5);

        assertThat(pagination.page()).isEqualTo(0);
        assertThat(pagination.size()).isEqualTo(20);
        assertThat(pagination.totalElements()).isEqualTo(100);
        assertThat(pagination.totalPages()).isEqualTo(5);
    }

    @Test
    @DisplayName("rejects negative page")
    void rejectsNegativePage() {
        assertThatThrownBy(() -> new Pagination(-1, 20, 100, 5))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("rejects zero size")
    void rejectsZeroSize() {
        assertThatThrownBy(() -> new Pagination(0, 0, 100, 5))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
