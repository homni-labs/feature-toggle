/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter;

import com.homni.featuretoggle.application.usecase.EnvironmentPage;
import com.homni.featuretoggle.domain.model.Environment;
import com.homni.generated.model.EnvironmentListResponse;
import com.homni.generated.model.EnvironmentSingleResponse;
import com.homni.generated.model.Pagination;
import com.homni.generated.model.ResponseMeta;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Maps environment domain objects to generated OpenAPI response models.
 */
@Component
public class EnvironmentPresenter {

    /**
     * Wraps a single environment in a typed response envelope.
     *
     * @param e the domain environment
     * @return the typed single response
     */
    public EnvironmentSingleResponse single(Environment e) {
        return new EnvironmentSingleResponse(toDto(e), meta());
    }

    /**
     * Wraps a page of environments in a typed response envelope.
     *
     * @param page     the domain environment page
     * @param pageNum  zero-based page number
     * @param pageSize page size
     * @return the typed list response with pagination
     */
    public EnvironmentListResponse list(EnvironmentPage page, int pageNum, int pageSize) {
        List<com.homni.generated.model.Environment> items = page.items().stream()
                .map(this::toDto).toList();
        return new EnvironmentListResponse(
                items, pagination(page.totalElements(), pageNum, pageSize), meta());
    }

    private Pagination pagination(long totalElements, int pageNum, int pageSize) {
        int totalPages = pageSize > 0 ? (int) Math.ceil((double) totalElements / pageSize) : 0;
        return new Pagination(pageNum, pageSize, totalElements, totalPages);
    }

    private com.homni.generated.model.Environment toDto(Environment e) {
        return new com.homni.generated.model.Environment(
                e.id.value, e.projectId.value, e.name(), toUtc(e.createdAt));
    }

    private ResponseMeta meta() {
        return new ResponseMeta(OffsetDateTime.now(ZoneOffset.UTC));
    }

    private OffsetDateTime toUtc(Instant instant) {
        return instant != null ? instant.atOffset(ZoneOffset.UTC) : null;
    }
}
