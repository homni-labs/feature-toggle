/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.jwt.JwtValidationException;
import org.springframework.security.oauth2.server.resource.InvalidBearerTokenException;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link SecurityErrorHandler}. Placed in the same package
 * to access the package-private constructor — no Spring context needed.
 */
@DisplayName("SecurityErrorHandler")
class SecurityErrorHandlerTest {

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule());
    private final SecurityErrorHandler handler = new SecurityErrorHandler(objectMapper);

    @Nested
    @DisplayName("commence (401)")
    class Commence {

        @Test
        @DisplayName("returns 401 UNAUTHORIZED for generic auth failure")
        void returnsUnauthorized() throws Exception {
            MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/test");
            MockHttpServletResponse response = new MockHttpServletResponse();
            AuthenticationException ex = new AuthenticationException("bad creds") {};

            handler.commence(request, response, ex);

            assertThat(response.getStatus()).isEqualTo(401);
            assertThat(response.getContentType()).isEqualTo("application/json");
            String body = response.getContentAsString();
            assertThat(body).contains("UNAUTHORIZED");
            assertThat(body).contains("Authentication is required");
        }

        @Test
        @DisplayName("returns 401 TOKEN_EXPIRED for expired JWT")
        void returnsTokenExpired() throws Exception {
            MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/test");
            MockHttpServletResponse response = new MockHttpServletResponse();

            OAuth2Error error = new OAuth2Error("invalid_token", "Jwt expired at ...", null);
            JwtValidationException jwtEx = new JwtValidationException("expired", List.of(error));
            InvalidBearerTokenException ex = new InvalidBearerTokenException("expired", jwtEx);

            handler.commence(request, response, ex);

            assertThat(response.getStatus()).isEqualTo(401);
            String body = response.getContentAsString();
            assertThat(body).contains("TOKEN_EXPIRED");
            assertThat(body).contains("Access token has expired");
        }
    }

    @Nested
    @DisplayName("handle (403)")
    class Handle {

        @Test
        @DisplayName("returns 403 FORBIDDEN for access denied")
        void returnsForbidden() throws Exception {
            MockHttpServletRequest request = new MockHttpServletRequest("POST", "/projects");
            MockHttpServletResponse response = new MockHttpServletResponse();
            AccessDeniedException ex = new AccessDeniedException("not allowed");

            handler.handle(request, response, ex);

            assertThat(response.getStatus()).isEqualTo(403);
            assertThat(response.getContentType()).isEqualTo("application/json");
            String body = response.getContentAsString();
            assertThat(body).contains("FORBIDDEN");
            assertThat(body).contains("permission");
        }
    }
}
