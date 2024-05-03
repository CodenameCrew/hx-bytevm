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
		#else
		if (v.hasNext == null || v.next == null) {
			try {
				v = v.keyValueIterator();
			} catch (e:Dynamic) {}
		}
		#end
		if (v.hasNext == null || v.next == null)
			throw "Invalid Iterator";
		return v;
	}

	#if cpp
	public static function getNamedVarArgsFunction(name: String, func:(Array<Dynamic>) -> Dynamic): (Array<Dynamic>) -> Dynamic {
		var f = (args:Array<Dynamic>) -> {
			var r = func(args);

			// Code to name a local function
			untyped __cpp__('return r; }

			const char *mName;
			::String __ToString() const{ return String(mName); }
			::Dynamic __DO_NOT_RUN__() {
				#ifdef HXCPP_STACK_TRACE
				::hx::StackFrame _hx_stackframe(0);
				#endif
				::Dynamic r = 0;
			');
			return r;
		}
		// set the name of the function
		untyped __cpp__("dynamic_cast<_hx_Closure_0 *>({0}.mPtr)->mName = {1}.__s", f, name);
		return Reflect.makeVarArgs(func);
	}
	#else
	public inline static function getNamedVarArgsFunction(name: String, func:(Array<Dynamic>) -> Dynamic): (Array<Dynamic>) -> Dynamic {
		return Reflect.makeVarArgs(func);
	}
	#end
}
