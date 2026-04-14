/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.http;

import java.util.Iterator;
import java.util.List;

import com.homni.togli.sdk.domain.exception.TogliParsingException;

/**
 * Lightweight wrapper around a {@link List} representing a parsed JSON array.
 *
 * <p>Implements {@link Iterable} over {@link JsonObject} elements for convenient
 * for-each iteration when the array contains only objects.
 */
final class JsonArray implements Iterable<JsonObject> {

    private final List<Object> data;

    /**
     * Creates a new JSON array backed by the given list.
     *
     * @param data the array elements, must not be {@code null}
     */
    JsonArray(List<Object> data) {
        if (data == null) {
            throw new TogliParsingException("JSON array data must not be null");
        }
        this.data = data;
    }

    /**
     * Returns the number of elements in this array.
     *
     * @return the element count
     */
    int size() {
        return data.size();
    }

    /**
     * Returns the JSON object at the given index.
     *
     * @param index zero-based index
     * @return the object at that index
     * @throws TogliParsingException if the index is out of bounds or the element is not an object
     */
    JsonObject object(int index) {
        Object value = element(index);
        if (value instanceof JsonObject obj) {
            return obj;
        }
        throw new TogliParsingException(
                "Expected object at index " + index + ", got " + typeName(value));
    }

    /**
     * Returns the string at the given index.
     *
     * @param index zero-based index
     * @return the string at that index
     * @throws TogliParsingException if the index is out of bounds or the element is not a string
     */
    String string(int index) {
        Object value = element(index);
        if (value instanceof String s) {
            return s;
        }
        throw new TogliParsingException(
                "Expected string at index " + index + ", got " + typeName(value));
    }

    /**
     * Returns an iterator over the array elements, treating each as a {@link JsonObject}.
     *
     * @return an iterator of JSON objects
     * @throws TogliParsingException if any element is not a {@link JsonObject}
     */
    @Override
    public Iterator<JsonObject> iterator() {
        return new Iterator<>() {
            private int cursor = 0;

            @Override
            public boolean hasNext() {
                return cursor < data.size();
            }

            @Override
            public JsonObject next() {
                return object(cursor++);
            }
        };
    }

    private Object element(int index) {
        if (index < 0 || index >= data.size()) {
            throw new TogliParsingException(
                    "Index " + index + " out of bounds for array of size " + data.size());
        }
        return data.get(index);
    }

    private static String typeName(Object value) {
        return value == null ? "null" : value.getClass().getSimpleName();
    }
}
