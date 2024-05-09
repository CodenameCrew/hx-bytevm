package hxbytevm.utils;

import haxe.Constraints.IMap;
import haxe.EnumTools.EnumValueTools;

class CompareUtils {
	static inline function isNull(a:Dynamic):Bool {
		return Type.enumEq(Type.typeof(a), TNull);
	}

	static inline function isFunction(a:Dynamic):Bool {
		return Type.enumEq(Type.typeof(a), TFunction);
	}

	// TODO: check this for bugs
	// Code from https://github.com/elnabo/equals/blob/master/src/equals/Equal.hx, (MIT License), but updated to work with haxe 4
	public static function deepEqual<T> (a:T, b:T) : Bool {
		if (a == b) { return true; } // if physical equality
		if (isNull(a) ||  isNull(b)) {
			return false;
		}

		switch (Type.typeof(a)) {
			case TNull, TInt, TBool, TUnknown:
				return a == b;
			case TFloat:
				return Math.isNaN(cast a) && Math.isNaN(cast b); // only valid true result remaining
			case TFunction:
				return Reflect.compareMethods(a, b); // only physical equality can be tested for function
			case TEnum(_):
				if (EnumValueTools.getIndex(cast a) != EnumValueTools.getIndex(cast b)) {
					return false;
				}
				var a_args = EnumValueTools.getParameters(cast a);
				var b_args = EnumValueTools.getParameters(cast b);
				return deepEqual(a_args, b_args);
			case TClass(_):
				if ((a is String) && (b is String)) {
					return a == b;
				}
				if ((a is Array) && (b is Array)) {
					var a = cast(a, Array<Dynamic>);
					var b = cast(b, Array<Dynamic>);
					if (a.length != b.length) { return false; }
					for (i in 0...a.length) {
						if (!deepEqual(a[i], b[i])) {
							return false;
						}
					}
					return true;
				}

				if ((a is IMap) && (b is IMap)) {
					var a = cast(a, IMap<Dynamic, Dynamic>);
					var b = cast(b, IMap<Dynamic, Dynamic>);
					var a_keys = [ for (key in a.keys()) key ];
					var b_keys = [ for (key in b.keys()) key ];
					a_keys.sort(Reflect.compare);
					b_keys.sort(Reflect.compare);
					if (!deepEqual(a_keys, b_keys)) { return false; }
					for (key in a_keys) {
						if (!deepEqual(a.get(key), b.get(key))) {
							return false;
						}
					}
					return true;
				}

				if ((a is Date) && (b is Date)) {
					return cast(a, Date).getTime() == cast(b, Date).getTime();
				}

				if ((a is haxe.io.Bytes) && (b is haxe.io.Bytes)) {
					return deepEqual(cast(a, haxe.io.Bytes).getData(), cast(b, haxe.io.Bytes).getData());
				}

			case TObject:
		}

		for (field in Reflect.fields(a)) {
			var pa = Reflect.field(a, field);
			var pb = Reflect.field(b, field);
			if (isFunction(pa)) {
				// ignore function as only physical equality can be tested, unless null
				if (isNull(pa) != isNull(pb)) {
					return false;
				}
				continue;
			}
			if (!deepEqual(pa, pb)) {
				return false;
			}
		}

		return true;
	}
}
