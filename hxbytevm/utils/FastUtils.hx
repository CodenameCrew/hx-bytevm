package hxbytevm.utils;

#if cpp
@:build(hxbytevm.utils.macros.Utils.includeXml("hxbytevmutils", "FastUtils.xml", "include"))
@:include('FastUtils.h')
#end
@:unreflective
#if cpp extern #end class FastUtils {
	#if cpp
	@:native('combineString') public static function combineString1(a:String):String;
	@:native('combineString') public static function combineString2(a:String, b:String):String;
	@:native('combineString') public static function combineString3(a:String, b:String, c:String):String;
	@:native('combineString') public static function combineString4(a:String, b:String, c:String, d:String):String;
	@:native('combineString') public static function combineString5(a:String, b:String, c:String, d:String, e:String):String;
	@:native('combineString') public static function combineString6(a:String, b:String, c:String, d:String, e:String, f:String):String;

	@:native('repeatString') public static function repeatString(str:String, times:Int):String;
	#else
	public static inline function combineString1(a:String):String return _combineString(a);
	public static inline function combineString2(a:String, b:String):String return _combineString(a,b);
	public static inline function combineString3(a:String, b:String, c:String):String return _combineString(a,b,c);
	public static inline function combineString4(a:String, b:String, c:String, d:String):String return _combineString(a,b,c,d);
	public static inline function combineString5(a:String, b:String, c:String, d:String, e:String):String return _combineString(a,b,c,d,e);
	public static inline function combineString6(a:String, b:String, c:String, d:String, e:String, f:String):String return _combineString(a,b,c,d,e,f);

	private static function _combineString(...a:String):String {
		var buf = new StringBuf();
		for(s in a)
			buf.add(s);
		return buf.toString();
	}

	public static function repeatString(str:String, times:Int):String {
		var buf = new StringBuf();
		for(i in 0...times)
			buf.add(str);
		return buf.toString();
	}
	#end
}
