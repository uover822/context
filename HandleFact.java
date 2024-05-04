package fact;

public class HandleFact {

	public static void main(String name) {

		try {
			//insert(new javassist.ClassPool(true).makeClass('c"+rndm+"_describes.{period}').toClass().getConstructor().newInstance());
			Object fo = java.lang.Class.forName(name, false, pool.getClassLoader());
			System.out.println("t.fo:"+fo.toString());
			if (ksession.getFactHandle(fo) != null)
				ksession.update(ksession.getFactHandle(fo), fo);
		}catch(ClassNotFoundException e){
			try {
				Class fc = fact.toClass();
				System.out.println("t.fc:"+fc.toString());
				ksession.insert(fc.getConstructor().newInstance());
				//insert(new javassist.ClassPool(true).makeClass('c"+rndm+"_describes.{period}').toClass().getConstructor().newInstance());
			}catch(Exception ex){
				ex.printStackTrace();
			}
		}catch(Exception e){
			e.printStackTrace();
		}
	}
}
