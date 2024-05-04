import org.kie.api.KieServices;
import org.kie.api.KieBase;
import org.kie.api.runtime.KieContainer;
import org.kie.api.runtime.KieSession;
import org.kie.api.runtime.StatelessKieSession;

import org.kie.api.builder.KieRepository;
import org.kie.api.builder.KieFileSystem;
import org.kie.api.builder.Results;

import org.drools.core.impl.InternalKnowledgeBase;
import org.drools.core.impl.KnowledgeBaseFactory;
import org.kie.api.io.ResourceType;
import org.kie.internal.io.ResourceFactory;
import org.kie.internal.builder.KnowledgeBuilder;
import org.kie.internal.builder.KnowledgeBuilderFactory;

import java.io.StringReader;

public class DSLExample {

	public static final void main(String[] args) {
		KieSession knowledgeSession = null;
		String dsl = 
			"#/ steps usage when then result\n"+
			"[condition]If there is a Person with name of '{name}'=Person(name=='{name}')\n"+
			"[condition]Person is at least {age} years old and lives in '{location}'=Person(age >= {age}, personLocation:location=='{location}')\n"+
			"[condition]And = and\n"+
			"[condition]get All Messages=message : Message()\n"+
			"[consequence]Say '{message}'=System.out.println('{message}');Message m = new Message('{message}'); m.setOriginalWord(personLocation); insert(m);\n"+
			"[condition]When there is a person living in a place with name that sounds like '{poorlySpelledLocation}'=Person(personLocation:location soundslike '{poorlySpelledLocation}')";

		String dslr =
			"import test.Message;\n"+
			"rule 'Rocky Balboa Says'\n"+
			"when\n"+
			"If there is a Person with name of 'Rocky Balboa'\n"+
			"And Person is at least 30 years old and lives in 'Philadelphia'\n"+
			"then\n"+
			"Say 'Yo, Adrian!';\n"+
			"end\n"+ 
			"rule 'Person means Tucson'\n"+
			"when\n"+
			"When there is a person living in a place with name that sounds like 'Two Sun'\n"+
			"then\n"+
			"Say 'You probably meant Tucson';\n"+
			"end\n"+
			"query 'Get all Messages'\n"+
			"get All Messages;\n"+
			"end";

		KieSession ksession = null;
		
		try {
			// load up the knowledge base
			/**/
			KieServices ks = KieServices.Factory.get();
			KieRepository kr = ks.getRepository();
			KieFileSystem kfs = ks.newKieFileSystem()
				.write("src/main/resources/r1.dsl", dsl)
				.write("src/main/resources/r1.dslr", dslr);
			System.out.println(ks.newKieBuilder(kfs).buildAll().getResults());

			KieContainer kContainer = ks.newKieContainer(kr.getDefaultReleaseId());
			KieBase kbase = kContainer.getKieBase();
			ksession = kbase.newKieSession();
			/*
			InternalKnowledgeBase kbase = KnowledgeBaseFactory.newKnowledgeBase();
			KnowledgeBuilder kbuilder = KnowledgeBuilderFactory.newKnowledgeBuilder();
			ksession = kbase.newKieSession();

			kbuilder.batch()
				.add(ResourceFactory.newReaderResource(new StringReader(dsl)), ResourceType.DSL)
				.add(ResourceFactory.newReaderResource(new StringReader(dslr)), ResourceType.DSLR)
				.build();
			System.out.println("**errors**:"+kbuilder.getErrors());
			System.out.println("**results**:"+kbuilder.getResults());
			*/

			// 4 - create and assert some facts
			Person rocky = new Person("Rocky Balboa", "Philadelphia", 35);
			ksession.insert(rocky);
		
			// 5 - fire the rules
			ksession.fireAllRules();
		} catch (Throwable t) {
			t.printStackTrace();
		} finally {
			ksession.dispose();
		}
	}
}
