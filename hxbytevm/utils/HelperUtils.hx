package hxbytevm.utils;

import hxbytevm.core.Ast;

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
}
