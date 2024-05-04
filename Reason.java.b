import io.javalin.Javalin;
import io.javalin.json.JsonMapper;
import java.lang.reflect.Type;
import org.jetbrains.annotations.NotNull;
import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Collections;
import java.util.Comparator;
import java.util.stream.Collectors;

import java.io.StringReader;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import org.drools.kiesession.rulebase.InternalKnowledgeBase;
import org.drools.kiesession.rulebase.KnowledgeBaseFactory;
import org.kie.internal.builder.KnowledgeBuilder;
import org.kie.internal.builder.KnowledgeBuilderFactory;
import org.kie.internal.builder.KnowledgeBuilderConfiguration;
import org.kie.api.KieServices;
import org.kie.api.runtime.KieContainer;
import org.kie.api.definition.KiePackage;
import org.kie.api.runtime.KieSession;
import org.kie.api.io.ResourceType;
import org.kie.internal.io.ResourceFactory;
import org.kie.api.builder.Results;
import org.kie.api.runtime.rule.FactHandle;

import org.apache.commons.lang3.RandomStringUtils;
	
import javassist.ClassPool;
import javassist.CtClass;
import javassist.CtNewConstructor;
import javassist.CtField;
import javassist.CtMethod;
import javassist.CtNewMethod;
import javassist.CannotCompileException;

import io.javalin.http.sse.SseClient;
import io.javalin.websocket.WsContext;
import java.util.concurrent.ConcurrentHashMap;
import java.util.ConcurrentModificationException;
import java.util.Arrays;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.charset.Charset;
import java.io.IOException;

import java.net.URLDecoder;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.net.URL;
import java.net.URLClassLoader;

import org.eclipse.jetty.server.handler.StatisticsHandler;
import org.eclipse.jetty.util.thread.QueuedThreadPool;
import org.eclipse.jetty.server.Server;
import io.prometheus.client.exporter.HTTPServer;
import io.prometheus.client.Gauge;

import edu.stanford.nlp.ling.*;
import edu.stanford.nlp.pipeline.*;

import java.nio.file.StandardOpenOption;

@SuppressWarnings(value={"unchecked"})
public class Reason {

	private static Map<String, Rule> rules = new HashMap<String, Rule>();
	private static Map<String, Descriptor> descriptors = new HashMap<String, Descriptor>();
	private static Map<String, Associate> associates = new HashMap<String, Associate>();
	private static Map<String, Relation> relations = new HashMap<String, Relation>();
	/*
	private static Map<String, SseClient> pushClients = new ConcurrentHashMap<String, SseClient>();
	private static Map<String, SseClient> iotClients = new ConcurrentHashMap<String, SseClient>();
	*/
	private static Map<String, WsContext> pushClients = new ConcurrentHashMap<String, WsContext>();
	private static Map<String, WsContext> iotClients = new ConcurrentHashMap<String, WsContext>();
	/**/

	private static final Gauge endTs = Gauge.build()
		.name("perf_context_descriptor_rsn_ts")
		.help("ts for context reasoner")
		.labelNames("event","return_code","service","cluster","app","user","ip","cid")
		.register();

	public static void main(String[] args) {
		try {
			Reason reason = new Reason();
			reason.run (args);
    }catch (Exception e) {
			e.printStackTrace();
    }
	}

	public void run(String[] args) throws Exception {

		Gson gson = new GsonBuilder().create();
		JsonMapper gsonMapper = new JsonMapper() {
				@Override
				public String toJsonString(@NotNull Object obj, @NotNull Type type) {
					return gson.toJson(obj, type);
				}

				@Override
				public <T> T fromJsonString(@NotNull String json, @NotNull Type targetType) {
					return gson.fromJson(json, targetType);
				}
			};

		StatisticsHandler statisticsHandler = new StatisticsHandler();
    QueuedThreadPool queuedThreadPool = new QueuedThreadPool(200, 8, 60_000);
    initializePrometheus(statisticsHandler, queuedThreadPool);

    Javalin app = Javalin.create(config -> {
        config.jetty.server(() -> {
            Server server = new Server(queuedThreadPool);
            server.setHandler(statisticsHandler);
            return server;
					});
				config.jsonMapper(gsonMapper);
			}).start(4567);

		// Delete a descriptor resource by id
		app.get("/reason/reason/{id}/{cid}", ctx -> {
				String id = ctx.pathParam("id");
				String cid = ctx.pathParam("cid");
				Descriptor descriptor = descriptors.get(id);
				if (descriptor != null) {
					if (descriptor.getType().equals("instance") ||
							descriptor.getType().equals("derived")) {
						descriptor.setServer(this);
						descriptor.setCid(cid);
						descriptor.reason();
					}
					ctx.status(200);
				}
				else
					ctx.status(404);
				ctx.result(id);
			});

		/*
		// Add a rule
		app.post("/reason/rule", ctx -> {
				Rule rule = new Gson().fromJson(ctx.body(), Rule.class);
				String id = rule.getId();
				rules.put(id, rule);
				ctx.status(201); // 201 Created
				System.out.println("rule id:"+id+" added");
				ctx.result(id);
			});

		// Update a rule
		app.put("/reason/rule", ctx -> {
				Rule rule = new Gson().fromJson(ctx.body(), Rule.class);
				String id = rule.getId();
				rules.put(id, rule);
				ctx.status(201); // 201 Created
				System.out.println("rule id:"+id+" updated");
				ctx.result(id);
			});

		// Delete a rule
		app.delete("/reason/rule/{id}", ctx -> {
				String id = ctx.pathParam("id");
				Rule rule = rules.remove(id);
				if (rule != null) {
					System.out.println("rule id:"+id+" deleted");
					ctx.result(id);
				} else {
					ctx.status(404); // 404 Not found
					ctx.result("rule not found");
				}
			});

		// Get all rule ids
		app.get("/reason/rule", ctx -> {
				String ids = "";
				for (String id : rules.keySet()) {
					ids += id + " ";
				}

				ctx.result(ids);
			});
		*/

		// Add a descriptor
		app.post("/reason/descriptor", ctx -> {
				Descriptor descriptor = ctx.bodyAsClass(Descriptor.class);
				//Descriptor descriptor = new Gson().fromJson(ctx.body(), Descriptor.class);
				String id = descriptor.getId();
				descriptors.put(id, descriptor);
				ctx.status(201); // 201 Created
				if (id==null)
					id="0";
				System.out.println("descriptor id:"+id+" added");
				ctx.result(id);
			});

		// Update a descriptor
		app.put("/reason/descriptor", ctx -> {
				Descriptor descriptor = new Gson().fromJson(ctx.body(), Descriptor.class);
				String id = descriptor.getId();
				descriptors.put(id, descriptor);
				ctx.status(201); // 201 Created
				System.out.println("descriptor id:"+id+" updated");
				ctx.result(id);
			});

		// Delete a descriptor resource by id
		app.delete("/reason/descriptor/{id}", ctx -> {
				String id = ctx.pathParam("id");
				Descriptor descriptor = descriptors.remove(id);
				if (descriptor != null) {
					System.out.println("descriptor id:"+id+" deleted");
					ctx.result(id);
				} else {
					ctx.status(404); // 404 Not found
					ctx.result("descriptor not found");
				}
			});

		// Add an associate
		app.post("/reason/associate", ctx -> {
				Associate associate = new Gson().fromJson(ctx.body(), Associate.class);
				String id = associate.getId();
				associates.put(id, associate);
				ctx.status(201); // 201 Created
				System.out.println("associate id:"+id+" added");
				if (id == null)
					id = "null";
				ctx.result(id);
			});

		// Update an associate
		app.put("/reason/associate", ctx -> {
				Associate associate = new Gson().fromJson(ctx.body(), Associate.class);
				String id = associate.getId();
				associates.put(id, associate);
				ctx.status(201); // 201 Created
				System.out.println("associate id:"+id+" updated");
				ctx.result(id);
			});

		// Delete an associate resource by id
		app.delete("/reason/associate/{id}", ctx -> {
				String id = ctx.pathParam("id");
				Associate associate = associates.remove(id);
				if (associate != null) {
					System.out.println("associate id:"+id+" deleted");
					ctx.result(id);
				} else {
					ctx.status(404); // 404 Not found
					ctx.result("associate not found");
				}
			});

		// Add a relation
		app.post("/reason/relation", ctx -> {
				Relation relation = new Gson().fromJson(ctx.body(), Relation.class);
				String id = relation.getId();
				relations.put(id, relation);
				ctx.status(201); // 201 Created
				if (id==null)
					id="0";
				System.out.println("relation id:"+id+" added");
				ctx.result(id);
			});

		// Update a relation
		app.put("/reason/relation", ctx -> {
				Relation relation = new Gson().fromJson(ctx.body(), Relation.class);
				String id = relation.getId();
				relations.put(id, relation);
				ctx.status(201); // 201 Created
				System.out.println("relation id:"+id+" updated");
				ctx.result(id);
			});

		// Delete a relation by id
		app.delete("/reason/relation/{id}", ctx -> {
				String id = ctx.pathParam("id");
				Relation relation = relations.remove(id);
				if (relation != null) {
					System.out.println("relation id:"+id+" deleted");
					ctx.result(id);
				} else {
					ctx.status(404); // 404 Not found
					ctx.result("relation not found");
				}
			});

		/*
		app.post("/push", ctx -> {
				SseClient client;
				for(Map.Entry<String, SseClient> entry : pushClients.entrySet()) {
					client = entry.getValue();
					try {
						client.sendEvent("push", ctx.body());
						System.out.println("** psh.k:"+entry.getKey()+" sent **");
					}catch(java.lang.Exception e) {
						System.out.println("** psh.k closed:"+e.getCause()+" **");
					}
				}
				ctx.status(200); // 200 Created
				ctx.result("pushed");
			});

		app.post("/iot", ctx -> {
				SseClient client;
				for(Map.Entry<String, SseClient> entry : iotClients.entrySet()) {
					client = entry.getValue();
					try {
						client.sendEvent("iot", ctx.body());
						System.out.println("** psh.k:"+entry.getKey()+" sent **");
					}catch(java.lang.Exception e) {
						System.out.println("** psh.k closed:"+e.getCause()+" **");
					}
				}
				ctx.status(200); // 200 Created
				ctx.result("sent");
			});
		*/

		app.post("/push", ctx -> {
				WsContext client;
				for(Map.Entry<String, WsContext> entry : pushClients.entrySet()) {
					client = entry.getValue();
					try {
						client.send(ctx.body());
						System.out.println("** psh.k:"+entry.getKey()+" sent **");
					}catch(java.lang.Exception e) {
						System.out.println("** psh.k closed:"+e.getCause()+" **");
					}
				}

				ctx.status(200); // 200 Created
				ctx.result("pushed");
			});

		app.post("/iot", ctx -> {
				WsContext client;
				String msg;
				for(Map.Entry<String, WsContext> entry : iotClients.entrySet()) {
					client = entry.getValue();
					msg = URLDecoder.decode( ctx.body(), "UTF-8" ).replace("\\'","'");
					try {
						client.send(msg);
						System.out.println("** iot.k:"+entry.getKey()+" sent **");
					}catch(java.lang.Exception e) {
						System.out.println("** iot.k closed:"+e.getCause()+" **");
					}
				}
				ctx.status(200); // 200 Created
				ctx.result("sent");
			});

		/*
		app.sse("/push", client -> {
				String key = String.valueOf(client.hashCode());
				client.onClose(() -> {
						pushClients.remove(key);
						System.out.println("psh.close.k:"+key);
					});
				if (pushClients.containsKey(key))
					pushClients.replace(key, client);
				else
					pushClients.put(key, client);
				System.out.println("psh.k:"+key);
			});

		app.sse("/iot", client -> {
				String key = String.valueOf(client.hashCode());
				client.onClose(() -> {
						iotClients.remove(key);
						System.out.println("psh.close.k:"+key);
					});
				if (iotClients.containsKey(key))
					iotClients.replace(key, client);
				else
					iotClients.put(key, client);
				System.out.println("iot.k:"+key);
			});
		*/

		app.ws("/push", ws -> {
				ws.onConnect(client -> {
						client.session.setIdleTimeout(java.time.Duration.ofSeconds(-1));
						String key = String.valueOf(client.hashCode());
						ws.onClose(e -> {
								pushClients.remove(key);
								System.out.println("psh.close.k:"+key);
							});
						if (pushClients.containsKey(key))
							pushClients.replace(key, client);
						else
							pushClients.put(key, client);
						System.out.println("psh.k:"+key);
					});
			});

		app.ws("/iot", ws -> {
				ws.onConnect(client -> {
						client.session.setIdleTimeout(java.time.Duration.ofSeconds(-1));
						String key = String.valueOf(client.hashCode());
						ws.onClose(e -> {
								iotClients.remove(key);
								System.out.println("iot.close.k:"+key);
							});
						if (iotClients.containsKey(key))
							iotClients.replace(key, client);
						else
							iotClients.put(key, client);
						System.out.println("iot.k:"+key);
					});
			});

		/**/
	}

	private static void initializePrometheus(StatisticsHandler statisticsHandler, QueuedThreadPool queuedThreadPool) throws IOException {
    StatisticsHandlerCollector.initialize(statisticsHandler); // collector is included in source code
    QueuedThreadPoolCollector.initialize(queuedThreadPool); // collector is included in source code
    HTTPServer prometheusServer = new HTTPServer(7080);
	}

	public static class Rule {

		public String id, value;

		public Rule(String id, String value) {
			this.id = id;
			this.value = value;
		}

		public String getId() {
			return id;
		}

		public void setId(String id) {
			this.id = id;
		}

		public String getValue() {
			return value;
		}

		public void setValue(String value) {
			this.value = value;
		}
	}

	public static class Properties {

		private String type = null, name = null, value = null;

		public Properties(String _type, String _name, String _value) {
			this.type = _type;
			this.name = _name;
			this.value = _value;
		}
	}

	public static class Descriptor {

		private String pid = null, x = null, y = null, id = null, type = null, cid = null;
		private ArrayList<Properties> properties;
		private ArrayList<String> rid;
		private ArrayList<String> rtype;
		private HashSet<String> sources, targets;
		private KnowledgeBuilder kbuilder;
		private Reason server;

		public Descriptor(String _pid, String _x, String _y, ArrayList<String> _rid, ArrayList<String> _rtype, ArrayList<Properties> _properties,
											HashSet<String> _sources, HashSet<String> _targets, String _id, String _type, String _cid) {
			this.pid = _pid;
			this.x = _x;
			this.y = _y;
			this.rid = _rid;
			this.rtype = _rtype;
			this.properties = _properties;
			this.sources = _sources;
			this.targets = _targets;
			this.id = _id;
			this.type = _type;
			this.cid = _cid;
		}

		public String getId() {
			return this.id;
		}

		public String getType() {
			return this.type;
		}

		public String getCid() {
			return this.cid;
		}

		public void setCid(String cid) {
			this.cid = cid;
		}

		String reasonTarget(ClassPool pool, String rndm, KieSession ksession, ArrayList seen) {
			Iterator ts, rs, as, ds, ps;
			String target, aid, tid;
			Relation relation;
			Properties property;
			Associate associate;
			Descriptor descriptor;

			CtClass fact;
			CtField field;
			String className, rtype = null;
			String tgt = "";

			ts = targets.iterator();
			while (ts.hasNext()) {
				target = (String)ts.next();

				as = associates.entrySet().iterator();
				try {
					while (as.hasNext()) {
						associate = (Associate)((Map.Entry)as.next()).getValue();
						aid = associate.getId();
						if (target.equals(aid)) {
							fact = pool.makeClass("c"+rndm);
							className = null;
							tid = associate.getTid();
							descriptor = descriptors.get(tid);
							tgt = descriptor.reasonTarget(pool, rndm, ksession, seen)+tgt;
							try {
								descriptor.setBuilder(kbuilder);
							}catch(Exception ex){ex.printStackTrace();}
							descriptor.setServer(server);
							ps = descriptor.properties.iterator();
							while (ps.hasNext()) {
								property = (Properties)ps.next();
								if (property.name.equals("name") && property.value != null)
									className = property.value.replace(" ", "_");
								if (!property.type.equals("4") && !property.type.equals("5"))
									try {
										field = CtField.make("public java.lang.String "+property.name+" = \""+property.value+"\";", fact);
										fact.addField(field);
										System.out.println("t.p-n:"+property.name+" p-v:"+property.value);
									}catch(CannotCompileException e){
										e.printStackTrace();
									}
							}

							if (className == null)
								className = "c"+rndm;
							System.out.println("t.cn:"+className);
							rs = relations.entrySet().iterator();
							try {
								while (rs.hasNext()) {
									relation = (Relation)((Map.Entry)rs.next()).getValue();
									aid = relation.getAid();
									if (target.equals(aid)) {
										System.out.println("t.r-t:"+relation.getType());
										//System.out.println("t:"+target+" a:"+aid);
										rtype = relation.getType().replace(" ", "_");
										if (fact.isFrozen()) {
											fact.stopPruning(true);
											try {
												fact.writeFile();
											}catch(Exception e){
												e.printStackTrace();
											}
											fact.defrost();
										}

										fact.setName("c"+rndm+"_"+rtype+"."+className);
										tgt = rtype+"."+className+"@"+tgt;
										try {
											Object fo = java.lang.Class.forName(fact.getName(), false, pool.getClassLoader());
											System.out.println("t.fo:"+fo.toString());
											if (ksession.getFactHandle(fo) != null)
												ksession.update(ksession.getFactHandle(fo), fo);
										}catch(ClassNotFoundException e){
											try {
												Class fc = fact.toClass();
												System.out.println("t.fc:"+fc.toString());
												ksession.insert(fc.getConstructor().newInstance());
											}catch(Exception ex){
												ex.printStackTrace();
											}
										}catch(Exception e){
											e.printStackTrace();
										}
									}
								}
							}catch(ConcurrentModificationException cme){}
							catch(java.lang.RuntimeException re){}
						}
					}
				}catch(ConcurrentModificationException e){}
			}
				
			return tgt;
		}

		String nonexistent(String desd, KieSession ks) {
			String fhs = null;
			String tdesd = desd.replace(".","\\.").replaceAll("\\{.*\\}",".*");
			for (FactHandle factHandle : ks.getFactHandles()) {
				fhs = factHandle.toExternalForm().substring(factHandle.toExternalForm().lastIndexOf(":")+1);
				//System.out.println(fhs+"|"+desd);
				if (fhs.matches(tdesd) && !tdesd.contains("_.*")) {
					//System.out.println("** match **");
					System.out.println("match ** "+fhs+"|"+tdesd+" **");
					return "";
				};
			}
			return desd;
		}

		public void reason() {
			Iterator ps;
			Properties property;
			ClassPool pool = new ClassPool(true);
			String rndm = RandomStringUtils.randomAlphanumeric(7);
			CtClass fact = pool.makeClass("c"+rndm);
			CtField field;
			String className = null;
			String dsl = null, drl = null, dslr = null, rule;
			String tgt = null;

			long beginTs = System.currentTimeMillis();

			KieServices ks = KieServices.Factory.get();
			KieContainer kcontainer = ks.getKieClasspathContainer(pool.getClassLoader());
			InternalKnowledgeBase kbase = KnowledgeBaseFactory.newKnowledgeBase();
			KnowledgeBuilder kbuilder = KnowledgeBuilderFactory.newKnowledgeBuilder();
			KieSession ksession = kbase.newKieSession();
			ArrayList<String> seen = new ArrayList<String>();

			System.out.println("** new session **");
			
			tgt = reasonTarget(pool, rndm, ksession, seen);
			System.out.println("** tgt:"+tgt);
			ps = properties.iterator();
			//boolean ruleFound = false;

			try {
				byte[] content = Files.readAllBytes(Paths.get("/app/dsl.txt"));
				dsl = new String(content).replaceAll("rndm",rndm).replaceAll("=crndm_","=c"+rndm+"_").replaceAll("'crndm_","'c"+rndm+"_").replaceAll(" crndm_"," c"+rndm+"_").replaceAll("cid[^_]*", this.cid+"+"+this.id);
				//dsl = new String(content).replaceAll("\\+rndm\\+",rndm).replaceAll("\\+this.id\\+",this.id);
				System.out.println("* "+dsl+" *");
			} catch (IOException e) {
				e.printStackTrace();
			}

			/*
			try {
				byte[] content = Files.readAllBytes(Paths.get("/app/dslr.txt"));
				dslr = new String(content).replaceAll("'crndm_","'c"+rndm+"_");
				//drl = new String(content).replaceAll("\\+rndm\\+",rndm).replaceAll("\\+this.id\\+",this.id);
				System.out.println("* "+dslr+" *");
			} catch (IOException e) {
				e.printStackTrace();
			}
			*/

			try {
				byte[] content = Files.readAllBytes(Paths.get("/app/drl.txt"));
				drl = new String(content);
				System.out.println("* "+drl+" *");
			} catch (IOException e) {
				e.printStackTrace();
			}

			/*
			try {
				byte[] content = Files.readAllBytes(Paths.get("/app/dsl.txt"));
				dsl = new String(content).replaceAll("\\+rndm\\+",rndm).replaceAll("\\+this.id\\+",this.id);
				System.out.println("* "+dsl+" *");
			} catch (IOException e) {
				e.printStackTrace();
			}

			try {
				byte[] content = Files.readAllBytes(Paths.get("/app/drl.txt"));
				drl = new String(content);
				System.out.println("* "+drl+" *");
			} catch (IOException e) {
				e.printStackTrace();
			}
			*/

			//String rule2 = "rule 'show' salience 8\nwhen\n$o:Object()\nthen\nSystem.out.println($o);\nend";
			kbuilder.batch()
				.add(ResourceFactory.newReaderResource(new StringReader(dsl)), ResourceType.DSL)
				.add(ResourceFactory.newReaderResource(new StringReader(drl)), ResourceType.DRL)
				.build();

			while (ps.hasNext()) {
				property = (Properties)ps.next();
				if (property.name.equals("name"))
					className = property.value;
				if (property.type.equals("4")) {
					/*
					boolean found = false;
					Iterator<KiePackage> pi = kbuilder.getKnowledgePackages().iterator();
					while (pi.hasNext() && !found) {
						Iterator<org.kie.api.definition.rule.Rule> ri = ((KiePackage)pi.next()).getRules().iterator();
						while (ri.hasNext() && !found) {
							if (((org.kie.api.definition.rule.Rule)ri.next()).getName().equals("c"+rndm+"_"+property.name))
								found = true;
						}
					}
					*/

					String[] splits = property.value.split(" then ");
					String hyp = "if "+splits[0].substring(3);
					String con = "then "+splits[1];
					String hypd = "[when] "+splits[0].substring(3);
					String cond = "[then]"+splits[1];
					// set up pipeline properties
					java.util.Properties props = new java.util.Properties();
					// set the list of annotators to run
					props.setProperty("annotators", "tokenize,ssplit,pos");
					// build pipeline
					StanfordCoreNLP pipeline = new StanfordCoreNLP(props);
					// create a document object
					CoreDocument document = pipeline.processToCoreDocument(hyp);

					System.out.println();
					for (CoreLabel tok : document.tokens())
						System.out.println(String.format("%s\t%s", tok.word(), tok.tag()));

					// display tokens
					int VBC = 0, NNC = 0, JJC = 0, RBC = 0, IDX, INC = 0, DTC = 0, UHC = 0;

					for (IDX = 0; IDX < document.tokens().size(); IDX++) {
						CoreLabel tok = document.tokens().get(IDX);
						if (tok.tag().startsWith("VB") && !tok.word().startsWith("'")) {
							hypd = new String(hypd).replace(tok.word(), "{VB"+VBC+"}");
							++VBC;
						}
						else
						if (tok.tag().startsWith("NN") || tok.tag().startsWith("PR") || tok.tag().startsWith("DT") && tok.word().length() > 2) {
							if (IDX+1 < document.tokens().size() && (document.tokens().get(IDX+1).word().startsWith("'"))) {
								hypd = new String(hypd).replace(tok.word()+document.tokens().get(IDX+1).word(), "{NN"+NNC+"} {VB"+VBC+"}");
								if (document.tokens().get(IDX+1).word().charAt(1) == 'd') {
									hyp = new String(hyp).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" would");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 'm') {
									hyp = new String(hyp).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" am");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 'r') {
									hyp = new String(hyp).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" are");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 's') {
									hyp = new String(hyp).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" is");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 'v') {
									hyp = new String(hyp).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" have");
								}

								++VBC;
								++IDX;
							}
							else
							if (IDX+1 < document.tokens().size() && (document.tokens().get(IDX+1).tag().startsWith("NN"))) {
								hypd = new String(hypd).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), "{NN"+NNC+"}");
								hyp = new String(hyp).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), tok.word()+"_"+document.tokens().get(IDX+1).word());
								++IDX;
							}
							else
								hypd = new String(hypd).replace(tok.word(), "{NN"+NNC+"}");
							++NNC;
						}
						else
						if (tok.tag().startsWith("JJ")) {
							hypd = new String(hypd).replace(tok.word(), "{JJ"+JJC+"}");
							++JJC;
						}
						else
						if (tok.tag().startsWith("RB")) {
							if (IDX+1 < document.tokens().size() && (document.tokens().get(IDX+1).tag().startsWith("VB"))) {
								hypd = new String(hypd).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), "{RB"+RBC+"}");
								hyp = new String(hyp).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), tok.word()+"_"+document.tokens().get(IDX+1).word());
								++IDX;
							}
							else {
								hypd = new String(hypd).replace(tok.word(), "{RB"+RBC+"}");
								++RBC;
							}
						}
						else
						if (tok.tag().startsWith("IN")) {
							hypd = new String(hypd).replace(tok.word(), "{IN"+INC+"}");
							++INC;
						}
						else
						if (tok.tag().startsWith("UH")) {
							hypd = new String(hypd).replace(tok.word(), "{UH"+UHC+"}");
							++UHC;
						}
					}

					System.out.println(hyp);
					System.out.println(hypd);

					String[] hypt = hypd.split(" ");

					if (hypt[0].contains("[") && hypt[0].contains("{"))
						hypt[0] = new String(hypt[0].replaceAll("\\[.*\\].*\\{","{"));
					else
						hypt[0] = new String(hypt[0].replaceAll("\\[.*\\]",""));

					/*
					for (String tok : hypt) {
						System.out.print(tok+":");
					}
					System.out.println("\n");
					*/

					List<Integer> idx = new ArrayList<>();

					idx.add(0);
					for (int i = 0; i < hypt.length; i++)
						if (hypt[i].startsWith("{NN"))
							idx.add(i+1);
					if (idx.get(idx.size()-1) < hypt.length-1)
						idx.add(hypt.length);
					String[] oa = {"VB", "IN", "JJ", "RB", "NN"};
					List<String[]> sa = new ArrayList<>();

					String desd, sad = "=", ssa[], PNN = "";
					for (int i = 1; i < idx.size(); i++)
						sa.add(Arrays.copyOfRange(hypt, idx.get(i-1), idx.get(i)));

					List<String> RB = new ArrayList<>(), JJ = new ArrayList<>(), IN = new ArrayList<>(), VB = new ArrayList<>(), NN = new ArrayList<>(), UH = new ArrayList<>();

					for (int i = 0; i < sa.size(); i++) {
						ssa = sa.get(i);
						desd = "";
						for (int iii = 0; iii < ssa.length; iii++)
							if (ssa[iii].contains("NN")) {
								NN.add(ssa[iii]);
								if (VB.size() == 0)
									VB.add("describes");
								if (RB.size() > 0 || JJ.size() > 0 || IN.size() > 0 || UH.size() > 0 || VB.size() > 0) {
									if (i+1 < sa.size())
										desd = "c"+rndm+(VB.size() > 0 ? "_"+String.join("_", VB) : "")+(IN.size() > 0 ? "_"+String.join("_", IN) : "")+(JJ.size() > 0 ? "_"+String.join("_", JJ) : "")
											+"."+NN.get(0)+"("+(RB.size() > 0 ? "type == '"+(UH.size() > 0 ? String.join("_", UH)+"_" : "")+String.join("_", RB)+"'" : "")+") ".replaceAll("['!]","");
									else
									if (iii > 1 && ssa[iii-2].contains("JJ") && ssa[iii-1].contains("RB"))
										desd = "c"+rndm+"_describes."+ssa[iii]+"("+ssa[iii-1]+" == '"+ssa[iii-2]+"') ";
									else
									  desd = "c"+rndm+"_"+(iii > 1 ? String.join("_", Arrays.copyOfRange(ssa, 0, iii)) : "describes")+"."+ssa[iii]+"()";
									/*
										desd = "c"+rndm+(VB.size() > 0 ? "_"+String.join("_", VB) : "")+(IN.size() > 0 ? "_"+String.join("_", IN) : "")+(JJ.size() > 0 ? "_"+String.join("_", JJ) : "")
											+"."+NN.get(0)+"("+(RB.size() > 0 ? "type == '"+(UH.size() > 0 ? String.join("_", UH)+"_" : "")+String.join("_", RB)+"'" : "")+") ".replaceAll("['!]","");

									*/
									sad += desd;
								}

								System.out.println("desd:"+desd);
							}
							else
							if (ssa[iii].contains("RB"))
								RB.add(ssa[iii]);
							else
							if (ssa[iii].contains("JJ"))
								JJ.add(ssa[iii]);
							else
							if (ssa[iii].contains("IN"))
								IN.add(ssa[iii]);
							else
							if (ssa[iii].contains("UH"))
								UH.add(ssa[iii]);
							else
							if (ssa[iii].contains("VB"))
								if (iii+1 < ssa.length && ssa[iii+1].contains("RB")) {
									VB.add(ssa[iii]);
									RB.add(ssa[iii+1]);
									iii++;
								}
								else
								if (iii+1 < ssa.length && ssa[iii+1].contains("IN")) {
									VB.add(ssa[iii]);
									IN.add(ssa[iii+1]);
									iii++;
								}
								else
									VB.add(ssa[iii]);

						if (desd.length() == 0 && PNN.length() > 0 && (RB.size() > 0 || JJ.size() > 0 || IN.size() > 0 || UH.size() > 0)) {
							desd = "c"+rndm+"_"+String.join("_", ssa)+"."+PNN+"()";
							/*
							desd = "c"+rndm+(VB.size() > 0 ? "_"+String.join("_", VB) : "")+(IN.size() > 0 ? "_"+String.join("_", IN) : "")+(JJ.size() > 0 ? "_"+String.join("_", JJ) : "")
								+"."+PNN+"("+(RB.size() > 0 ? "type == '"+(UH.size() > 0 ? String.join("_", UH)+"_" : "")+String.join("_", RB)+"'" : "")+") ".replaceAll("['!]","");
							*/
							sad += desd;
							System.out.println("desd::"+desd);
						}

						if (NN.size() > 0)
							PNN = NN.get(0);
						NN.clear(); VB.clear(); IN.clear(); JJ.clear(); RB.clear(); UH.clear();
					}

					hypd += sad;

					document = pipeline.processToCoreDocument(con);

					for (CoreLabel tok : document.tokens())
						System.out.println(String.format("%s\t%s", tok.word(), tok.tag()));

					// display tokens
					VBC = 0; NNC = 0; JJC = 0; RBC = 0; IDX = 0; INC = 0; UHC = 0;
					for (IDX = 0; IDX < document.tokens().size(); IDX++) {
						CoreLabel tok = document.tokens().get(IDX);
						if (tok.tag().startsWith("VB"))
							if (IDX > 0 && document.tokens().get(IDX-1).tag().startsWith("RB"))
								cond = new String(cond).replace(tok.word()+" ", "");
							else {
								cond = new String(cond).replace(tok.word(), "{VB"+VBC+"}");
								++VBC;
							}
					  else
						if (tok.tag().startsWith("NN") || tok.tag().startsWith("PR") || tok.tag().startsWith("DT") && tok.word().length() > 2) {
							if (IDX+1 < document.tokens().size() && (document.tokens().get(IDX+1).word().startsWith("'"))) {
								cond = new String(cond).replace(tok.word()+document.tokens().get(IDX+1).word(), "{NN"+NNC+"} {VB"+VBC+"}");
								if (document.tokens().get(IDX+1).word().charAt(1) == 'd') {
									con = new String(con).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" would");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 'm') {
									con = new String(con).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" am");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 'r') {
									con = new String(con).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" are");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 's') {
									con = new String(con).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" is");
								}
								else
								if (document.tokens().get(IDX+1).word().charAt(1) == 'v') {
									con = new String(con).replace(tok.word()+document.tokens().get(IDX+1).word(), tok.word()+" have");
								}

								++VBC;
								++IDX;
							}
							else
							if (IDX+1 < document.tokens().size() && (document.tokens().get(IDX+1).tag().startsWith("NN"))) {
								cond = new String(cond).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), "{NN"+NNC+"}");
								con = new String(con).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), tok.word()+"_"+document.tokens().get(IDX+1).word());
								++IDX;
							}
							else
								cond = new String(cond).replace(tok.word(), "{NN"+NNC+"}");
							++NNC;
						}
						else
						if (tok.tag().startsWith("JJ")) {
							cond = new String(cond).replace(tok.word(), "{JJ"+JJC+"}");
							++JJC;
						}
						else
						if (tok.tag().startsWith("RB") && !tok.word().equals("then")) {
							if (IDX+1 < document.tokens().size() && (document.tokens().get(IDX+1).tag().startsWith("VB"))) {
								cond = new String(cond).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), "{RB"+RBC+"}");
								con = new String(con).replace(tok.word()+" "+document.tokens().get(IDX+1).word(), tok.word()+"_"+document.tokens().get(IDX+1).word());
								++IDX;
							}
							else
								cond = new String(cond).replace(tok.word(), "{RB"+RBC+"}");
							++RBC;
						}
						else
						if (tok.tag().startsWith("IN") && !tok.word().equals("then")) {
							cond = new String(cond).replace(tok.word(), "{IN"+INC+"}");
							++INC;
						}
					}

					/*
          System.out.println(con);
          System.out.println(cond);
					*/

					String[] cont = cond.split(" ");

					if (cont[0].contains("[") && cont[0].contains("{"))
						cont[0] = new String(cont[0].replaceAll("\\[.*\\].*\\{","{"));
					else
						cont[0] = new String(cont[0].replaceAll("\\[.*\\]",""));

					/*
					for (String tok : cont) {
						System.out.print(tok+":");
					}
					System.out.println("\n");
					*/

					idx.clear();

					idx.add(0);
					for (int i = 0; i < cont.length; i++)
						if (cont[i].startsWith("{NN") || cont[i].startsWith("{DT")) {
							idx.add(i+1);
						}
					if (idx.get(idx.size()-1) < cont.length-1)
						idx.add(cont.length);

					sa.clear();
					sad = ";="; PNN = "";
					String impd;

					for (int i = 1; i < idx.size(); i++)
						sa.add(Arrays.copyOfRange(cont, idx.get(i-1), idx.get(i)));

					for (int i = 0; i < sa.size(); i++) {
						ssa = sa.get(i);
						desd = ""; impd = "";
						for (int iii = 0; iii < ssa.length; iii++)
							if (ssa[iii].contains("NN")) {
								NN.add(ssa[iii]);
								if (VB.size() == 0)
									VB.add("describes");
								if (RB.size() > 0 || JJ.size() > 0 || IN.size() > 0 || UH.size() > 0) {
									if (iii > 1 && ssa[iii-2].contains("JJ") && ssa[iii-1].contains("RB"))
										desd = "then "+ssa[iii-2]+" "+ssa[iii-1]+" "+ssa[iii]+"=c"+rndm+"_describes."+ssa[iii]+"("+ssa[iii-1]+" == '"+ssa[iii-2]+"') ".replaceAll("['!]","");
									else
										desd = "c"+rndm+"_"+(iii > 1 ? String.join("_", Arrays.copyOfRange(ssa, 0, iii)) : "describes")+"."+ssa[iii]+"()";
										/*
										desd = nonexistent("c"+rndm+"_"+String.join("_", VB)+(IN.size() > 0 ? "_"+String.join("_", IN) : "")+(JJ.size() > 0 ? "_"+String.join("_", JJ) : "")
																			 +(UH.size() > 0 ? "_"+String.join("_", UH) : "")+(RB.size() > 0 ? "_"+String.join("_", RB) : "")+"."+NN.get(0), ksession).replaceAll("['!]","");
										*/

									if (desd.length() > 0) {
										impd = ("_|"+String.join("_", VB)+(IN.size() > 0 ? " "+String.join("_", IN)+"|r|" : "|r|")+(JJ.size() > 0 ? String.join("_", JJ)+"|a|type|n|" : "")
														+(UH.size() > 0 ? String.join("_", UH)+"_" : "")+(RB.size() > 0 ? String.join("_", RB)+"|a|type|n|" : "")+NN.get(0)+"|d").replaceAll("['!]","");
										sad += " insert(new javassist.ClassPool(true).makeClass('"+desd+"').toClass().getConstructor().newInstance()); sse.Push.main('"+this.cid+"+"+this.id+impd+"');\n";
									}
								}
								/*
								desd = "c"+rndm+"_"+(iii > 1 ? String.join("_", Arrays.copyOfRange(ssa, 0, iii)) : "describes")+"."+ssa[iii]+"()";
								impd = ("_|"+String.join("_", VB)+(IN.size() > 0 ? "_"+String.join("_", IN)+"|r|" : "|r|")+(JJ.size() > 0 ? String.join("_", JJ)+"|a|type|n|" : "")
												+(UH.size() > 0 ? String.join("_", UH)+"_" : "")+(RB.size() > 0 ? String.join("_", RB)+"" : "")+NN.get(0)+"|d");
								sad += " insert(new javassist.ClassPool(true).makeClass('"+desd+"').toClass().getConstructor().newInstance()); sse.Push.main('"+this.id+impd+"');\n";
								*/
							}
							else
							if (ssa[iii].contains("RB"))
								RB.add(ssa[iii]);
							else
							if (ssa[iii].contains("JJ"))
								JJ.add(ssa[iii]);
							else
							if (ssa[iii].contains("IN"))
								IN.add(ssa[iii]);
							else
							if (ssa[iii].contains("UH"))
								UH.add(ssa[iii]);
							else
							if (ssa[iii].contains("VB")) {
								if (iii+1 < ssa.length && ssa[iii+1].contains("RB")) {
									VB.add(ssa[iii]);
									RB.add(ssa[iii+1]);
									iii++;
								}
								else
								if (iii+1 < ssa.length && ssa[iii+1].contains("IN")) {
									VB.add(ssa[iii]);
									IN.add(ssa[iii+1]);
									iii++;
								}
								else
									VB.add(ssa[iii]);
							}

						if (desd.length() == 0 && PNN.length() > 0 && (RB.size() > 0 || JJ.size() > 0 || IN.size() > 0 || UH.size() > 0))
							if ((desd = nonexistent("c"+rndm+"_"+String.join("_", VB)+(IN.size() > 0 ? "_"+String.join("_", IN) : "")+(JJ.size() > 0 ? "_"+String.join("_", JJ) : "")
																			+"."+PNN+(UH.size() > 0 ? "_"+String.join("_", UH) : "")+(RB.size() > 0 ? "_"+String.join("_", RB) : ""), ksession).replaceAll("['!]","")).length() > 0) {
								desd = "c"+rndm+"_"+String.join("_", ssa)+"."+PNN+"()";
								impd = "_|"+(String.join("", ssa)+PNN).replace("{VB0}","{VB0}|r|").replace("{RB0}","{RB0} ").replace("{JJ0}","{JJ0}|a|").replace("{NN0}","{NN0}|d|");
								/*
									impd = ("_|"+String.join("_", VB)+(IN.size() > 0 ? "_"+String.join("_", IN)+"|r|" : "|r|")+(JJ.size() > 0 ? String.join("_", JJ)+"|a|type|n|" : "")
									+(UH.size() > 0 ? String.join("_", UH)+"_" : "")+(RB.size() > 0 ? String.join("_", RB)+"|a|type|n|" : "")+PNN+"|d").replaceAll("['!]","");
									impd = ("_|"+String.join("_", VB)+(IN.size() > 0 ? "_"+String.join("_", IN)+"|r|" : "|r|")+(RB.size() > 0 ? String.join("_", RB)+"|a|type|n|" : "")
									+(JJ.size() > 0 ? String.join("_", JJ)+"|a|type|n|" : "")+(UH.size() > 0 ? String.join("_", UH)+"_" : "")+PNN+"|d").replaceAll("['!]","");
								*/
								sad += " insert(new javassist.ClassPool(true).makeClass('"+desd+"').toClass().getConstructor().newInstance()); sse.Push.main('"+this.cid+"+"+this.id+impd+"');\n";
								System.out.println(" desd::::"+"c"+rndm+"_"+String.join("_", ssa)+"."+PNN+"()");
								System.out.println(" impd::::"+"_|"+(String.join("", ssa)+PNN).replace("{VB0}","{VB0}|r|").replace("{RB0}","{RB0} ").replace("{JJ0}","{JJ0}|a|").replace("{NN0}","{NN0}|d|"));
							}

						if (NN.size() > 0)
							PNN = NN.get(0);
						NN.clear(); VB.clear(); IN.clear(); JJ.clear(); RB.clear(); UH.clear();
					}

					//System.out.println("sad::"+sad+"::");
					cond += sad;

					System.out.println("DSL::>>"+hypd+cond+"<<");
					System.out.println("DSLR::>>"+hyp+" "+con+"<<");

					//rule = "import sse.*;\nrule 'c"+rndm+"_"+property.name+"' salience 10\nwhen\n"+property.value.replace(" then ","\nthen\n")+";\nend";
					rule = "import sse.*;\nrule 'c"+rndm+"_gen"+"' salience 10\nwhen\n"+(hyp+" "+con).replace(" then ","\nthen\n")+";\nend";
					System.out.println("dslr::>>"+rule+"<<");
					kbuilder.batch()
						.add(ResourceFactory.newReaderResource(new StringReader(rule)), ResourceType.DSLR)
  					.add(ResourceFactory.newReaderResource(new StringReader(hypd+"\n"+cond)), ResourceType.DSL)
						.build();
					System.out.println("** errors **:"+kbuilder.getErrors());
					System.out.println("** results **:"+kbuilder.getResults(org.kie.internal.builder.ResultSeverity.INFO));
					System.out.println("** end results **:"+kbuilder.getResults(org.kie.internal.builder.ResultSeverity.INFO));
			  }
				else
					try {
						field = CtField.make("public java.lang.String "+property.name+" = \""+property.value+"\";", fact);
						fact.addField(field);
					}catch(CannotCompileException e){
						e.printStackTrace();
					}
			}

			kbase.addPackages(kbuilder.getKnowledgePackages());

			if (className == null)
				className = rndm;
			else {
				fact.setName("c"+rndm+"_"+className);
				System.out.println("fact::"+fact.getName());
				try {
					Object fc = Class.forName(fact.getName(), false, pool.getClassLoader());
					ksession.delete(ksession.getFactHandle(fc));
					try {
						System.out.println("f::"+fact.toClass().toString());
						ksession.insert(fact.toClass().getConstructor().newInstance());
					}catch(Exception ex){
						ex.printStackTrace();
					}
				}catch(ClassNotFoundException e){
					try {
						ksession.insert(fact.toClass().getConstructor().newInstance());
					}catch(Exception ex){
						ex.printStackTrace();
					}
				}catch(Exception e){
					e.printStackTrace();
				}
			}

			System.out.println("** fire rules **");

			try {
				ksession.fireAllRules();
			}
			catch(Exception e){
				e.printStackTrace();
			}
			
			System.out.println("** fired rules **");

			ksession.halt();
			ksession.dispose();
			System.out.println("** dispose session **");

			InetAddress ip = null;
			try {
				ip = InetAddress.getLocalHost();
			}catch(UnknownHostException e){
				e.printStackTrace();
			}

			endTs
				.labels("descriptor.rsn", "200", "context", System.getenv("cluster"), System.getenv("app"), System.getenv("user"), ip.getHostAddress(), getCid())
				.set(beginTs + 1.0 / (System.currentTimeMillis() - beginTs));
		}

		public void setBuilder(KnowledgeBuilder builder) {
			kbuilder = builder;
		}

		public void setServer(Reason server) {
			server = server;
		}
	}

	public static class Associate {

		public String id, sid, tid;

		public Associate(String id, String sid, String tid) {
			this.id = id;
			this.sid = sid;
			this.tid = tid;
		}

		public String getId() {
			return id;
		}

		public void setId(String id) {
			this.id = id;
		}

		public String getSid() {
			return sid;
		}

		public void setSid(String sid) {
			this.sid = sid;
		}

		public String getTid() {
			return tid;
		}

		public void setTid(String tid) {
			this.tid = tid;
		}
	}

	public static class Relation {

		public String id, aid, sid, type;

		public Relation(String id, String aid, String sid, String type) {
			this.id = id;
			this.aid = aid;
			this.sid = sid;
			this.type = type;
		}

		public String getId() {
			return id;
		}

		public void setId(String id) {
			this.id = id;
		}

		public String getAid() {
			return aid;
		}

		public void setAid(String id) {
			this.aid = aid;
		}

		public String getSid() {
			return sid;
		}

		public void setSid(String id) {
			this.sid = sid;
		}

		public String getType() {
			return type;
		}

		public void setType(String type) {
			this.type = type;
		}
	}
}
