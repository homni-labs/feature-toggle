/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.domain.model;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;

/**
 * Newly issued API key with the raw token (shown once).
 */
public final class IssuedApiKey {

    private static final String TOKEN_PREFIX = "hft_";
    private static final int TOKEN_BYTE_LENGTH = 32;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    public final ApiKey apiKey;
    public final String rawToken;

    /**
     * Issues a new read-only API key with a generated token.
     *
     * @param projectId the owning project
     * @param name      key name (1-255 chars)
     * @param expiresAt expiration, or {@code null}
     * @throws com.homni.featuretoggle.domain.exception.DomainValidationException if name is invalid
     */
    public IssuedApiKey(ProjectId projectId, String name, Instant expiresAt) {
        this.rawToken = generateToken();
        TokenHash tokenHash = TokenHash.from(this.rawToken);
        this.apiKey = new ApiKey(projectId, name, ProjectRole.READER, tokenHash, expiresAt);
    }

    private String generateToken() {
        byte[] bytes = new byte[TOKEN_BYTE_LENGTH];
        SECURE_RANDOM.nextBytes(bytes);
        return TOKEN_PREFIX + Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
