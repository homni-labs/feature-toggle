/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.http;

import java.util.Map;
import java.util.Optional;

import com.homni.togli.sdk.domain.exception.TogliParsingException;

/**
 * Lightweight wrapper around a {@link Map} representing a parsed JSON object.
 *
 * <p>Internal values may be: {@link String}, {@link Number} ({@link Double} or
 * {@link Long}), {@link Boolean}, {@code null}, {@link JsonObject}, or
 * {@link JsonArray}.
 */
final class JsonObject {

    private final Map<String, Object> data;

    /**
     * Creates a new JSON object backed by the given map.
     *
     * @param data the key-value pairs, must not be {@code null}
     */
    JsonObject(Map<String, Object> data) {
        if (data == null) {
            throw new TogliParsingException("JSON object data must not be null");
        }
        this.data = data;
    }

    /**
     * Returns the string value for the given key.
     *
     * @param key the JSON key
     * @return the string value
     * @throws TogliParsingException if the key is missing or the value is not a string
     */
    String string(String key) {
        Object value = require(key);
        if (value instanceof String s) {
            return s;
        }
        throw new TogliParsingException("Expected string for key '" + key + "', got " + typeName(value));
    }

    /**
     * Returns an optional string value for the given key.
     *
     * @param key the JSON key
     * @return the string value, or {@link Optional#empty()} if the key is missing or the value is {@code null}
     */
    Optional<String> optString(String key) {
        Object value = data.get(key);
        if (value == null) {
            return Optional.empty();
        }
        if (value instanceof String s) {
            return Optional.of(s);
        }
        throw new TogliParsingException("Expected string for key '" + key + "', got " + typeName(value));
    }

    /**
     * Returns the integer value for the given key.
     *
     * @param key the JSON key
     * @return the int value
     * @throws TogliParsingException if the key is missing or the value is not a number
     */
    int integer(String key) {
        Object value = require(key);
        if (value instanceof Number n) {
            return n.intValue();
        }
        throw new TogliParsingException("Expected number for key '" + key + "', got " + typeName(value));
    }

    /**
     * Returns the long value for the given key.
     *
     * @param key the JSON key
     * @return the long value
     * @throws TogliParsingException if the key is missing or the value is not a number
     */
    long longValue(String key) {
        Object value = require(key);
        if (value instanceof Number n) {
            return n.longValue();
        }
        throw new TogliParsingException("Expected number for key '" + key + "', got " + typeName(value));
    }

    /**
     * Returns the boolean value for the given key.
     *
     * @param key the JSON key
     * @return the boolean value
     * @throws TogliParsingException if the key is missing or the value is not a boolean
     */
    boolean bool(String key) {
        Object value = require(key);
        if (value instanceof Boolean b) {
            return b;
        }
        throw new TogliParsingException("Expected boolean for key '" + key + "', got " + typeName(value));
    }

    /**
     * Returns the nested JSON object for the given key.
     *
     * @param key the JSON key
     * @return the nested object
     * @throws TogliParsingException if the key is missing or the value is not an object
     */
    JsonObject object(String key) {
        Object value = require(key);
        if (value instanceof JsonObject obj) {
            return obj;
        }
        throw new TogliParsingException("Expected object for key '" + key + "', got " + typeName(value));
    }

    /**
     * Returns the JSON array for the given key.
     *
     * @param key the JSON key
     * @return the array
     * @throws TogliParsingException if the key is missing or the value is not an array
     */
    JsonArray array(String key) {
        Object value = require(key);
        if (value instanceof JsonArray arr) {
            return arr;
        }
        throw new TogliParsingException("Expected array for key '" + key + "', got " + typeName(value));
    }

    /**
     * Returns an optional nested JSON object for the given key.
     *
     * @param key the JSON key
     * @return the nested object, or {@link Optional#empty()} if the key is missing or the value is {@code null}
     */
    Optional<JsonObject> optObject(String key) {
        Object value = data.get(key);
        if (value == null) {
            return Optional.empty();
        }
        if (value instanceof JsonObject obj) {
            return Optional.of(obj);
        }
        throw new TogliParsingException("Expected object for key '" + key + "', got " + typeName(value));
    }

    /**
     * Checks whether the given key exists in this object.
     *
     * @param key the JSON key
     * @return {@code true} if the key exists (even if the value is {@code null})
     */
    boolean hasKey(String key) {
        return data.containsKey(key);
    }

    private Object require(String key) {
        if (!data.containsKey(key)) {
            throw new TogliParsingException("Missing required key '" + key + "'");
        }
        Object value = data.get(key);
        if (value == null) {
            throw new TogliParsingException("Value for key '" + key + "' is null");
        }
        return value;
    }

    private static String typeName(Object value) {
        return value == null ? "null" : value.getClass().getSimpleName();
    }
}
