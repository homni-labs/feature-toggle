package com.homni.togli.example;

import com.homni.togli.sdk.FeatureToggle;

/**
 * Checkout service interface. The SDK routes calls between
 * {@link NewCheckout} and {@link LegacyCheckout} based on
 * the "new-checkout" toggle state.
 */
public interface CheckoutService {

    @FeatureToggle(name = "new-checkout")
    String process(String orderId, double amount);
}
