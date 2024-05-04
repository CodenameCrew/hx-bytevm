package hxbytevm.utils;

import hxbytevm.core.Ast;

class HelperUtils {
	public static function getPackFromTypePath(typePath:TypePath):String {
		var pack = "";
		for(p in typePath.pack) {
			pack += p + ".";
		}
		pack += typePath.name;
		if(typePath.sub != null && typePath.sub.length > 0)
			pack += typePath.sub;
		// TODO: params
		return pack;
	}

	public inline static function getIdentFromExpr(e: Expr): String {
		return switch (e.expr) {
			case EConst(CIdent(s)): s;
			default: null;
		}
	}
}
