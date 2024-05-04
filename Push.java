package sse;

import kong.unirest.Unirest;
import io.prometheus.client.exporter.HTTPServer;
import io.prometheus.client.Gauge;
import java.net.InetAddress;
import java.net.UnknownHostException;

public class Push {

	private static final Gauge endTs = Gauge.build()
		.name("perf_push_descriptor_rsn_ts")
		.help("ts for push reasoner")
		.labelNames("event","return_code","service","cluster","app","user","ip","cid")
		.register();

	public static void main(String value) {

		long beginTs = System.currentTimeMillis();

		try {
			System.out.println("p-v:"+value);
			Unirest.post("http://localhost:4567/push")
				.body("{\"value\":\""+value.substring(value.indexOf("+")+1, value.indexOf("_")+1)+value.substring(value.indexOf("_")+1).replace("_", " ")+"\"}")
				.asString();
		}catch(Exception e){
			e.printStackTrace();
		}
		finally {
			Unirest.shutDown();
		}

		InetAddress ip = null;
		try {
			ip = InetAddress.getLocalHost();
		}catch(UnknownHostException e){
			e.printStackTrace();
		}

		endTs
			.labels("descriptor.rsn", "200", "context", System.getenv("cluster"), System.getenv("app"), System.getenv("user"), ip.getHostAddress(), value.substring(0, value.indexOf("+")))
			.set(beginTs + 1.0 / (System.currentTimeMillis() - beginTs));
	}
}
