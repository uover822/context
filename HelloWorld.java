import com.google.gson.Gson;
import io.javalin.Javalin;
import io.javalin.json.JavalinJson;

import java.util.HashSet;

import io.javalin.serversentevent.SseClient; // offending class
import java.util.Queue;

public class HelloWorld {
    public static void main(String[] args) {
        Gson gson = new Gson();

        JavalinJson.setFromJsonMapper(gson::fromJson);
        JavalinJson.setToJsonMapper(gson::toJson);

        Javalin app = Javalin.create().start(7070);
        app.post("/reason/descriptor", ctx -> {
            System.out.println("Body as string: " + ctx.body());

            Descriptor descriptor = ctx.bodyAsClass(Descriptor.class);

            ctx.result(descriptor.pid);
        });
    }

	public static class Descriptor {
		public String pid;
		public HashSet<String> sources;
		public HashSet<String> targets;
		public Queue<SseClient> clients; // comment/ uncomment this

		public Descriptor(String pid, HashSet<String> sources, HashSet<String> targets) {
			this.pid = pid;
			this.sources = sources;
			this.targets = targets;
		}
	}
}
