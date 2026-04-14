package com.homni.togli.example;

import com.homni.togli.sdk.TogliClient;
import com.homni.togli.sdk.domain.model.Toggle;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * E-commerce store that uses feature toggles to control behavior.
 *
 * <p>Imagine a real store where product team manages features via Togli dashboard:
 * <ul>
 *   <li>"dark-mode" — new UI theme</li>
 *   <li>"new-checkout" — redesigned checkout flow</li>
 *   <li>"free-shipping" — promotional free shipping</li>
 * </ul>
 *
 * Create these toggles in your Togli project to see the example in action.
 */
@RestController
@RequestMapping("/store")
public class ToggleController {

    private final TogliClient togli;
    private final CheckoutService checkout;

    public ToggleController(TogliClient togli) {
        this.togli = togli;

        // proxy() — SDK routes to new or legacy checkout based on toggle state
        this.checkout = togli.proxy(
                CheckoutService.class,
                new NewCheckout(),
                new LegacyCheckout());
    }

    /**
     * GET /store/theme
     *
     * isEnabled() — simple boolean check.
     * Toggle "dark-mode" controls the UI theme.
     */
    @GetMapping("/theme")
    public Map<String, Object> theme() {
        boolean darkMode = togli.isEnabled("dark-mode");
        return Map.of(
                "theme", darkMode ? "dark" : "light",
                "toggle", "dark-mode",
                "enabled", darkMode);
    }

    /**
     * GET /store/checkout
     *
     * proxy() — interface routing.
     * Toggle "new-checkout" switches between new and legacy checkout.
     */
    @GetMapping("/checkout")
    public Map<String, Object> checkout() {
        String result = checkout.process("order-42", 99.90);
        return Map.of("result", result);
    }

    /**
     * GET /store/shipping
     *
     * evaluate() — inline fallback with return value.
     * Toggle "free-shipping" controls shipping cost.
     */
    @GetMapping("/shipping")
    public Map<String, Object> shipping() {
        double cost = togli.evaluate("free-shipping",
                () -> 0.0,
                () -> 9.99);
        return Map.of(
                "shippingCost", cost,
                "freeShipping", cost == 0.0);
    }

    /**
     * GET /store/banner
     *
     * evaluate() — void fallback.
     * Toggle "promo-banner" shows or hides a promotional banner.
     */
    @GetMapping("/banner")
    public Map<String, String> banner() {
        String[] message = {""};
        togli.evaluate("promo-banner",
                () -> message[0] = "Summer Sale — 30% OFF everything!",
                () -> message[0] = "Welcome to our store.");
        return Map.of("banner", message[0]);
    }

    /**
     * GET /store/debug
     *
     * allToggles() + projectInfo() — introspection.
     */
    @GetMapping("/debug")
    public Map<String, Object> debug() {
        var project = togli.projectInfo();
        var toggles = togli.allToggles().stream()
                .map(t -> Map.of(
                        "name", t.name,
                        "environments", t.environments.stream()
                                .map(s -> s.environmentName() + "=" + s.enabled())
                                .toList()))
                .toList();
        return Map.of(
                "project", project.name,
                "toggleCount", togli.allToggles().size(),
                "toggles", toggles);
    }
}
