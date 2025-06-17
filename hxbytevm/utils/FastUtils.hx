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
	@:pure public static overload extern inline function combineStringFast(a:String):String return _combineString(a);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String):String return _combineString(a,b);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String):String return _combineString(a,b,c);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String):String return _combineString(a,b,c,d);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String):String return _combineString(a,b,c,d,e);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String):String return _combineString(a,b,c,d,e,f);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String):String return _combineString(a,b,c,d,e,f,g);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String):String return _combineString(a,b,c,d,e,f,g,h);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String):String return _combineString(a,b,c,d,e,f,g,h,i);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String):String return _combineString(a,b,c,d,e,f,g,h,i,j);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o);
	@:pure public static overload extern inline function combineStringFast(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String, p:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p);

	@:pure public static overload extern inline function combineString(a:String):String return _combineString(a);
	@:pure public static overload extern inline function combineString(a:String, b:String):String return _combineString(a,b);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String):String return _combineString(a,b,c);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String):String return _combineString(a,b,c,d);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String):String return _combineString(a,b,c,d,e);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String):String return _combineString(a,b,c,d,e,f);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String):String return _combineString(a,b,c,d,e,f,g);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String):String return _combineString(a,b,c,d,e,f,g,h);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String):String return _combineString(a,b,c,d,e,f,g,h,i);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String):String return _combineString(a,b,c,d,e,f,g,h,i,j);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o);
	@:pure public static overload extern inline function combineString(a:String, b:String, c:String, d:String, e:String, f:String, g:String, h:String, i:String, j:String, k:String, l:String, m:String, n:String, o:String, p:String):String return _combineString(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p);

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
	#end
}
