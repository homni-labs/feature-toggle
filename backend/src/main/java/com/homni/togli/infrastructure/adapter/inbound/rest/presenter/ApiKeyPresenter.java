/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest.presenter;

import com.homni.togli.application.usecase.ApiKeyPage;
import com.homni.togli.domain.model.ApiKey;
import com.homni.togli.domain.model.IssuedApiKey;
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

/**
 * Maps API key domain objects to generated OpenAPI response models.
 */
@Component
public class ApiKeyPresenter {

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
        List<com.homni.generated.model.ApiKey> items = page.items().stream()
                .map(this::toDto).toList();
        return new ApiKeyListResponse(
                items, pagination(page.totalElements(), pageNum, pageSize), meta());
    }

    private com.homni.generated.model.ApiKey toDto(ApiKey k) {
        com.homni.generated.model.ApiKey dto = new com.homni.generated.model.ApiKey(
                k.id.value, k.projectId.value, k.name,
                com.homni.generated.model.ApiKey.RoleEnum.fromValue(k.projectRole.name()),
                k.maskedToken(), k.isActive(), toUtc(k.createdAt));
        if (k.expiresAt != null) {
            dto.setExpiresAt(JsonNullable.of(toUtc(k.expiresAt)));
        }
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
