import io.javalin.http.sse.SseClient
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

object ClientEventService {

    init {
        Executors.newSingleThreadScheduledExecutor().scheduleAtFixedRate({ broadcast("heartbeat") }, /*delay=*/0,  /*period=*/5, TimeUnit.SECONDS)
    }

    private val clients = ConcurrentHashMap.newKeySet<SseClient>()

    fun registerClient(client: SseClient) {
        clients.add(client)
        client.onClose { clients.remove(client) }
    }

    fun broadcast(msg: String) = clients.forEach { it.sendEvent("server-event", msg) }

}