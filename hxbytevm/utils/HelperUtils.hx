package hxbytevm.utils;

import haxe.ds.Option;
import hxbytevm.core.Ast;

/**
 * Useful to limit a Dynamic function argument's type to the specified
 * type parameters. This does NOT make the use of Dynamic type-safe in
 * any way (the underlying type is still Dynamic and Std.is() checks +
 * casts are necessary).
 */
abstract OneOfTwo<T1, T2>(Dynamic) from T1 from T2 to T1 to T2 {}

class TupleImpl<T1, T2> {
	public var t1:T1;
	public var t2:T2;
	public function new(t1:T1, t2:T2) {
		this.t1 = t1;
		this.t2 = t2;
	}
}

@:forward
abstract Tuple<T1, T2>(TupleImpl<T1, T2>) from TupleImpl<T1, T2> to TupleImpl<T1, T2> {
	@:arrayAccess
	public inline function get(index:Int):OneOfTwo<T1, T2> {
		return switch index {
			case 0: this.t1;
			case 1: this.t2;
			default: throw "Invalid index";
		}
	}

	public static function make<T1, T2>(t1:T1, t2:T2):Tuple<T1, T2> {
		return new TupleImpl(t1, t2);
	}
}

class HelperUtils {
	@:noUsing @:pure public static function getPackFromTypePath(typePath:TypePath):String {
		var pack = "";
		for(p in typePath.pack) {
			pack += p + ".";
		}
		pack += typePath.name;
		var sub = typePath.sub;
		if(sub != null && sub.length > 0)
			pack += "." + sub;
		// TODO: params
		return pack;
	}

	@:noUsing @:pure public inline static function getIdentFromExpr(e: Expr): String {
		return switch (e.expr) {
			case EConst(CIdent(s)): s;
			default: null;
		}
	}

	public inline static function last<T>(arr:Array<T>):T {
		return arr[arr.length - 1];
	}
	public inline static function first<T>(arr:Array<T>):T {
		return arr[0];
	}

	public inline static function get<T>(s:Option<T>, ?defaultValue:T):T {
		return switch s {
			case Some(v): v;
			case None: defaultValue;
		}
	}

	public inline static function getOrThrow<T>(s:Option<T>):T {
		return switch s {
			case Some(v): v;
			case None: throw "Invalid Option";
		}
	}

	public inline static function toOption<T>(v:T):Option<T> {
		return if(v == null) None else Some(v);
	}
}
