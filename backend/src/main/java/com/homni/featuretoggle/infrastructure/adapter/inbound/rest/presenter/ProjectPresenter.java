/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter;

import com.homni.featuretoggle.application.usecase.ProjectListItem;
import com.homni.featuretoggle.application.usecase.ProjectPage;
import com.homni.featuretoggle.domain.model.Project;
import com.homni.generated.model.Pagination;
import com.homni.generated.model.ProjectListResponse;
import com.homni.generated.model.ProjectSingleResponse;
import com.homni.generated.model.ResponseMeta;
import org.openapitools.jackson.nullable.JsonNullable;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

/**
 * Maps project domain objects to generated OpenAPI response models.
 */
@Component
public class ProjectPresenter {

    /**
     * Wraps a single project in a typed response envelope. Single-project
     * responses don't carry list-only counts (toggles/envs/members), so the
     * count fields are populated as zero — they are only meaningful in the
     * list endpoint output anyway.
     *
     * @param p the domain project
     * @return the typed single response
     */
    public ProjectSingleResponse single(Project p) {
        return new ProjectSingleResponse(toDto(p, 0L, 0L, 0L), meta());
    }

    /**
     * Wraps a page of projects in a typed list response envelope, including
     * the pagination block (filtered query) and workspace-level subtitle
     * counts (totalCount / archivedCount).
     *
     * @param page     the application-layer project page
     * @param pageNum  zero-based page number
     * @param pageSize page size
     * @return the typed list response
     */
    public ProjectListResponse list(ProjectPage page, int pageNum, int pageSize) {
        List<com.homni.generated.model.Project> items = page.items().stream()
                .map(this::toListDto)
                .toList();
        return new ProjectListResponse(
                items,
                pagination(page.totalElements(), pageNum, pageSize),
                page.totalCount(),
                page.archivedCount(),
                meta());
    }

    private com.homni.generated.model.Project toListDto(ProjectListItem item) {
        var dto = toDto(item.project(), item.togglesCount(), item.environmentsCount(), item.membersCount());
        if (item.myRole() != null) {
            dto.setMyRole(JsonNullable.of(
                    com.homni.generated.model.Project.MyRoleEnum.fromValue(item.myRole().name())));
        }
        return dto;
    }

    private com.homni.generated.model.Project toDto(Project p,
                                                    long togglesCount,
                                                    long environmentsCount,
                                                    long membersCount) {
        com.homni.generated.model.Project dto = new com.homni.generated.model.Project(
                p.id.value, p.slug.value(), p.name(), p.isArchived(), toUtc(p.createdAt),
                togglesCount, environmentsCount, membersCount);
        dto.setDescription(p.description().orElse(null));
        dto.setUpdatedAt(JsonNullable.of(p.lastModifiedAt().map(this::toUtc).orElse(null)));
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
