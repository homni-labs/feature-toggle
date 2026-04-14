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
import com.homni.generated.model.ErrorResponse;
import com.homni.generated.model.ErrorResponsePayload;
import com.homni.generated.model.ResponseMeta;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.jwt.JwtValidationException;
import org.springframework.security.oauth2.server.resource.InvalidBearerTokenException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.OffsetDateTime;

/**
 * Writes JSON error responses for authentication and authorization failures.
 */
@Component
public class SecurityErrorHandler implements AuthenticationEntryPoint, AccessDeniedHandler {

    private static final Logger log = LoggerFactory.getLogger(SecurityErrorHandler.class);

    private final ObjectMapper mapper;

    SecurityErrorHandler(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    /**
     * Handles unauthenticated requests (401).
     *
     * @param request       the HTTP request
     * @param response      the HTTP response
     * @param authException the authentication failure
     * @throws IOException if writing the response fails
     */
    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException {
        String code;
        String message;

        if (isTokenExpired(authException)) {
            code = "TOKEN_EXPIRED";
            message = "Access token has expired";
        } else {
            code = "UNAUTHORIZED";
            message = "Authentication is required to access this resource";
        }

        log.debug("Authentication failure: status=401, code={}, uri={}", code, request.getRequestURI());
        writeError(response, HttpServletResponse.SC_UNAUTHORIZED, code, message);
    }

    /**
     * Handles access-denied requests (403).
     *
     * @param request                 the HTTP request
     * @param response                the HTTP response
     * @param accessDeniedException   the access denial
     * @throws IOException if writing the response fails
     */
    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
                       AccessDeniedException accessDeniedException) throws IOException {
        log.debug("Access denied: uri={}", request.getRequestURI());
        writeError(response, HttpServletResponse.SC_FORBIDDEN,
                "FORBIDDEN", "You do not have permission to access this resource");
    }

    private boolean isTokenExpired(AuthenticationException ex) {
        if (ex instanceof InvalidBearerTokenException && ex.getCause() instanceof JwtValidationException jwtEx) {
            return jwtEx.getErrors().stream()
                    .anyMatch(error -> error.getDescription() != null
                            && error.getDescription().contains("Jwt expired"));
        }
        return false;
    }

    private void writeError(HttpServletResponse response, int status,
                            String code, String message) throws IOException {
        ErrorResponsePayload payload = new ErrorResponsePayload(code, message);
        ErrorResponse body = new ErrorResponse(payload, new ResponseMeta().timestamp(OffsetDateTime.now()));

        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        mapper.writeValue(response.getOutputStream(), body);
    }
}
