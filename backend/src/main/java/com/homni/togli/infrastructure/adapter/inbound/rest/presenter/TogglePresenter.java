/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest.presenter;

import com.homni.togli.application.usecase.TogglePage;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.generated.model.FeatureToggleEnvironment;
import com.homni.generated.model.FeatureToggleListResponse;
import com.homni.generated.model.FeatureToggleSingleResponse;
import com.homni.generated.model.Pagination;
import com.homni.generated.model.ResponseMeta;
import org.openapitools.jackson.nullable.JsonNullable;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

/**
 * Maps feature toggle domain objects to generated OpenAPI response models.
 */
@Component
public class TogglePresenter {

    /**
     * Wraps a single feature toggle in a typed response envelope.
     *
     * @param t the domain toggle
     * @return the typed single response
     */
    public FeatureToggleSingleResponse single(FeatureToggle t) {
        return new FeatureToggleSingleResponse(toDto(t), meta());
    }

    /**
     * Wraps a page of feature toggles in a typed response envelope.
     *
     * @param page     the domain toggle page
     * @param pageNum  zero-based page number
     * @param pageSize page size
     * @return the typed list response with pagination
     */
    public FeatureToggleListResponse list(TogglePage page, int pageNum, int pageSize) {
        List<com.homni.generated.model.FeatureToggle> items = page.items().stream()
                .map(this::toDto).toList();
        return new FeatureToggleListResponse(
                items, pagination(page.totalElements(), pageNum, pageSize), meta());
    }

    private com.homni.generated.model.FeatureToggle toDto(FeatureToggle t) {
        // Sort by env name here so the API response is stable for the UI.
        // The domain Map intentionally has no ordering invariant — keeping
        // a stable rendering order is a presentation concern.
        List<FeatureToggleEnvironment> envs = t.environmentStates().entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> new FeatureToggleEnvironment(e.getKey(), Boolean.TRUE.equals(e.getValue())))
                .toList();
        com.homni.generated.model.FeatureToggle dto = new com.homni.generated.model.FeatureToggle(
                t.id.value, t.projectId.value, t.name(), envs, toUtc(t.createdAt));
        dto.setDescription(t.description().orElse(null));
        dto.setUpdatedAt(JsonNullable.of(t.lastModifiedAt().map(this::toUtc).orElse(null)));
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
