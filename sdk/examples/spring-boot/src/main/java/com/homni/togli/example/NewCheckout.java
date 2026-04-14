package com.homni.togli.example;

/**
 * New checkout flow — Stripe integration, one-click payments.
 */
public class NewCheckout implements CheckoutService {

    @Override
    public String process(String orderId, double amount) {
        return "Order %s processed via NEW checkout (Stripe, $%.2f)".formatted(orderId, amount);
    }
}
