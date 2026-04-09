/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter;

import com.homni.featuretoggle.domain.model.Environment;
import com.homni.generated.model.DefaultEnvironmentListResponse;
import com.homni.generated.model.EnvironmentListResponse;
import com.homni.generated.model.EnvironmentSingleResponse;
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
     * Wraps a list of environments in a typed response envelope.
     *
     * @param environments the domain environment list
     * @return the typed list response
     */
    public EnvironmentListResponse list(List<Environment> environments) {
        List<com.homni.generated.model.Environment> items = environments.stream()
                .map(this::toDto).toList();
        return new EnvironmentListResponse(items, meta());
    }

    /**
     * Wraps the platform-wide list of default environment names in a typed
     * response envelope. The list is read straight from application config and
     * does not touch the database.
     *
     * @param defaultNames default environment names from config
     * @return the typed default environment list response
     */
    public DefaultEnvironmentListResponse defaults(List<String> defaultNames) {
        return new DefaultEnvironmentListResponse(List.copyOf(defaultNames), meta());
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
