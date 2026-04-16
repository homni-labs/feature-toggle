/*
 * Copyright (c) Homni Labs
 * Licensed under the MIT License
 */
package com.homni.togli.sdk.infrastructure.http;

import com.homni.togli.sdk.domain.exception.TogliParsingException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DisplayName("JsonParser")
class JsonParserTest {

    @Nested
    @DisplayName("valid JSON")
    class ValidJson {

        @Test
        @DisplayName("parses empty object")
        void parsesEmptyObject() {
            JsonObject obj = JsonParser.parse("{}");

            assertThat(obj).isNotNull();
        }

        @Test
        @DisplayName("parses string value")
        void parsesStringValue() {
            JsonObject obj = JsonParser.parse("{\"name\": \"dark-mode\"}");

            assertThat(obj.string("name")).isEqualTo("dark-mode");
        }

        @Test
        @DisplayName("parses integer value")
        void parsesIntegerValue() {
            JsonObject obj = JsonParser.parse("{\"count\": 42}");

            assertThat(obj.integer("count")).isEqualTo(42);
        }

        @Test
        @DisplayName("parses boolean values")
        void parsesBooleanValues() {
            JsonObject obj = JsonParser.parse("{\"enabled\": true, \"archived\": false}");

            assertThat(obj.bool("enabled")).isTrue();
            assertThat(obj.bool("archived")).isFalse();
        }

        @Test
        @DisplayName("parses null as absent optional")
        void parsesNullValue() {
            JsonObject obj = JsonParser.parse("{\"description\": null}");

            assertThat(obj.optString("description")).isEmpty();
        }

        @Test
        @DisplayName("parses nested object")
        void parsesNestedObject() {
            JsonObject obj = JsonParser.parse("{\"meta\": {\"timestamp\": \"2026-01-01\"}}");

            JsonObject meta = obj.object("meta");
            assertThat(meta.string("timestamp")).isEqualTo("2026-01-01");
        }

        @Test
        @DisplayName("parses array of objects")
        void parsesArray() {
            JsonObject obj = JsonParser.parse("{\"items\": [{\"name\": \"a\"}, {\"name\": \"b\"}]}");

            JsonArray items = obj.array("items");
            assertThat(items.size()).isEqualTo(2);
            assertThat(items.object(0).string("name")).isEqualTo("a");
            assertThat(items.object(1).string("name")).isEqualTo("b");
        }

        @Test
        @DisplayName("parses escaped characters in strings")
        void parsesEscapedCharacters() {
            JsonObject obj = JsonParser.parse("{\"text\": \"line1\\nline2\\ttab\"}");

            assertThat(obj.string("text")).isEqualTo("line1\nline2\ttab");
        }

        @Test
        @DisplayName("parses unicode escapes")
        void parsesUnicodeEscapes() {
            JsonObject obj = JsonParser.parse("{\"char\": \"\\u0041\"}");

            assertThat(obj.string("char")).isEqualTo("A");
        }

        @Test
        @DisplayName("parses floating point number")
        void parsesFloatingPoint() {
            JsonObject obj = JsonParser.parse("{\"value\": 3.14}");

            assertThat(obj).isNotNull();
        }

        @Test
        @DisplayName("parses negative number")
        void parsesNegativeNumber() {
            JsonObject obj = JsonParser.parse("{\"offset\": -10}");

            assertThat(obj.integer("offset")).isEqualTo(-10);
        }
    }

    @Nested
    @DisplayName("invalid JSON")
    class InvalidJson {

        @Test
        @DisplayName("rejects null input")
        void rejectsNull() {
            assertThatThrownBy(() -> JsonParser.parse(null))
                    .isInstanceOf(TogliParsingException.class);
        }

        @Test
        @DisplayName("rejects empty string")
        void rejectsEmpty() {
            assertThatThrownBy(() -> JsonParser.parse(""))
                    .isInstanceOf(TogliParsingException.class);
        }

        @Test
        @DisplayName("rejects malformed JSON")
        void rejectsMalformed() {
            assertThatThrownBy(() -> JsonParser.parse("{broken"))
                    .isInstanceOf(TogliParsingException.class);
        }

        @Test
        @DisplayName("rejects trailing content")
        void rejectsTrailingContent() {
            assertThatThrownBy(() -> JsonParser.parse("{} extra"))
                    .isInstanceOf(TogliParsingException.class);
        }

        @Test
        @DisplayName("rejects unterminated string")
        void rejectsUnterminatedString() {
            assertThatThrownBy(() -> JsonParser.parse("{\"key\": \"unterminated}"))
                    .isInstanceOf(TogliParsingException.class);
        }
    }

    @Nested
    @DisplayName("JsonObject accessors")
    class JsonObjectAccessors {

        @Test
        @DisplayName("optString returns value when present")
        void optStringPresent() {
            JsonObject obj = JsonParser.parse("{\"name\": \"test\"}");

            assertThat(obj.optString("name")).contains("test");
        }

        @Test
        @DisplayName("optString returns empty when key missing")
        void optStringMissing() {
            JsonObject obj = JsonParser.parse("{}");

            assertThat(obj.optString("name")).isEmpty();
        }

        @Test
        @DisplayName("optObject returns nested object when present")
        void optObjectPresent() {
            JsonObject obj = JsonParser.parse("{\"meta\": {\"key\": \"val\"}}");

            assertThat(obj.optObject("meta")).isPresent();
            assertThat(obj.optObject("meta").get().string("key")).isEqualTo("val");
        }

        @Test
        @DisplayName("optObject returns empty when key missing")
        void optObjectMissing() {
            JsonObject obj = JsonParser.parse("{}");

            assertThat(obj.optObject("meta")).isEmpty();
        }

        @Test
        @DisplayName("hasKey returns true for existing key")
        void hasKeyTrue() {
            JsonObject obj = JsonParser.parse("{\"name\": \"test\"}");

            assertThat(obj.hasKey("name")).isTrue();
        }

        @Test
        @DisplayName("hasKey returns false for missing key")
        void hasKeyFalse() {
            JsonObject obj = JsonParser.parse("{}");

            assertThat(obj.hasKey("name")).isFalse();
        }

        @Test
        @DisplayName("string throws on missing key")
        void stringThrowsOnMissing() {
            JsonObject obj = JsonParser.parse("{}");

            assertThatThrownBy(() -> obj.string("missing"))
                    .isInstanceOf(TogliParsingException.class);
        }

        @Test
        @DisplayName("long value accessor works")
        void longValueAccessor() {
            JsonObject obj = JsonParser.parse("{\"total\": 9999999999}");

            assertThat(obj.longValue("total")).isEqualTo(9999999999L);
        }
    }

    @Nested
    @DisplayName("JsonArray accessors")
    class JsonArrayAccessors {

        @Test
        @DisplayName("iterates over array of objects")
        void iteratesObjects() {
            JsonObject obj = JsonParser.parse("{\"items\": [{\"n\": 1}, {\"n\": 2}, {\"n\": 3}]}");
            JsonArray items = obj.array("items");

            int count = 0;
            for (JsonObject item : items) {
                count++;
                assertThat(item.integer("n")).isGreaterThan(0);
            }
            assertThat(count).isEqualTo(3);
        }

        @Test
        @DisplayName("string accessor by index")
        void stringByIndex() {
            JsonObject obj = JsonParser.parse("{\"tags\": [\"a\", \"b\"]}");
            JsonArray tags = obj.array("tags");

            assertThat(tags.string(0)).isEqualTo("a");
            assertThat(tags.string(1)).isEqualTo("b");
        }

        @Test
        @DisplayName("throws on out-of-bounds index")
        void throwsOnOutOfBounds() {
            JsonObject obj = JsonParser.parse("{\"items\": []}");
            JsonArray items = obj.array("items");

            assertThatThrownBy(() -> items.object(0))
                    .isInstanceOf(TogliParsingException.class);
        }
    }
}
