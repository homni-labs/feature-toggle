/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.featuretoggle.application.usecase;

import com.homni.featuretoggle.domain.model.Project;
import com.homni.featuretoggle.domain.model.ProjectRole;

/**
 * Project paired with the caller's role.
 *
 * @param project the project
 * @param myRole  caller's role, or {@code null} for platform admins
 */
public record ProjectWithRole(Project project, ProjectRole myRole) {}
