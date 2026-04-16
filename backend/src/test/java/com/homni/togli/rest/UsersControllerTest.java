/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.usecase.UserPage;
import com.homni.togli.domain.exception.CannotModifySelfException;
import com.homni.togli.domain.model.AppUser;
import com.homni.togli.domain.model.PlatformRole;
import com.homni.togli.domain.model.UserId;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class UsersControllerTest extends BaseControllerTest {

    @Nested
    @DisplayName("GET /users/me")
    class GetCurrentUser {

        @Test
        @DisplayName("returns current authenticated user with all fields")
        void returnsCurrentUser() throws Exception {
            AppUser user = new AppUser("sub-123", "admin@test.local", "Admin");
            when(getCurrentUser.execute()).thenReturn(user);

            mockMvc.perform(get("/users/me"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(user.id.value.toString()))
                    .andExpect(jsonPath("$.payload.email").value("admin@test.local"))
                    .andExpect(jsonPath("$.payload.name").value("Admin"))
                    .andExpect(jsonPath("$.payload.platformRole").value("USER"))
                    .andExpect(jsonPath("$.payload.active").value(true))
                    .andExpect(jsonPath("$.payload.createdAt").exists())
                    .andExpect(jsonPath("$.meta.timestamp").exists());

            verify(getCurrentUser).execute();
        }
    }

    @Nested
    @DisplayName("GET /users")
    class ListUsers {

        @Test
        @DisplayName("returns paginated user list with full item content")
        void returnsList() throws Exception {
            AppUser user = new AppUser("sub-1", "user@test.local", "User");
            UserPage page = new UserPage(List.of(user), 1L);
            when(listUsers.execute(eq(2), eq(5))).thenReturn(page);

            mockMvc.perform(get("/users").param("page", "2").param("size", "5"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].id").value(user.id.value.toString()))
                    .andExpect(jsonPath("$.payload[0].email").value("user@test.local"))
                    .andExpect(jsonPath("$.payload[0].name").value("User"))
                    .andExpect(jsonPath("$.payload[0].platformRole").value("USER"))
                    .andExpect(jsonPath("$.payload[0].active").value(true))
                    .andExpect(jsonPath("$.pagination.totalElements").value(1))
                    .andExpect(jsonPath("$.pagination.page").value(2))
                    .andExpect(jsonPath("$.pagination.size").value(5));

            verify(listUsers).execute(eq(2), eq(5));
        }
    }

    @Nested
    @DisplayName("GET /users/search")
    class SearchUsers {

        @Test
        @DisplayName("returns matching users with all fields")
        void searchesByQuery() throws Exception {
            AppUser user = new AppUser("sub-1", "alice@test.local", "Alice");
            when(searchUsers.execute(eq("alice"))).thenReturn(List.of(user));

            mockMvc.perform(get("/users/search").param("q", "alice"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].id").value(user.id.value.toString()))
                    .andExpect(jsonPath("$.payload[0].email").value("alice@test.local"))
                    .andExpect(jsonPath("$.payload[0].name").value("Alice"))
                    .andExpect(jsonPath("$.payload[0].active").value(true))
                    .andExpect(jsonPath("$.pagination").doesNotExist());
        }

        @Test
        @DisplayName("returns empty list when no matches")
        void returnsEmptyForUnknown() throws Exception {
            when(searchUsers.execute(eq("zzzzz"))).thenReturn(List.of());

            mockMvc.perform(get("/users/search").param("q", "zzzzz"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(0)));
        }
    }

    @Nested
    @DisplayName("PATCH /users/{userId}")
    class UpdateUser {

        @Test
        @DisplayName("promotes user to platform admin with full response")
        void promotesUser() throws Exception {
            UUID userId = UUID.randomUUID();
            AppUser user = new AppUser("sub-1", "user@test.local", "User");
            user.promoteToPlatformAdmin();
            when(updateUser.execute(any(UserId.class), eq(PlatformRole.PLATFORM_ADMIN), any()))
                    .thenReturn(user);

            mockMvc.perform(patch("/users/{userId}", userId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"platformRole": "PLATFORM_ADMIN"}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(user.id.value.toString()))
                    .andExpect(jsonPath("$.payload.email").value("user@test.local"))
                    .andExpect(jsonPath("$.payload.name").value("User"))
                    .andExpect(jsonPath("$.payload.platformRole").value("PLATFORM_ADMIN"))
                    .andExpect(jsonPath("$.payload.active").value(true));
        }

        @Test
        @DisplayName("returns 409 when modifying self")
        void rejectsSelfModification() throws Exception {
            UUID userId = UUID.randomUUID();
            when(updateUser.execute(any(), any(), any()))
                    .thenThrow(new CannotModifySelfException(new UserId(userId)));

            mockMvc.perform(patch("/users/{userId}", userId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"active": false}
                                    """))
                    .andExpect(status().isConflict())
                    .andExpect(jsonPath("$.payload.code").value("CONFLICT"));
        }
    }
}
