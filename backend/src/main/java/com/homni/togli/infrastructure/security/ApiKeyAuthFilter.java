/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.security;

import com.homni.togli.application.port.out.ApiKeyRepositoryPort;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.TokenHash;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Authenticates requests carrying an {@code X-API-Key} header.
 * Creates an {@link ApiKeyAuthentication} with the key's project and role.
 */
@Component
public class ApiKeyAuthFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(ApiKeyAuthFilter.class);
    private static final String API_KEY_HEADER = "X-API-Key";

    private final ApiKeyRepositoryPort apiKeyRepository;

    ApiKeyAuthFilter(ApiKeyRepositoryPort apiKeyRepository) {
        this.apiKeyRepository = apiKeyRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String apiKeyHeader = request.getHeader(API_KEY_HEADER);

        if (apiKeyHeader != null && !apiKeyHeader.isBlank()) {
            log.debug("API key header present, resolving token");
            TokenHash hash = TokenHash.from(apiKeyHeader);
            ApiKey apiKey = apiKeyRepository.findByTokenHash(hash).orElse(null);

            if (apiKey != null && apiKey.isValid()) {
                ApiKeyAuthentication auth = new ApiKeyAuthentication(
                        apiKey.projectId,
                        apiKey.projectRole,
                        "apikey:" + apiKey.name,
                        List.of(new SimpleGrantedAuthority(
                                "ROLE_" + apiKey.projectRole.name())));
                SecurityContextHolder.getContext().setAuthentication(auth);
                log.debug("API key authenticated: name={}, project={}, role={}",
                        apiKey.name, apiKey.projectId.value, apiKey.projectRole);
            } else {
                log.debug("API key not found or invalid");
            }
        }

        filterChain.doFilter(request, response);
    }
}
