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
import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("AppUserJdbcAdapter")
class AppUserJdbcAdapterIntegrationTest extends BaseIntegrationTest {

    @Autowired AppUserRepositoryPort users;

    @BeforeEach
    void setUp() {
        actAsAdmin(adminUser());
    }

    @Nested
    @DisplayName("search")
    class Search {

        @Test
        @DisplayName("finds users by email substring")
        void searchByEmail() {
            String unique = "searchable" + randomSuffix();
            AppUser user = new AppUser("oidc-" + unique, unique + "@test.local", "Searchable");
            users.save(user);

            List<AppUser> results = users.search(unique, 10);
            assertThat(results).extracting(u -> u.id).contains(user.id);
        }

        @Test
        @DisplayName("finds users by name substring")
        void searchByName() {
            String unique = "NameSearch" + randomSuffix();
            AppUser user = new AppUser("oidc-ns-" + randomSuffix(), "ns-" + randomSuffix() + "@test.local", unique);
            users.save(user);

            List<AppUser> results = users.search(unique.toLowerCase(), 10);
            assertThat(results).extracting(u -> u.id).contains(user.id);
        }

        @Test
        @DisplayName("respects limit")
        void respectsLimit() {
            List<AppUser> results = users.search("@", 2);
            assertThat(results.size()).isLessThanOrEqualTo(2);
        }
    }

    @Nested
    @DisplayName("findByEmail")
    class FindByEmail {

        @Test
        @DisplayName("finds user by email")
        void findsUser() {
            String email = "byemail-" + randomSuffix().toLowerCase() + "@test.local";
            AppUser user = new AppUser("oidc-be-" + randomSuffix(), email, "Test");
            users.save(user);

            Optional<AppUser> found = users.findByEmail(email);
            assertThat(found).isPresent();
            assertThat(found.get().id).isEqualTo(user.id);
        }
    }

    @Nested
    @DisplayName("findByOidcSubject")
    class FindByOidc {

        @Test
        @DisplayName("finds user by OIDC subject")
        void findsUser() {
            String subject = "oidc-sub-" + randomSuffix();
            AppUser user = new AppUser(subject, "oidc-" + randomSuffix() + "@test.local", "Test");
            users.save(user);

            Optional<AppUser> found = users.findByOidcSubject(subject);
            assertThat(found).isPresent();
            assertThat(found.get().id).isEqualTo(user.id);
        }

        @Test
        @DisplayName("returns empty for unknown subject")
        void returnsEmpty() {
            assertThat(users.findByOidcSubject("nonexistent")).isEmpty();
        }
    }

    @Nested
    @DisplayName("pagination")
    class Pagination {

        @Test
        @DisplayName("paginates user list and counts total")
        void paginatesAndCounts() {
            long countBefore = users.count();

            AppUser user = new AppUser("oidc-pg-" + randomSuffix(),
                    "pg-" + randomSuffix() + "@test.local", "Test");
            users.save(user);

            long countAfter = users.count();
            assertThat(countAfter).isEqualTo(countBefore + 1);

            List<AppUser> page = users.findAll(0, 2);
            assertThat(page.size()).isLessThanOrEqualTo(2);
        }
    }

    @Nested
    @DisplayName("delete")
    class Delete {

        @Test
        @DisplayName("deletes user by id")
        void deletesUser() {
            AppUser user = new AppUser("oidc-del-" + randomSuffix(),
                    "del-" + randomSuffix() + "@test.local", "Test");
            users.save(user);

            users.deleteById(user.id);
            assertThat(users.findById(user.id)).isEmpty();
        }
    }
}
