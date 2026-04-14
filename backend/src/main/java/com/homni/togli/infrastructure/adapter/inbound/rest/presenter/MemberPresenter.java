/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest.presenter;

import com.homni.togli.application.usecase.MemberPage;
import com.homni.togli.domain.model.ProjectMembership;
import com.homni.generated.model.MembershipListResponse;
import com.homni.generated.model.MembershipSingleResponse;
import com.homni.generated.model.Pagination;
import com.homni.generated.model.ResponseMeta;
import org.openapitools.jackson.nullable.JsonNullable;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Maps project membership domain objects to generated OpenAPI response models.
 */
@Component
public class MemberPresenter {

    /**
     * Wraps a single membership in a typed response envelope.
     *
     * @param m the domain membership
     * @return the typed single response
     */
    public MembershipSingleResponse single(ProjectMembership m) {
        return new MembershipSingleResponse(toDto(m), meta());
    }

    /**
     * Wraps a page of memberships in a typed response envelope.
     *
     * @param page     the domain member page
     * @param pageNum  zero-based page number
     * @param pageSize page size
     * @return the typed list response with pagination
     */
    public MembershipListResponse list(MemberPage page, int pageNum, int pageSize) {
        List<com.homni.generated.model.ProjectMembership> items = page.items().stream()
                .map(this::toDto).toList();
        return new MembershipListResponse(
                items, pagination(page.totalElements(), pageNum, pageSize), meta());
    }

    private com.homni.generated.model.ProjectMembership toDto(ProjectMembership m) {
        com.homni.generated.model.ProjectMembership dto =
                new com.homni.generated.model.ProjectMembership(
                        m.id.value, m.projectId.value, m.userId.value,
                        com.homni.generated.model.ProjectMembership.RoleEnum.fromValue(
                                m.currentRole().name()),
                        toUtc(m.grantedAt));
        m.lastModifiedAt().ifPresent(t ->
                dto.setUpdatedAt(JsonNullable.of(toUtc(t))));
        m.email().ifPresent(e ->
                dto.setEmail(JsonNullable.of(e)));
        m.displayName().ifPresent(n ->
                dto.setName(JsonNullable.of(n)));
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
