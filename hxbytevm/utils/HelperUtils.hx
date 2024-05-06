package hxbytevm.utils;

import hxbytevm.core.Ast;

class HelperUtils {
	@:pure public static function getPackFromTypePath(typePath:TypePath):String {
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

	@:pure public inline static function getIdentFromExpr(e: Expr): String {
		return switch (e.expr) {
			case EConst(CIdent(s)): s;
			default: null;
		}
	}
}
