/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.http;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.homni.togli.sdk.domain.exception.TogliParsingException;

/**
 * Hand-rolled recursive-descent JSON parser.
 *
 * <p>Parses a JSON string into {@link JsonObject} / {@link JsonArray} wrappers
 * using only standard library types. No external dependencies are required.
 */
final class JsonParser {

    private final char[] chars;
    private int pos;

    private JsonParser(char[] chars) {
        this.chars = chars;
        this.pos = 0;
    }

    /**
     * Parses a JSON string into a {@link JsonObject}.
     *
     * @param json the JSON string to parse, must not be {@code null}
     * @return the parsed object
     * @throws TogliParsingException if the input is {@code null}, empty, or malformed
     */
    static JsonObject parse(String json) {
        if (json == null || json.isEmpty()) {
            throw new TogliParsingException("JSON input must not be null or empty");
        }
        JsonParser parser = new JsonParser(json.toCharArray());
        parser.skipWhitespace();
        if (parser.pos >= parser.chars.length || parser.chars[parser.pos] != '{') {
            throw parser.error("Expected '{' at start of JSON object");
        }
        JsonObject result = parser.parseObject();
        parser.skipWhitespace();
        if (parser.pos < parser.chars.length) {
            throw parser.error("Unexpected trailing content");
        }
        return result;
    }

    private Object parseValue() {
        skipWhitespace();
        if (pos >= chars.length) {
            throw error("Unexpected end of input");
        }
        return switch (chars[pos]) {
            case '{' -> parseObject();
            case '[' -> parseArray();
            case '"' -> parseString();
            case 't', 'f', 'n' -> parseLiteral();
            default -> {
                if (chars[pos] == '-' || (chars[pos] >= '0' && chars[pos] <= '9')) {
                    yield parseNumber();
                }
                throw error("Unexpected character '" + chars[pos] + "'");
            }
        };
    }

    private JsonObject parseObject() {
        expect('{');
        Map<String, Object> map = new LinkedHashMap<>();
        skipWhitespace();
        if (pos < chars.length && chars[pos] == '}') {
            pos++;
            return new JsonObject(map);
        }
        while (true) {
            skipWhitespace();
            if (pos >= chars.length || chars[pos] != '"') {
                throw error("Expected '\"' for object key");
            }
            String key = parseString();
            skipWhitespace();
            expect(':');
            Object value = parseValue();
            map.put(key, value);
            skipWhitespace();
            if (pos >= chars.length) {
                throw error("Unexpected end of input in object");
            }
            if (chars[pos] == '}') {
                pos++;
                return new JsonObject(map);
            }
            expect(',');
        }
    }

    private JsonArray parseArray() {
        expect('[');
        List<Object> list = new ArrayList<>();
        skipWhitespace();
        if (pos < chars.length && chars[pos] == ']') {
            pos++;
            return new JsonArray(list);
        }
        while (true) {
            Object value = parseValue();
            list.add(value);
            skipWhitespace();
            if (pos >= chars.length) {
                throw error("Unexpected end of input in array");
            }
            if (chars[pos] == ']') {
                pos++;
                return new JsonArray(list);
            }
            expect(',');
        }
    }

    private String parseString() {
        expect('"');
        StringBuilder sb = new StringBuilder();
        while (pos < chars.length) {
            char c = chars[pos++];
            if (c == '"') {
                return sb.toString();
            }
            if (c == '\\') {
                if (pos >= chars.length) {
                    throw error("Unexpected end of input in string escape");
                }
                char escaped = chars[pos++];
                switch (escaped) {
                    case '"' -> sb.append('"');
                    case '\\' -> sb.append('\\');
                    case '/' -> sb.append('/');
                    case 'n' -> sb.append('\n');
                    case 't' -> sb.append('\t');
                    case 'r' -> sb.append('\r');
                    case 'b' -> sb.append('\b');
                    case 'f' -> sb.append('\f');
                    case 'u' -> sb.append(parseUnicodeEscape());
                    default -> throw error("Invalid escape sequence '\\" + escaped + "'");
                }
            } else {
                sb.append(c);
            }
        }
        throw error("Unterminated string");
    }

    private char parseUnicodeEscape() {
        if (pos + 4 > chars.length) {
            throw error("Incomplete unicode escape");
        }
        String hex = new String(chars, pos, 4);
        pos += 4;
        try {
            return (char) Integer.parseInt(hex, 16);
        } catch (NumberFormatException e) {
            throw error("Invalid unicode escape '\\u" + hex + "'");
        }
    }

    private Number parseNumber() {
        int start = pos;
        if (pos < chars.length && chars[pos] == '-') {
            pos++;
        }
        if (pos >= chars.length) {
            throw error("Unexpected end of input in number");
        }
        if (chars[pos] == '0') {
            pos++;
        } else if (chars[pos] >= '1' && chars[pos] <= '9') {
            pos++;
            while (pos < chars.length && chars[pos] >= '0' && chars[pos] <= '9') {
                pos++;
            }
        } else {
            throw error("Invalid number");
        }
        boolean isFloat = false;
        if (pos < chars.length && chars[pos] == '.') {
            isFloat = true;
            pos++;
            if (pos >= chars.length || chars[pos] < '0' || chars[pos] > '9') {
                throw error("Expected digit after decimal point");
            }
            while (pos < chars.length && chars[pos] >= '0' && chars[pos] <= '9') {
                pos++;
            }
        }
        if (pos < chars.length && (chars[pos] == 'e' || chars[pos] == 'E')) {
            isFloat = true;
            pos++;
            if (pos < chars.length && (chars[pos] == '+' || chars[pos] == '-')) {
                pos++;
            }
            if (pos >= chars.length || chars[pos] < '0' || chars[pos] > '9') {
                throw error("Expected digit in exponent");
            }
            while (pos < chars.length && chars[pos] >= '0' && chars[pos] <= '9') {
                pos++;
            }
        }
        String raw = new String(chars, start, pos - start);
        try {
            if (isFloat) {
                return Double.parseDouble(raw);
            }
            return Long.parseLong(raw);
        } catch (NumberFormatException e) {
            throw error("Invalid number '" + raw + "'");
        }
    }

    private Object parseLiteral() {
        if (matches("true")) {
            return Boolean.TRUE;
        }
        if (matches("false")) {
            return Boolean.FALSE;
        }
        if (matches("null")) {
            return null;
        }
        throw error("Unexpected literal");
    }

    private boolean matches(String literal) {
        int len = literal.length();
        if (pos + len > chars.length) {
            return false;
        }
        for (int i = 0; i < len; i++) {
            if (chars[pos + i] != literal.charAt(i)) {
                return false;
            }
        }
        pos += len;
        return true;
    }

    private void skipWhitespace() {
        while (pos < chars.length) {
            char c = chars[pos];
            if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
                pos++;
            } else {
                break;
            }
        }
    }

    private void expect(char expected) {
        if (pos >= chars.length) {
            throw error("Expected '" + expected + "' but reached end of input");
        }
        if (chars[pos] != expected) {
            throw error("Expected '" + expected + "' but found '" + chars[pos] + "'");
        }
        pos++;
    }

    private TogliParsingException error(String message) {
        return new TogliParsingException(message + " at position " + pos);
    }
}
