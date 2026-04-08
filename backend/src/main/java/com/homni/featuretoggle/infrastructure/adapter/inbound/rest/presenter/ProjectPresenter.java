/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter;

import com.homni.featuretoggle.application.usecase.ProjectWithRole;
import com.homni.featuretoggle.domain.model.Project;
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
     * Wraps a single project in a typed response envelope.
     *
     * @param p the domain project
     * @return the typed single response
     */
    public ProjectSingleResponse single(Project p) {
        return new ProjectSingleResponse(toDto(p), meta());
    }

    /**
     * Wraps a list of projects-with-role in a typed response envelope.
     *
     * @param projects the list of project-with-role entries
     * @return the typed list response
     */
    public ProjectListResponse list(List<ProjectWithRole> projects) {
        List<com.homni.generated.model.Project> items = projects.stream()
                .map(pwr -> {
                    var dto = toDto(pwr.project());
                    if (pwr.myRole() != null) {
                        dto.setMyRole(JsonNullable.of(
                                com.homni.generated.model.Project.MyRoleEnum.fromValue(
                                        pwr.myRole().name())));
                    }
                    return dto;
                })
                .toList();
        return new ProjectListResponse(items, meta());
    }

    private com.homni.generated.model.Project toDto(Project p) {
        com.homni.generated.model.Project dto = new com.homni.generated.model.Project(
                p.id.value, p.slug.value(), p.name(), p.isArchived(), toUtc(p.createdAt));
        dto.setDescription(p.description().orElse(null));
        dto.setUpdatedAt(JsonNullable.of(p.lastModifiedAt().map(this::toUtc).orElse(null)));
        return dto;
    }

    private ResponseMeta meta() {
        return new ResponseMeta(OffsetDateTime.now(ZoneOffset.UTC));
    }

    private OffsetDateTime toUtc(Instant instant) {
        return instant != null ? instant.atOffset(ZoneOffset.UTC) : null;
    }
}
