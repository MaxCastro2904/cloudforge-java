package pe.challenge;

import com.sun.net.httpserver.HttpServer;
import java.net.URI;
import java.net.http.*;
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

class AppTest {
    static HttpServer server;
    static String base;
    static final HttpClient client = HttpClient.newHttpClient();
    @BeforeAll static void start() throws Exception {
        server = App.createServer(0);
        server.start();
        base = "http://127.0.0.1:" + server.getAddress().getPort();
    }
    @AfterAll static void stop() { server.stop(0); }
    HttpResponse<String> get(String path) throws Exception {
        return client.send(HttpRequest.newBuilder(URI.create(base + path)).GET().build(), HttpResponse.BodyHandlers.ofString());
    }
    @Test void hello() throws Exception {
        var response = get("/api/hello");
        assertEquals(200, response.statusCode());
        assertTrue(response.body().contains("Hola Mundo"));
        assertTrue(response.headers().firstValue("Content-Type").orElse("").contains("application/json"));
    }
    @Test void health() throws Exception { assertEquals("{\"status\":\"UP\"}", get("/health").body()); }
    @Test void root() throws Exception { assertEquals(200, get("/").statusCode()); }
    @Test void unknownPath() throws Exception { assertEquals(404, get("/health/unknown").statusCode()); }
    @Test void unsupportedMethod() throws Exception {
        var request = HttpRequest.newBuilder(URI.create(base + "/api/hello")).POST(HttpRequest.BodyPublishers.noBody()).build();
        var response = client.send(request, HttpResponse.BodyHandlers.ofString());
        assertEquals(405, response.statusCode());
        assertEquals("GET", response.headers().firstValue("Allow").orElseThrow());
    }
}
