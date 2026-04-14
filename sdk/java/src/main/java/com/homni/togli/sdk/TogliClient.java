/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk;

import com.homni.togli.sdk.domain.model.EnvironmentInfo;
import com.homni.togli.sdk.domain.model.ProjectInfo;
import com.homni.togli.sdk.domain.model.Toggle;

import java.util.List;
import java.util.function.Supplier;

/**
 * Primary entry point for the Togli feature toggle SDK.
 *
 * <p>Usage:
 * <pre>{@code
 * TogliClient client = TogliClients.builder()
 *     .baseUrl("http://localhost:8080")
 *     .apiKey("hft_your_api_key")
 *     .projectSlug("my-project")
 *     .onError(e -> logger.warn("Toggle error: {}", e.getMessage()))
 *     .build();
 *
 * if (client.isEnabled("dark-mode", "PROD")) {
 *     // feature is on
 * }
 * }</pre>
 *
 * @see TogliClients#builder()
 */
public interface TogliClient extends AutoCloseable {

    /**
     * Checks whether the named toggle is enabled in the default environment.
     *
     * <p>Requires a default environment to be set via
     * {@code .defaultEnvironment("PROD")} in the builder. Returns {@code false}
     * if the toggle does not exist or if any error occurs.
     *
     * @param toggleName the toggle name (case-sensitive), must not be {@code null}
     * @return {@code true} if the toggle is enabled, {@code false} otherwise
     * @throws IllegalStateException if no default environment is configured
     */
    boolean isEnabled(String toggleName);

    /**
     * Checks whether the named toggle is enabled in the given environment.
     *
     * <p>Returns {@code false} if the toggle does not exist, if the environment
     * is not assigned to the toggle, or if any error occurs (network, server, etc.).
     *
     * @param toggleName      the toggle name (case-sensitive), must not be {@code null}
     * @param environmentName the environment name to evaluate, must not be {@code null}
     * @return {@code true} if the toggle is enabled, {@code false} otherwise
     */
    boolean isEnabled(String toggleName, String environmentName);

    /**
     * Retrieves the full toggle definition by name.
     *
     * @param toggleName the toggle name (case-sensitive), must not be {@code null}
     * @return the toggle, never {@code null}
     * @throws com.homni.togli.sdk.domain.exception.TogliNotFoundException if the toggle does not exist
     */
    Toggle toggle(String toggleName);

    /**
     * Returns all toggles in the project.
     *
     * @return an unmodifiable list of all toggles, never {@code null}
     */
    List<Toggle> allToggles();

    /**
     * Returns all environments in the project.
     *
     * @return an unmodifiable list of all environments, never {@code null}
     */
    List<EnvironmentInfo> allEnvironments();

    /**
     * Returns the cached project information.
     *
     * @return the project info, never {@code null}
     */
    ProjectInfo projectInfo();

    /**
     * Evaluates a toggle in the default environment and runs one of two actions.
     *
     * <pre>{@code
     * client.evaluate("dark-mode",
     *     () -> renderNewDesign(),
     *     () -> renderOldDesign());
     * }</pre>
     *
     * @param toggleName the toggle name (case-sensitive), must not be {@code null}
     * @param enabled    action to run if the toggle is on
     * @param disabled   action to run if the toggle is off
     * @throws IllegalStateException if no default environment is configured
     */
    void evaluate(String toggleName, Runnable enabled, Runnable disabled);

    /**
     * Evaluates a toggle in the given environment and runs one of two actions.
     *
     * @param toggleName      the toggle name (case-sensitive), must not be {@code null}
     * @param environmentName the environment name, must not be {@code null}
     * @param enabled         action to run if the toggle is on
     * @param disabled        action to run if the toggle is off
     */
    void evaluate(String toggleName, String environmentName, Runnable enabled, Runnable disabled);

    /**
     * Evaluates a toggle in the default environment and returns one of two values.
     *
     * <pre>{@code
     * String theme = client.evaluate("dark-mode",
     *     () -> "dark",
     *     () -> "light");
     * }</pre>
     *
     * @param <T>        the return type
     * @param toggleName the toggle name (case-sensitive), must not be {@code null}
     * @param enabled    supplier called if the toggle is on
     * @param disabled   supplier called if the toggle is off
     * @return the result of the chosen supplier
     * @throws IllegalStateException if no default environment is configured
     */
    <T> T evaluate(String toggleName, Supplier<T> enabled, Supplier<T> disabled);

    /**
     * Evaluates a toggle in the given environment and returns one of two values.
     *
     * @param <T>             the return type
     * @param toggleName      the toggle name (case-sensitive), must not be {@code null}
     * @param environmentName the environment name, must not be {@code null}
     * @param enabled         supplier called if the toggle is on
     * @param disabled        supplier called if the toggle is off
     * @return the result of the chosen supplier
     */
    <T> T evaluate(String toggleName, String environmentName, Supplier<T> enabled, Supplier<T> disabled);

    /**
     * Creates a dynamic proxy that routes method calls based on toggle state.
     *
     * <p>Methods annotated with {@link FeatureToggle} are routed:
     * <ul>
     *   <li>toggle ON &rarr; calls the method on the {@code enabled} implementation</li>
     *   <li>toggle OFF &rarr; calls the method on the {@code disabled} implementation</li>
     * </ul>
     *
     * <p>Methods <b>without</b> the annotation always call the {@code enabled}
     * (primary) implementation.
     *
     * <pre>{@code
     * public interface CheckoutService {
     *     @FeatureToggle(name = "new-checkout")
     *     PaymentResult checkout(Order order);
     * }
     *
     * CheckoutService service = client.proxy(
     *     CheckoutService.class,
     *     new NewCheckout(),
     *     new LegacyCheckout());
     *
     * service.checkout(order); // routed by toggle state
     * }</pre>
     *
     * @param <T>      the interface type
     * @param type     the interface class, must not be {@code null}
     * @param enabled  implementation used when the toggle is ON, must not be {@code null}
     * @param disabled implementation used when the toggle is OFF, must not be {@code null}
     * @return a proxy that routes calls based on toggle state
     * @throws IllegalArgumentException if {@code type} is not an interface
     */
    <T> T proxy(Class<T> type, T enabled, T disabled);

    /**
     * Forces an immediate cache refresh.
     *
     * <p>If caching is disabled, this method is a no-op.
     */
    void refresh();

    /**
     * Closes this client and releases all resources (e.g. background polling threads).
     */
    @Override
    void close();
}
