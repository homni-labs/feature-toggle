/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.rest;

import com.homni.togli.application.port.out.ApiKeyClientRepositoryPort;
import com.homni.togli.application.port.out.ApiKeyRepositoryPort;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.domain.model.ProjectRole;
import com.homni.togli.domain.model.TokenHash;
import com.homni.togli.infrastructure.security.ApiKeyAuthFilter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the API key authentication filter. Tests the filter in
 * isolation without a Spring context, verifying that valid keys set the
 * SecurityContext and invalid/missing keys pass through unauthenticated.
 */
@ExtendWith(MockitoExtension.class)
class ApiKeyAuthFilterTest {

    @Mock ApiKeyRepositoryPort apiKeyRepository;
    @Mock ApiKeyClientRepositoryPort apiKeyClientRepository;
    @Mock HttpServletRequest request;
    @Mock HttpServletResponse response;
    @Mock FilterChain filterChain;

    @InjectMocks ApiKeyAuthFilter filter;

    @Nested
    @DisplayName("valid API key")
    class ValidApiKey {

        @Test
        @DisplayName("sets authentication in SecurityContext and continues chain")
        void authenticatesRequest() throws Exception {
            String rawToken = "hft_test_token_123";
            TokenHash hash = TokenHash.from(rawToken);
            ApiKey apiKey = new ApiKey(
                    new ProjectId(), "test-key", ProjectRole.READER, hash, null);

            when(request.getHeader("X-API-Key")).thenReturn(rawToken);
            when(apiKeyRepository.findByTokenHash(any())).thenReturn(Optional.of(apiKey));
            when(request.getHeader("X-Togli-Service")).thenReturn("my-service");

            SecurityContextHolder.clearContext();
            filter.doFilter(request, response, filterChain);

            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
            verify(filterChain).doFilter(request, response);
        }
    }

    @Nested
    @DisplayName("expired API key")
    class ExpiredApiKey {

        @Test
        @DisplayName("does not authenticate and continues chain")
        void doesNotAuthenticate() throws Exception {
            String rawToken = "hft_expired_token";
            TokenHash hash = TokenHash.from(rawToken);
            Instant expired = Instant.now().minus(1, ChronoUnit.DAYS);
            ApiKey apiKey = new ApiKey(
                    new ProjectId(), "expired-key", ProjectRole.READER, hash, expired);

            when(request.getHeader("X-API-Key")).thenReturn(rawToken);
            when(apiKeyRepository.findByTokenHash(any())).thenReturn(Optional.of(apiKey));

            SecurityContextHolder.clearContext();
            filter.doFilter(request, response, filterChain);

            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
            verify(filterChain).doFilter(request, response);
        }
    }

    @Nested
    @DisplayName("missing API key header")
    class MissingHeader {

        @Test
        @DisplayName("passes through without authentication")
        void passesThrough() throws Exception {
            when(request.getHeader("X-API-Key")).thenReturn(null);

            SecurityContextHolder.clearContext();
            filter.doFilter(request, response, filterChain);

            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
            verify(filterChain).doFilter(request, response);
            verify(apiKeyRepository, never()).findByTokenHash(any());
        }
    }

    @Nested
    @DisplayName("missing X-Togli-Service header")
    class MissingServiceHeader {

        @Test
        @DisplayName("returns 400 when service header is absent")
        void returns400() throws Exception {
            String rawToken = "hft_test_token_456";
            TokenHash hash = TokenHash.from(rawToken);
            ApiKey apiKey = new ApiKey(
                    new ProjectId(), "test-key", ProjectRole.READER, hash, null);

            when(request.getHeader("X-API-Key")).thenReturn(rawToken);
            when(apiKeyRepository.findByTokenHash(any())).thenReturn(Optional.of(apiKey));
            when(request.getHeader("X-Togli-Service")).thenReturn(null);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));

            SecurityContextHolder.clearContext();
            filter.doFilter(request, response, filterChain);

            verify(response).setStatus(400);
            verify(filterChain, never()).doFilter(request, response);
        }
    }

    @Nested
    @DisplayName("unknown API key")
    class UnknownKey {

        @Test
        @DisplayName("does not authenticate when key not found in database")
        void doesNotAuthenticate() throws Exception {
            when(request.getHeader("X-API-Key")).thenReturn("hft_unknown");
            when(apiKeyRepository.findByTokenHash(any())).thenReturn(Optional.empty());

            SecurityContextHolder.clearContext();
            filter.doFilter(request, response, filterChain);

            assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
            verify(filterChain).doFilter(request, response);
        }
    }
}
