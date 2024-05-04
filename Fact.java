package util;

import javassist.ClassPool;
import javassist.CtClass;
import javassist.CtField;
import javassist.CtMethod;
import javassist.CtNewMethod;
import javassist.CannotCompileException;
import javassist.NotFoundException;

@SuppressWarnings(value={"unchecked"})
public class Fact {

	public static Object build(String name) {

		ClassPool pool = new ClassPool(true);
		CtClass fact = pool.makeClass(name);
		CtField field;
		Class fc = null;
		try {
			/*
				field = CtField.make("public java.lang.String "+property.name+" = \""+property.value+"\";", fact);
				fact.addField(field);
			*/
			fc = fact.toClass();
			System.out.println("**build**:"+fc);
			System.out.flush();
			return fc.getConstructor().newInstance();
		}catch(Exception ex){
		}

		return null;
	}
}
