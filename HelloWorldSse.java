/*
 * Javalin - https://javalin.io
 * Copyright 2017 David Åse
 * Licensed under Apache 2.0: https://github.com/tipsy/javalin/blob/master/LICENSE
 */

import io.javalin.Javalin;
import io.javalin.serversentevent.SseClient;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.TimeUnit;

public class HelloWorldSse {

    public static void main(String[] args) throws InterruptedException {

        Queue<SseClient> clients = new ConcurrentLinkedQueue<>();

        Javalin app = Javalin.create().start(7000);
        app.get("/", ctx -> ctx.html("<meta http-equiv='content-type' content='text/html; charset=utf-8' /><script>new EventSource('http://localhost:7000/sse').addEventListener('hi', msg => console.log(msg));</script>"));
        app.sse("/sse", client -> {
            clients.add(client);
            client.onClose(() -> clients.remove(client));
        });

        while (true) {
            for (SseClient client : clients) {
                client.sendEvent("hi", "hello world");
            }
            TimeUnit.SECONDS.sleep(1);
        }

    }

}
