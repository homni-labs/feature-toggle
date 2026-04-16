/*
 * (\(\
 * ( -.-)    I'm watching you.
 * o_(")(")  Don't write crappy code.
 *
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */

package com.homni.togli;

import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Single PostgreSQL container shared by all test classes. Started once
 * when this class is first loaded — Testcontainers Ryuk stops it when
 * the JVM exits.
 *
 * <p>Every test base class ({@code BaseIntegrationTest},
 * {@code BaseControllerTest}, etc.) should reference {@link #PG} for
 * dynamic datasource properties instead of creating its own container.
 */
public final class SharedTestContainer {

    public static final PostgreSQLContainer<?> PG;

    static {
        PG = new PostgreSQLContainer<>("postgres:17-alpine")
                .withDatabaseName("togli_test")
                .withUsername("test")
                .withPassword("test");
        PG.start();
    }

    private SharedTestContainer() {}
}
