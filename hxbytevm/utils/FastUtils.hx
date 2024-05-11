package hxbytevm.utils;

/*
#if cpp
@:build(hxbytevm.utils.macros.Utils.includeXml("hxbytevmutils", "FastUtils.xml", "include"))
@:include('FastUtils.h')
#end
@:unreflective
#if cpp extern #end*/ class FastUtils {
	/*
	#if cpp
	@:native('combineStringFast') public static function combineStringFast1(a:String):String;
	@:native('combineStringFast') public static function combineStringFast2(a:String, b:String):String;
	@:native('combineStringFast') public static function combineStringFast3(a:String, b:String, c:String):String;
	@:native('combineStringFast') public static function combineStringFast4(a:String, b:String, c:String, d:String):String;
	@:native('combineStringFast') public static function combineStringFast5(a:String, b:String, c:String, d:String, e:String):String;
	@:native('combineStringFast') public static function combineStringFast6(a:String, b:String, c:String, d:String, e:String, f:String):String;
	@:native('combineStringFast') public static function combineStringFast7(a:String, b:String, c:String, d:String, e:String, f:String, g:String):String;
	@:native('combineStringFast') public static function combineStringFast8(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String):String;
	@:native('combineStringFast') public static function combineStringFast9(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String):String;
	@:native('combineStringFast') public static function combineStringFast10(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String):String;
	@:native('combineStringFast') public static function combineStringFast11(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String):String;
	@:native('combineStringFast') public static function combineStringFast12(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String):String;
	@:native('combineStringFast') public static function combineStringFast13(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String):String;
	@:native('combineStringFast') public static function combineStringFast14(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String):String;
	@:native('combineStringFast') public static function combineStringFast15(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String):String;
	@:native('combineStringFast') public static function combineStringFast16(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String, p:String):String;

	@:native('combineString') public static function combineString1(a:String):String;
	@:native('combineString') public static function combineString2(a:String, b:String):String;
	@:native('combineString') public static function combineString3(a:String, b:String, c:String):String;
	@:native('combineString') public static function combineString4(a:String, b:String, c:String, d:String):String;
	@:native('combineString') public static function combineString5(a:String, b:String, c:String, d:String, e:String):String;
	@:native('combineString') public static function combineString6(a:String, b:String, c:String, d:String, e:String, f:String):String;
	@:native('combineString') public static function combineString7(a:String, b:String, c:String, d:String, e:String, f:String, g:String):String;
	@:native('combineString') public static function combineString8(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String):String;
	@:native('combineString') public static function combineString9(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String):String;
	@:native('combineString') public static function combineString10(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String):String;
	@:native('combineString') public static function combineString11(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String):String;
	@:native('combineString') public static function combineString12(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String):String;
	@:native('combineString') public static function combineString13(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String):String;
	@:native('combineString') public static function combineString14(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String):String;
	@:native('combineString') public static function combineString15(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String):String;
	@:native('combineString') public static function combineString16(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String, p:String):String;

	@:native('repeatString') public static function repeatString(str:String, times:Int):String;
	@:native('parse_int_throw') public static function parseIntLimit(str:String):Int;
	#else
	*/
	@:pure public static inline function combineStringFast1(a:String):String return _combineString(a);
	@:pure public static inline function combineStringFast2(a:String, b:String):String return _combineString(a,b);
	@:pure public static inline function combineStringFast3(a:String, b:String, c:String):String return _combineString(a,b,c);
	@:pure public static inline function combineStringFast4(a:String, b:String, c:String, d:String):String return _combineString(a,b,c,d);
	@:pure public static inline function combineStringFast5(a:String, b:String, c:String, d:String, e:String):String return _combineString(a,b,c,d,e);
	@:pure public static inline function combineStringFast6(a:String, b:String, c:String, d:String, e:String, f:String):String return _combineString(a,b,c,d,e,f);
	@:pure public static inline function combineStringFast7(a:String, b:String, c:String, d:String, e:String, f:String, g:String):String return _combineString(a,b,c,d,e,f,g);
	@:pure public static inline function combineStringFast8(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String):String return _combineString(a,b,c,d,e,f,g,h);
	@:pure public static inline function combineStringFast9(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String):String return _combineString(a,b,c,d,e,f,g,h,i);
	@:pure public static inline function combineStringFast10(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String):String return _combineString(a,b,c,d,e,f,g,h,i,j);
	@:pure public static inline function combineStringFast11(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k);
	@:pure public static inline function combineStringFast12(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l);
	@:pure public static inline function combineStringFast13(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m);
	@:pure public static inline function combineStringFast14(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n);
	@:pure public static inline function combineStringFast15(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o);
	@:pure public static inline function combineStringFast16(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String, p:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p);

	@:pure public static inline function combineString1(a:String):String return _combineString(a);
	@:pure public static inline function combineString2(a:String, b:String):String return _combineString(a,b);
	@:pure public static inline function combineString3(a:String, b:String, c:String):String return _combineString(a,b,c);
	@:pure public static inline function combineString4(a:String, b:String, c:String, d:String):String return _combineString(a,b,c,d);
	@:pure public static inline function combineString5(a:String, b:String, c:String, d:String, e:String):String return _combineString(a,b,c,d,e);
	@:pure public static inline function combineString6(a:String, b:String, c:String, d:String, e:String, f:String):String return _combineString(a,b,c,d,e,f);
	@:pure public static inline function combineString7(a:String, b:String, c:String, d:String, e:String, f:String, g:String):String return _combineString(a,b,c,d,e,f,g);
	@:pure public static inline function combineString8(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String):String return _combineString(a,b,c,d,e,f,g,h);
	@:pure public static inline function combineString9(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String):String return _combineString(a,b,c,d,e,f,g,h,i);
	@:pure public static inline function combineString10(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String):String return _combineString(a,b,c,d,e,f,g,h,i,j);
	@:pure public static inline function combineString11(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k);
	@:pure public static inline function combineString12(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l);
	@:pure public static inline function combineString13(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m);
	@:pure public static inline function combineString14(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n);
	@:pure public static inline function combineString15(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o);
	@:pure public static inline function combineString16(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String, p:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p);

	@:pure private static function _combineString(...a:String):String {
		var buf = new StringBuf();
		for(s in a)
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
	// #end
}
