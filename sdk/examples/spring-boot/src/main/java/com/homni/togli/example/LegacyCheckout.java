package com.homni.togli.example;

/**
 * Legacy checkout flow — classic bank transfer.
 */
public class LegacyCheckout implements CheckoutService {

    @Override
    public String process(String orderId, double amount) {
        return "Order %s processed via LEGACY checkout (bank transfer, $%.2f)".formatted(orderId, amount);
    }
}
