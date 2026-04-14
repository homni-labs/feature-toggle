/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest.presenter;

import com.homni.togli.application.port.out.ApiKeyClientRepositoryPort;
import com.homni.togli.application.usecase.ApiKeyPage;
import com.homni.togli.application.usecase.ClientStats;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.ApiKeyClient;
import com.homni.togli.domain.model.ApiKeyId;
import com.homni.togli.domain.model.IssuedApiKey;
import com.homni.generated.model.ApiKeyClientListResponse;
import com.homni.generated.model.ApiKeyCreated;
import com.homni.generated.model.ApiKeyCreatedSingleResponse;
import com.homni.generated.model.ApiKeyListResponse;
import com.homni.generated.model.Pagination;
import com.homni.generated.model.ResponseMeta;
import org.openapitools.jackson.nullable.JsonNullable;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Maps API key domain objects to generated OpenAPI response models.
 */
@Component
public class ApiKeyPresenter {

    private final ApiKeyClientRepositoryPort clients;

    /**
     * Creates the API key presenter.
     *
     * @param clients API key client persistence port for usage stats
     */
    public ApiKeyPresenter(ApiKeyClientRepositoryPort clients) {
        this.clients = clients;
    }

    /**
     * Wraps a newly issued API key (with raw token) in a typed response envelope.
     *
     * @param issued the issued key with raw token
     * @return the typed single response
     */
    public ApiKeyCreatedSingleResponse created(IssuedApiKey issued) {
        ApiKey key = issued.apiKey;
        ApiKeyCreated.RoleEnum role = ApiKeyCreated.RoleEnum.fromValue(key.projectRole.name());
        ApiKeyCreated dto = new ApiKeyCreated(
                key.id.value, key.name, role, issued.rawToken, toUtc(key.createdAt));
        if (key.expiresAt != null) {
            dto.setExpiresAt(JsonNullable.of(toUtc(key.expiresAt)));
        }
        return new ApiKeyCreatedSingleResponse(dto, meta());
    }

    /**
     * Wraps a page of API keys in a typed response envelope.
     *
     * @param page     the domain API key page
     * @param pageNum  zero-based page number
     * @param pageSize page size
     * @return the typed list response with pagination
     */
    public ApiKeyListResponse list(ApiKeyPage page, int pageNum, int pageSize) {
        List<ApiKeyId> keyIds = page.items().stream().map(k -> k.id).toList();
        Map<UUID, ClientStats> statsMap = clients.statsByApiKeys(keyIds);

        List<com.homni.generated.model.ApiKey> items = page.items().stream()
                .map(k -> toDto(k, statsMap.get(k.id.value))).toList();
        return new ApiKeyListResponse(
                items, pagination(page.totalElements(), pageNum, pageSize), meta());
    }

    /**
     * Wraps a list of API key clients in a typed response envelope.
     *
     * @param clientList the domain client list
     * @return the typed list response
     */
    public ApiKeyClientListResponse clientList(List<ApiKeyClient> clientList) {
        List<com.homni.generated.model.ApiKeyClient> items = clientList.stream()
                .map(this::toClientDto).toList();
        return new ApiKeyClientListResponse(items, meta());
    }

    private com.homni.generated.model.ApiKey toDto(ApiKey k, ClientStats stats) {
        com.homni.generated.model.ApiKey dto = new com.homni.generated.model.ApiKey(
                k.id.value, k.projectId.value, k.name,
                com.homni.generated.model.ApiKey.RoleEnum.fromValue(k.projectRole.name()),
                k.maskedToken(), k.isActive(), toUtc(k.createdAt));
        if (k.expiresAt != null) {
            dto.setExpiresAt(JsonNullable.of(toUtc(k.expiresAt)));
        }
        if (stats != null) {
            dto.setLastUsedAt(JsonNullable.of(toUtc(stats.lastUsedAt())));
            dto.setClientCount(stats.clientCount());
        }
        return dto;
    }

    private com.homni.generated.model.ApiKeyClient toClientDto(ApiKeyClient c) {
        var dto = new com.homni.generated.model.ApiKeyClient();
        dto.setId(c.id.value());
        dto.setApiKeyId(c.apiKeyId.value);
        dto.setClientType(
                com.homni.generated.model.ApiKeyClient.ClientTypeEnum.fromValue(c.clientType.name()));
        dto.setSdkName(JsonNullable.of(c.sdkName));
        dto.setServiceName(c.serviceName);
        dto.setNamespace(JsonNullable.of(c.namespace));
        dto.setFirstSeenAt(toUtc(c.firstSeenAt));
        dto.setLastSeenAt(toUtc(c.lastSeenAt));
        dto.setRequestCount(c.requestCount);
        return dto;
    }

    private Pagination pagination(long totalElements, int pageNum, int pageSize) {
        int totalPages = pageSize > 0 ? (int) Math.ceil((double) totalElements / pageSize) : 0;
        return new Pagination(pageNum, pageSize, totalElements, totalPages);
    }

    private ResponseMeta meta() {
        return new ResponseMeta(OffsetDateTime.now(ZoneOffset.UTC));
    }

    private OffsetDateTime toUtc(Instant instant) {
        return instant != null ? instant.atOffset(ZoneOffset.UTC) : null;
    }
}
