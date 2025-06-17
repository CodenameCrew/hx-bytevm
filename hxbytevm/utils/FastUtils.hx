package hxbytevm.utils;

#if cpp
@:build(hxbytevm.utils.macros.Utils.includeXml("hxbytevmutils", "FastUtils.xml", "include"))
@:include('FastUtils.h')
#end
@:unreflective
#if cpp extern #end class FastUtils {
	#if cpp
	@:native('combineStringFast') public static function  combineStringFast(inArray:cpp.StdVector<String>):String;

	@:native('combineString') public static function  combineString(inArray:cpp.StdVector<String>):String;

	@:native('repeatString') public static function repeatString(str:String, times:Int):String;
	@:native('parse_int_throw') public static function parseIntLimit(str:String):Int;
	#else
	@:pure public static inline function combineStringFast(inArray:Array<String>){
		combineString(inArray);
	}

	@:pure public static function combineString(inArray:Array<String>){
		var buf = new StringBuf();
		for(s in inArray)
			buf.add(s);
		return buf.toString();
	}


	@:pure public static function repeatString(str:String, times:Int):String {
		var buf = new StringBuf();
		for(i in 0...times)
			buf.add(str);
		return buf.toString();
	}

	@:pure public static function parseIntLimit(str:String):Int { // TODO: make this work
		return Std.parseInt(str);
	}
	#end
}
