package sse;

public class Confirm {

	public static String rtn = "true";
	
	public static void main(String[] args) {
		//cKdIGfVS_eating.sundae@on_top.cherry@having.icecream@topped_with.nuts@eating.sundae @ Sun Dec 13 2020 07:26:52 GMT-0800 (Pacific Standard Time)@@1ca6a203
		Confirm.rtn = "true";
	}

	public static String getRtn() {
		return Confirm.rtn;
	}
}
