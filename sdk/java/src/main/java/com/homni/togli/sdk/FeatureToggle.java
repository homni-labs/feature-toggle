/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks an interface method for toggle-based routing.
 *
 * <p>When used with {@link TogliClient#proxy(Class, Object, Object)}, the SDK
 * checks the toggle state on each invocation and routes the call to either
 * the {@code enabled} or {@code disabled} implementation.
 *
 * <p>Methods without this annotation always call the {@code enabled} (primary)
 * implementation.
 *
 * <pre>{@code
 * public interface CheckoutService {
 *     @FeatureToggle(name = "new-checkout")
 *     PaymentResult checkout(Order order);
 * }
 *
 * CheckoutService service = client.proxy(
 *     CheckoutService.class,
 *     new NewCheckout(),      // toggle ON
 *     new LegacyCheckout());  // toggle OFF
 *
 * service.checkout(order); // SDK routes based on toggle state
 * }</pre>
 *
 * @see TogliClient#proxy(Class, Object, Object)
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface FeatureToggle {

    /**
     * Toggle name (case-sensitive).
     *
     * @return the toggle name
     */
    String name();

    /**
     * Environment name (e.g. "PROD", "DEV").
     *
     * <p>If empty (default), the {@code defaultEnvironment} from the builder is used.
     *
     * @return the environment name, or empty string for default
     */
    String environment() default "";
}
