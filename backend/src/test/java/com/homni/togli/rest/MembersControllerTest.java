/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.usecase.MemberPage;
import com.homni.togli.domain.exception.InsufficientPermissionException;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.togli.domain.model.ProjectRole;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class MembersControllerTest extends BaseControllerTest {

    private final UUID projectId = UUID.randomUUID();

    @Nested
    @DisplayName("PUT /projects/{projectId}/members/{userId}")
    class UpsertMember {

        @Test
        @DisplayName("adds member and returns full membership payload")
        void addsMember() throws Exception {
            UUID userId = UUID.randomUUID();
            ProjectMembership membership = new ProjectMembership(
                    new ProjectId(projectId), new UserId(userId), ProjectRole.EDITOR);
            when(upsertMember.execute(any(), any(), any())).thenReturn(membership);

            mockMvc.perform(put("/projects/{projectId}/members/{userId}", projectId, userId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"role": "EDITOR"}
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload.id").value(membership.id.value.toString()))
                    .andExpect(jsonPath("$.payload.projectId").value(projectId.toString()))
                    .andExpect(jsonPath("$.payload.userId").value(userId.toString()))
                    .andExpect(jsonPath("$.payload.role").value("EDITOR"))
                    .andExpect(jsonPath("$.payload.grantedAt").exists())
                    .andExpect(jsonPath("$.meta.timestamp").exists());

            verify(upsertMember).execute(
                    eq(new ProjectId(projectId)), eq(new UserId(userId)), eq(ProjectRole.EDITOR));
        }

        @Test
        @DisplayName("returns 400 when role is missing")
        void rejectsMissingRole() throws Exception {
            UUID userId = UUID.randomUUID();

            mockMvc.perform(put("/projects/{projectId}/members/{userId}", projectId, userId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isBadRequest());
        }


        @Test
        @DisplayName("returns 403 when caller lacks MANAGE_MEMBERS permission")
        void rejectsInsufficientPermission() throws Exception {
            UUID userId = UUID.randomUUID();
            when(upsertMember.execute(any(), any(), any()))
                    .thenThrow(new InsufficientPermissionException(
                            new ProjectId(projectId), Permission.MANAGE_MEMBERS));

            mockMvc.perform(put("/projects/{projectId}/members/{userId}", projectId, userId)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {"role": "READER"}
                                    """))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.payload.code").value("FORBIDDEN"));
        }
    }

    @Nested
    @DisplayName("GET /projects/{projectId}/members")
    class ListMembers {

        @Test
        @DisplayName("returns paginated member list with full item content")
        void returnsList() throws Exception {
            ProjectMembership membership = new ProjectMembership(
                    new ProjectId(projectId), new UserId(), ProjectRole.ADMIN);
            MemberPage page = new MemberPage(List.of(membership), 1L);
            when(listMembers.execute(any(), eq(0), eq(20))).thenReturn(page);

            mockMvc.perform(get("/projects/{projectId}/members", projectId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.payload", hasSize(1)))
                    .andExpect(jsonPath("$.payload[0].id").value(membership.id.value.toString()))
                    .andExpect(jsonPath("$.payload[0].projectId").value(projectId.toString()))
                    .andExpect(jsonPath("$.payload[0].userId").value(membership.userId.value.toString()))
                    .andExpect(jsonPath("$.payload[0].role").value("ADMIN"))
                    .andExpect(jsonPath("$.payload[0].grantedAt").exists())
                    .andExpect(jsonPath("$.pagination.totalElements").value(1));
        }
    }

    @Nested
    @DisplayName("DELETE /projects/{projectId}/members/{userId}")
    class RemoveMember {

        @Test
        @DisplayName("removes member and returns 204")
        void removesMember() throws Exception {
            UUID userId = UUID.randomUUID();

            mockMvc.perform(delete("/projects/{projectId}/members/{userId}", projectId, userId))
                    .andExpect(status().isNoContent());

            verify(removeMember).execute(eq(new ProjectId(projectId)), eq(new UserId(userId)));
        }
    }
}
