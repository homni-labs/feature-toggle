/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk;

import com.homni.togli.sdk.internal.TogliClientBuilder;

/**
 * Static factory for creating {@link TogliClient} instances.
 *
 * <pre>{@code
 * TogliClient client = TogliClients.builder()
 *         .baseUrl("https://api.togli.io")
 *         .apiKey("tok_live_abc123")
 *         .projectSlug("my-project")
 *         .build();
 * }</pre>
 *
 * @see TogliClientBuilder
 */
public final class TogliClients {

    private TogliClients() {
        throw new AssertionError("No instances");
    }

    /**
     * Creates a new client builder with sensible defaults.
     *
     * @return a fresh builder, never {@code null}
     */
    public static TogliClientBuilder builder() {
        return new TogliClientBuilder();
    }
}
