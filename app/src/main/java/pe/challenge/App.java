package pe.challenge;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;

public final class App {
    private App() { }

    public static HttpServer createServer(int port) throws IOException {
        var server = HttpServer.create(new InetSocketAddress("0.0.0.0", port), 0);
        server.createContext("/", exchange -> {
            String path = exchange.getRequestURI().getPath();
            int status;
            String body;
            if (!"GET".equals(exchange.getRequestMethod())) {
                status = 405;
                body = "{\"error\":\"Method not allowed\"}";
                exchange.getResponseHeaders().set("Allow", "GET");
            } else if ("/health".equals(path)) {
                status = 200;
                body = "{\"status\":\"UP\"}";
            } else if ("/".equals(path) || "/api/hello".equals(path)) {
                status = 200;
                body = "{\"message\":\"Hola Mundo\",\"service\":\"java-ecs-api\"}";
            } else {
                status = 404;
                body = "{\"error\":\"Not found\"}";
            }
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
            exchange.getResponseHeaders().set("X-Content-Type-Options", "nosniff");
            exchange.sendResponseHeaders(status, bytes.length);
            try (var output = exchange.getResponseBody()) { output.write(bytes); }
            System.out.printf("method=%s path=%s status=%d%n", exchange.getRequestMethod(), path, status);
            exchange.close();
        });
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        return server;
    }

    public static void main(String[] args) throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        var server = createServer(port);
        Runtime.getRuntime().addShutdownHook(new Thread(() -> server.stop(5)));
        server.start();
        System.out.printf("Listening on port %d%n", port);
    }
}
