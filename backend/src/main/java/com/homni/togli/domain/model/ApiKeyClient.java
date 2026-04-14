/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.domain.model;

import com.homni.togli.domain.exception.DomainValidationException;

import java.time.Instant;
import java.util.Objects;

/**
 * Tracks usage of an API key by a specific client (SDK or REST service).
 */
public final class ApiKeyClient {

    public final ApiKeyClientId id;
    public final ApiKeyId apiKeyId;
    public final ProjectId projectId;
    public final ClientType clientType;
    public final String sdkName;
    public final String serviceName;
    public final String namespace;
    public final Instant firstSeenAt;
    public final Instant lastSeenAt;
    public final long requestCount;

    /**
     * Factory constructor for new tracking entries.
     *
     * @param apiKeyId    the API key identity
     * @param projectId   the owning project identity
     * @param clientType  the client type (SDK or REST)
     * @param sdkName     SDK name, or {@code null}
     * @param serviceName service name (must not be blank)
     * @param namespace   namespace, or {@code null}
     * @throws DomainValidationException if serviceName is blank
     */
    public ApiKeyClient(ApiKeyId apiKeyId, ProjectId projectId, ClientType clientType,
                        String sdkName, String serviceName, String namespace) {
        this.id = new ApiKeyClientId();
        this.apiKeyId = Objects.requireNonNull(apiKeyId, "apiKeyId must not be null");
        this.projectId = Objects.requireNonNull(projectId, "projectId must not be null");
        this.clientType = Objects.requireNonNull(clientType, "clientType must not be null");
        this.sdkName = sdkName;
        this.serviceName = validateServiceName(serviceName);
        this.namespace = namespace;
        this.firstSeenAt = Instant.now();
        this.lastSeenAt = Instant.now();
        this.requestCount = 1;
    }

    /**
     * Reconstitution constructor from storage.
     *
     * @param id           the client identity
     * @param apiKeyId     the API key identity
     * @param projectId    the owning project identity
     * @param clientType   the client type
     * @param sdkName      SDK name, or {@code null}
     * @param serviceName  service name
     * @param namespace    namespace, or {@code null}
     * @param firstSeenAt  first seen timestamp
     * @param lastSeenAt   last seen timestamp
     * @param requestCount total request count
     * @throws DomainValidationException if serviceName is blank
     */
    public ApiKeyClient(ApiKeyClientId id, ApiKeyId apiKeyId, ProjectId projectId,
                        ClientType clientType, String sdkName, String serviceName,
                        String namespace, Instant firstSeenAt, Instant lastSeenAt,
                        long requestCount) {
        this.id = Objects.requireNonNull(id, "id must not be null");
        this.apiKeyId = Objects.requireNonNull(apiKeyId, "apiKeyId must not be null");
        this.projectId = Objects.requireNonNull(projectId, "projectId must not be null");
        this.clientType = Objects.requireNonNull(clientType, "clientType must not be null");
        this.sdkName = sdkName;
        this.serviceName = validateServiceName(serviceName);
        this.namespace = namespace;
        this.firstSeenAt = Objects.requireNonNull(firstSeenAt, "firstSeenAt must not be null");
        this.lastSeenAt = Objects.requireNonNull(lastSeenAt, "lastSeenAt must not be null");
        this.requestCount = requestCount;
    }

    private String validateServiceName(String serviceName) {
        if (serviceName == null || serviceName.isBlank()) {
            throw new DomainValidationException("serviceName must not be null or blank");
        }
        return serviceName;
    }
}
