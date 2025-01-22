package hxbytevm.utils.macros;

#if macro
import haxe.macro.MacroStringTools;
import haxe.CallStack;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Compiler;
import haxe.macro.Printer;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
#end

class OptimizerMacro {
	#if macro
	public static function init() {
		#if !display
		if(Context.defined("display")) return;
		if(!Context.defined("cpp")) return;
		Compiler.addGlobalMetadata("", "@:build(hxbytevm.utils.macros.OptimizerMacro.build())");
		#end
	}

	macro public static function build(): Array<Field> {
		var fields = Context.getBuildFields();
		if(fields == null) return fields;
		for (field in fields) {
			switch(field.kind) {
				case FFun(fun) if (fun.expr != null):
					fun.expr = map(fun.expr);
				case _:
			}
		}
		return fields;
	}

	static function map(e:Expr) {
		// TODO: support EBinOp(OpAdd, e1, e2)
		var ret = switch(e.expr) {
			case EConst(CString(s, SingleQuotes)) if(StringTools.contains(s, "$")):
				optimizeStringInterpolation(MacroStringTools.formatString(s, e.pos)).map(map);
			default:
				e.map(map);
		}
		return ret;
	}
	static function optimizeStringInterpolation(str: Expr): Expr {
		var printer = new Printer();

		var strElements:Array<Expr> = [];

		function iter(e:Expr) {
			switch (e.expr) {
				case EBinop(OpAdd, e1, e2):
					iter(e1);
					iter(e2);
				case EConst(CString(s, _)) if(s.length == 0): // exclude empty strings
				case _:
					strElements.push(e);
			}
		}
		ExprTools.iter(str, iter);
		if(strElements.length == 0) return str;

		var newstrElements:Array<Expr> = [];

		function convertToCombineString(arr:Array<Expr>):Expr {
			var combined:Expr = null;

			while(arr.length > 0) {
				var args = arr.splice(0, 16);
				for(i in 0...args.length) {
					var e = args[i];
					switch(e.expr) {
						case EConst(CString(_, _)):
						default:
							//try {
							//	args[i] = switch(Context.typeof(e)) {
							//		case TInst(_.get() => {name: "String"}, _): e;
							//		default: macro @:pos(e.pos) Std.string($e);
							//	}
							//} catch (err:Dynamic) {
								//trace(err);
								//trace(e.toString());
								//trace(e.pos);
								//trace(CallStack.toString(CallStack.exceptionStack()));
								args[i] = switch(e.expr) {
									case EConst(CString(_, _)): e;
									case ETernary(_, _.expr => EConst(CString(_, _)), _.expr => EConst(CString(_, _))): e;
									case EIf(_, _.expr => EConst(CString(_, _)), _.expr => EConst(CString(_, _))): e;
									case EMeta({name: ":str"}, ie): ie;
									default: macro @:pos(e.pos) Std.string($e);
								}
							//}
					}
				}
				var ta = args.length;
				var e:Expr = null;
				if(ta == 1) {
					e = args[0];
				} else {
					e = macro @:pos(str.pos) $p{["hxbytevm","utils","FastUtils","combineString" + ta]}($a{args});
				}
				newstrElements.push(e);
				combined = (combined == null) ? e : {expr: EBinop(OpAdd, combined, e), pos: str.pos};
			}
			return combined;
		}

		var e:Expr = convertToCombineString(strElements);

		while(newstrElements.length > 1) {
			var arr = newstrElements; newstrElements = [];
			e = convertToCombineString(arr);
		}

		// trace(str.toString());
		// trace(e.toString());

		return e;
	}

	/*
	static function optimizeStringInterpolationSmarter(str: Expr): Expr {
		var printer = new Printer();
		trace(printer.printExpr(str));
		//trace(str);
		trace(Context.getClassPath());
		trace(Context.getLocalClass().get());
		trace(Context.getLocalModule());
		trace(Context.getLocalImports());
		trace(Context.getLocalMethod());
		trace(Context.getExpectedType());
		trace(Context.getLocalType());
		trace(Context.getLocalUsing());
		trace(Context.getLocalTVars());
		//var f:Expr = MacroStringTools.formatString(str);
		//try {
		//	f = Context.getTypedExpr(Context.typeExpr(macro @:pos(str.pos) ${str}));
		//} catch (e:Dynamic) {
		//	trace(e);
		//	trace(CallStack.toString(CallStack.exceptionStack()));
		//	return str;
		//}
		//trace(printer.printExpr(f));
		//TypedExprTools.iter(cf, iter);
		var strElements:Array<Expr> = [];

		function iter(e:Expr) {
			switch (e.expr) {
				case EBinop(OpAdd, e1, e2):
					iter(e1);
					iter(e2);
				case _:
					strElements.push(e);
			}
		}
		ExprTools.iter(str, iter);


		//trace(strElements.map(function(e) return printer.printExpr(e)));
		var newstrElements:Array<Expr> = [];

		function convertToCombineString(arr:Array<Expr>):Expr {
			//trace(arr.map(function(e) return printer.printExpr(e)));
			var combined:Expr = null;

			while(arr.length > 0) {
				var args = arr.splice(0, 16);
				for(i in 0...args.length) {
					var e = args[i];
					args[i] = switch(Context.typeExpr(e).t) {
						case TInst(_.get() => {name: "String"}, _): e;
						default: macro @:pos(e.pos) Std.string($e);
					}
				}
				var ta = args.length;
				var e:Expr = null;
				if(ta == 1) {
					e = args[0];
				} else {
					e = macro @:pos(str.pos) $p{["hxbytevm","utils","FastUtils","combineString" + ta]}($a{args});
				}
				newstrElements.push(e);
				combined = (combined == null) ? e : {expr: EBinop(OpAdd, combined, e), pos: str.pos};
			}
			return combined;
		}

		var e:Expr = convertToCombineString(strElements);

		while(newstrElements.length > 1) {
			var arr = newstrElements; newstrElements = [];
			e = convertToCombineString(arr);
		}

		//trace(printer.printExpr(e));

		return e;
	}
	*/
	#end
}
