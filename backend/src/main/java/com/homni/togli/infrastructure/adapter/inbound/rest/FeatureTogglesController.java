/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli.infrastructure.adapter.inbound.rest;

import com.homni.togli.application.usecase.CreateToggleUseCase;
import com.homni.togli.application.usecase.DeleteToggleUseCase;
import com.homni.togli.application.usecase.FindToggleUseCase;
import com.homni.togli.application.usecase.ListTogglesUseCase;
import com.homni.togli.application.usecase.TogglePage;
import com.homni.togli.application.usecase.UpdateToggleUseCase;
import com.homni.togli.domain.model.FeatureToggle;
import com.homni.togli.domain.model.FeatureToggleId;
import com.homni.togli.domain.model.ProjectId;
import com.homni.togli.infrastructure.adapter.inbound.rest.presenter.TogglePresenter;
import com.homni.generated.api.FeatureTogglesApi;
import com.homni.generated.model.CreateFeatureToggleRequest;
import com.homni.generated.model.FeatureToggleListResponse;
import com.homni.generated.model.FeatureToggleSingleResponse;
import com.homni.generated.model.UpdateFeatureToggleRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Handles feature toggle CRUD operations.
 */
@RestController
class FeatureTogglesController implements FeatureTogglesApi {

    private final CreateToggleUseCase createToggle;
    private final FindToggleUseCase findToggle;
    private final ListTogglesUseCase listToggles;
    private final UpdateToggleUseCase updateToggle;
    private final DeleteToggleUseCase deleteToggle;
    private final TogglePresenter presenter;

    /**
     * Creates the feature toggles controller.
     *
     * @param createToggle the use case for toggle creation
     * @param findToggle   the use case for finding a toggle
     * @param listToggles  the use case for listing toggles
     * @param updateToggle the use case for updating a toggle
     * @param deleteToggle the use case for deleting a toggle
     * @param presenter    maps domain objects to API response models
     */
    FeatureTogglesController(CreateToggleUseCase createToggle,
                             FindToggleUseCase findToggle,
                             ListTogglesUseCase listToggles,
                             UpdateToggleUseCase updateToggle,
                             DeleteToggleUseCase deleteToggle,
                             TogglePresenter presenter) {
        this.createToggle = createToggle;
        this.findToggle = findToggle;
        this.listToggles = listToggles;
        this.updateToggle = updateToggle;
        this.deleteToggle = deleteToggle;
        this.presenter = presenter;
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<FeatureToggleSingleResponse> createToggle(UUID projectId,
                                                                     CreateFeatureToggleRequest req) {
        FeatureToggle toggle = createToggle.execute(
                new ProjectId(projectId), req.getName(), req.getDescription(),
                toSet(req.getEnvironments()));
        return ResponseEntity.ok(presenter.single(toggle));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<FeatureToggleSingleResponse> getToggle(UUID projectId, UUID toggleId) {
        FeatureToggle toggle = findToggle.execute(new FeatureToggleId(toggleId));
        return ResponseEntity.ok(presenter.single(toggle));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<FeatureToggleListResponse> listToggles(UUID projectId, Boolean enabled,
                                                                  String environment,
                                                                  Integer page, Integer size) {
        PaginationParams p = PaginationParams.of(page, size);
        TogglePage result = listToggles.execute(
                new ProjectId(projectId), enabled, environment, p.page(), p.size());
        return ResponseEntity.ok(presenter.list(result, p.page(), p.size()));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<FeatureToggleSingleResponse> updateToggle(UUID projectId, UUID toggleId,
                                                                     UpdateFeatureToggleRequest req) {
        FeatureToggle toggle = updateToggle.execute(
                new FeatureToggleId(toggleId), req.getName(), req.getDescription(),
                toSet(req.getEnvironments()), req.getEnvironmentStates());
        return ResponseEntity.ok(presenter.single(toggle));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<Void> deleteToggle(UUID projectId, UUID toggleId) {
        deleteToggle.execute(new FeatureToggleId(toggleId));
        return ResponseEntity.noContent().build();
    }

    private Set<String> toSet(List<String> list) {
        return list != null ? new LinkedHashSet<>(list) : null;
    }
}
