import kong.unirest.Unirest;

@SuppressWarnings(value={"unchecked"})
public class Client {
	public static void main(String[] args) {
		Unirest.post("http://192.168.1.6:4567/push")
			.body("{\"value\":\"this is a test\"}")
			.asString();
		Unirest.shutDown();
	}
}
