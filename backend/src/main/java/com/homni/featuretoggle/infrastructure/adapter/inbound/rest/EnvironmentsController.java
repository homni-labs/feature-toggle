/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.infrastructure.adapter.inbound.rest;

import com.homni.featuretoggle.application.usecase.CreateEnvironmentUseCase;
import com.homni.featuretoggle.application.usecase.DeleteEnvironmentUseCase;
import com.homni.featuretoggle.application.usecase.ListEnvironmentsUseCase;
import com.homni.featuretoggle.domain.model.Environment;
import com.homni.featuretoggle.domain.model.EnvironmentDefaults;
import com.homni.featuretoggle.domain.model.EnvironmentId;
import com.homni.featuretoggle.domain.model.ProjectId;
import com.homni.featuretoggle.infrastructure.adapter.inbound.rest.presenter.EnvironmentPresenter;
import com.homni.generated.api.EnvironmentsApi;
import com.homni.generated.model.CreateEnvironmentRequest;
import com.homni.generated.model.DefaultEnvironmentListResponse;
import com.homni.generated.model.EnvironmentListResponse;
import com.homni.generated.model.EnvironmentSingleResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Handles deployment environment management.
 */
@RestController
class EnvironmentsController implements EnvironmentsApi {

    private final CreateEnvironmentUseCase createEnvironment;
    private final ListEnvironmentsUseCase listEnvironments;
    private final DeleteEnvironmentUseCase deleteEnvironment;
    private final EnvironmentDefaults environmentDefaults;
    private final EnvironmentPresenter presenter;

    /**
     * Creates the environments controller.
     *
     * @param createEnvironment    the use case for environment creation
     * @param listEnvironments     the use case for listing environments
     * @param deleteEnvironment    the use case for deleting an environment
     * @param environmentDefaults  platform-wide default environments policy
     * @param presenter            maps domain objects to API response models
     */
    EnvironmentsController(CreateEnvironmentUseCase createEnvironment,
                           ListEnvironmentsUseCase listEnvironments,
                           DeleteEnvironmentUseCase deleteEnvironment,
                           EnvironmentDefaults environmentDefaults,
                           EnvironmentPresenter presenter) {
        this.createEnvironment = createEnvironment;
        this.listEnvironments = listEnvironments;
        this.deleteEnvironment = deleteEnvironment;
        this.environmentDefaults = environmentDefaults;
        this.presenter = presenter;
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<EnvironmentSingleResponse> createEnvironment(UUID projectId,
                                                                        CreateEnvironmentRequest req) {
        Environment env = createEnvironment.execute(new ProjectId(projectId), req.getName());
        return ResponseEntity.ok(presenter.single(env));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<EnvironmentListResponse> listEnvironments(UUID projectId) {
        List<Environment> environments = listEnvironments.execute(new ProjectId(projectId));
        return ResponseEntity.ok(presenter.list(environments));
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<Void> deleteEnvironment(UUID projectId, UUID environmentId) {
        deleteEnvironment.execute(new EnvironmentId(environmentId), new ProjectId(projectId));
        return ResponseEntity.noContent().build();
    }

    /** {@inheritDoc} */
    @Override
    public ResponseEntity<DefaultEnvironmentListResponse> listDefaultEnvironments() {
        return ResponseEntity.ok(presenter.defaults(environmentDefaults.all()));
    }
}
