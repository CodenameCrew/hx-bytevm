package hxbytevm.utils.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class DefinesMacro {
	public static macro function getDefines():Expr {
		return macro $v{Context.getDefines()};
	}
}
