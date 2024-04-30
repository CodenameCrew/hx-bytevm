package hxbytevm.utils;

class RuntimeUtils {
    public static inline function iterator(v:Dynamic):Iterator<Dynamic> {
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.iterator != null)
			v = v.iterator();
		#else
		if(v.hasNext == null || v.next == null) {
			try
				v = v.iterator()
			catch (e:Dynamic) {};
		}
		#end
		if (v.hasNext == null || v.next == null)
			throw "Invalid Iterator";
		return v;
	}

    public static inline function keyValueIterator(v:Dynamic):Iterator<Dynamic> {
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.keyValueIterator != null)
			v = v.keyValueIterator();

		//if (v.iterator != null)
		//	v = v.iterator();

		if (v.hasNext == null || v.next == null)
			throw "Invalid Iterator";
		#else
		try {
			if (v.hasNext == null || v.next == null)
				v = v.keyValueIterator();
		} catch (e:Dynamic) {}

		if (v.hasNext == null || v.next == null)
			throw "Invalid Iterator";
		//if (v.hasNext == null || v.next == null)
		//	v = iterator(v);
		#end
		return v;
	}
}