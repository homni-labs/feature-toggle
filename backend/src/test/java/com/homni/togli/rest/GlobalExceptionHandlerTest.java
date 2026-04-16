/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.domain.exception.AlreadyExistsException;
import com.homni.togli.domain.exception.DomainAccessDeniedException;
import com.homni.togli.domain.exception.DomainValidationException;
import com.homni.togli.domain.exception.EntityNotFoundException;
import com.homni.togli.domain.exception.InsufficientPermissionException;
import com.homni.togli.domain.model.Permission;
import com.homni.togli.domain.model.ProjectId;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Tests that the {@code GlobalExceptionHandler} maps domain exceptions
 * to the correct HTTP status codes and response format.
 *
 * <p>Uses the {@code GET /users/me} endpoint as a trigger — when the mocked
 * use-case throws, the exception handler catches and maps the response.
 */
class GlobalExceptionHandlerTest extends BaseControllerTest {

    @Test
    @DisplayName("DomainAccessDeniedException → 403 FORBIDDEN")
    void accessDenied_returns403() throws Exception {
        when(getCurrentUser.execute())
                .thenThrow(new InsufficientPermissionException(new ProjectId(), Permission.MANAGE_MEMBERS));

        mockMvc.perform(get("/users/me"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.payload.code").value("FORBIDDEN"))
                .andExpect(jsonPath("$.payload.message").exists())
                .andExpect(jsonPath("$.meta.timestamp").exists());
    }

    @Test
    @DisplayName("DomainNotFoundException → 404 NOT_FOUND")
    void notFound_returns404() throws Exception {
        when(getCurrentUser.execute())
                .thenThrow(new EntityNotFoundException("User", "missing-id"));

        mockMvc.perform(get("/users/me"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.payload.code").value("NOT_FOUND"))
                .andExpect(jsonPath("$.payload.message").exists());
    }

    @Test
    @DisplayName("DomainConflictException → 409 CONFLICT")
    void conflict_returns409() throws Exception {
        when(getCurrentUser.execute())
                .thenThrow(new AlreadyExistsException("User", "dup@test.local"));

        mockMvc.perform(get("/users/me"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.payload.code").value("CONFLICT"));
    }

    @Test
    @DisplayName("DomainValidationException → 422 UNPROCESSABLE_ENTITY")
    void validation_returns422() throws Exception {
        when(getCurrentUser.execute())
                .thenThrow(new DomainValidationException("Invalid name"));

        mockMvc.perform(get("/users/me"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.payload.code").value("VALIDATION_ERROR"));
    }

    @Test
    @DisplayName("IllegalArgumentException → 400 BAD_REQUEST")
    void illegalArgument_returns400() throws Exception {
        when(getCurrentUser.execute())
                .thenThrow(new IllegalArgumentException("bad param"));

        mockMvc.perform(get("/users/me"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.payload.code").value("BAD_REQUEST"));
    }

    @Test
    @DisplayName("Unhandled exception → 500 INTERNAL_SERVER_ERROR")
    void unexpected_returns500() throws Exception {
        when(getCurrentUser.execute())
                .thenThrow(new RuntimeException("something broke"));

        mockMvc.perform(get("/users/me"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.payload.code").value("INTERNAL_ERROR"))
                .andExpect(jsonPath("$.payload.message").value("An unexpected error occurred"));
    }
}
