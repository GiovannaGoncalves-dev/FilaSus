package br.com.filasus.controller.api;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class ApiSupport {
    private static final Pattern STRING = Pattern.compile("\\\"([^\\\"]+)\\\"\\s*:\\s*\\\"((?:\\\\.|[^\\\"])*)\\\"");
    private static final Pattern PRIMITIVE = Pattern.compile("\\\"([^\\\"]+)\\\"\\s*:\\s*(true|false|-?\\d+)");
    private ApiSupport() {}

    static String body(HttpServletRequest request) throws IOException {
        return request.getReader().lines().reduce("", (a, b) -> a + b);
    }

    static String string(String json, String name) {
        Matcher matcher = STRING.matcher(json == null ? "" : json);
        while (matcher.find()) if (name.equals(matcher.group(1))) {
            return matcher.group(2).replace("\\\"", "\"").replace("\\\\", "\\");
        }
        return "";
    }

    static int integer(String json, String name, int fallback) {
        Matcher matcher = PRIMITIVE.matcher(json == null ? "" : json);
        while (matcher.find()) if (name.equals(matcher.group(1))) {
            try { return Integer.parseInt(matcher.group(2)); } catch (NumberFormatException ignored) { return fallback; }
        }
        String value = string(json, name);
        try { return Integer.parseInt(value); } catch (NumberFormatException ignored) { return fallback; }
    }

    static boolean bool(String json, String name, boolean fallback) {
        Matcher matcher = PRIMITIVE.matcher(json == null ? "" : json);
        while (matcher.find()) if (name.equals(matcher.group(1))) return Boolean.parseBoolean(matcher.group(2));
        return fallback;
    }

    static List<Integer> integers(String json, String name) {
        Matcher matcher = Pattern.compile("\\\"" + Pattern.quote(name) + "\\\"\\s*:\\s*\\[([^]]*)]").matcher(json);
        List<Integer> values = new ArrayList<>();
        if (matcher.find()) {
            Matcher number = Pattern.compile("\\d+").matcher(matcher.group(1));
            while (number.find()) values.add(Integer.parseInt(number.group()));
        }
        return values;
    }

    static String escape(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    static String quote(String value) { return value == null ? "null" : "\"" + escape(value) + "\""; }

    static void json(HttpServletResponse response, int status, String content) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(content);
    }

    static void error(HttpServletResponse response, int status, String message) throws IOException {
        json(response, status, "{\"error\":\"" + escape(message) + "\"}");
    }

    static int id(String value) {
        if (value == null) return 0;
        Matcher matcher = Pattern.compile("\\d+").matcher(value);
        return matcher.find() ? Integer.parseInt(matcher.group()) : 0;
    }

    static int[] itemId(String value) {
        Matcher matcher = Pattern.compile("(\\d+)[_:-](\\d+)").matcher(value == null ? "" : value);
        return matcher.find() ? new int[]{Integer.parseInt(matcher.group(1)), Integer.parseInt(matcher.group(2))} : new int[]{0, 0};
    }
}
