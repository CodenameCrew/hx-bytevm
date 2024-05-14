package hxbytevm.interp;

import hxbytevm.utils.HelperUtils;
import haxe.Constraints.IMap;
import hxbytevm.utils.UnsafeReflect;
import haxe.ds.Option;
import hxbytevm.utils.RuntimeUtils;
import hxbytevm.core.Ast;
import haxe.ds.Vector;

@:structInit
class DeclaredVar {
	public var name: String;
	public var value: Dynamic;
	//public var type: Type;
	//public var depth: Int;
}

/**
 * Interpreter
 *
 * This intepreter is used for short scripts, that dont need to be compiled, aka if its only run once or two
**/
class Interp {
	public function new() {
		addTopLevelVar("trace", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var inf:haxe.PosInfos = @:fixed {
				fileName: "",
				lineNumber: 0,
				methodName: "", // TODO: get function name of function which called it,
				className: "", // Use class name, if not available, use filename
				customParams: []
			}
			var v = args.shift();
			if (args.length > 0)
				inf.customParams = args;
			haxe.Log.trace(Std.string(v), inf);
		}));
	}

	public function run(e: Expr):Dynamic {
		try {
			return expr(e);
		} catch( e: Stop ) {
			switch (e) {
				case SReturn(v): return v;
				case SBreak: throw "Invalid break";
				case SContinue: throw "Invalid continue";
			}
		} catch( e: Dynamic ) {
			throw e;
		}
		return null;
	}

	public var decls:Array<Array<DeclaredVar>> = [];

	public function addTopLevelVar(name: String, value: Dynamic) {
		getDeclLevel(0).push({
			name: name,
			value: value,
			//depth: 0
		});
	}

	var depth(default, set): Int = 0;
	function set_depth(v: Int): Int {
		//while(decls.length > 0 && decls[decls.length - 1].depth > v) {
		//	decls.pop();
		//}
		while(decls.length > 0 && decls.length - 1 > v) {
			decls.pop();
		}
		return depth = v;
	}

	function getDeclLevel(depth: Int): Array<DeclaredVar> {
		if(decls.length > depth)
			return decls[depth];

		var d = [];
		decls.push(d);
		return d;
	}

	public function pushVar(name: String, value: Dynamic, ?type: Type) {
		pushDecl({
			name: name,
			value: value,
			//type: type,
			//depth: depth
		});
	}

	public function pushDecl(decl:DeclaredVar) {
		getDeclLevel(depth).push(decl);
	}

	@:pure public function getTopLevelVar(name: String): Option<DeclaredVar> {
		var len = decls.length;
		if(len == 0) return None;
		for (decl in decls[0]) {
			if (decl.name == name) {
				return Some(decl);
			}
		}

		return None;
	}

	@:pure public function getLocal(name: String): Option<DeclaredVar> {
		var len = decls.length;
		for (i in 0...len) {
			var idx = len - i - 1; // make it go from the end to the beginning
			var scope = decls[idx];
			var scopeLength = scope.length;
			for(j in 0...scopeLength) {
				var v = scope[scopeLength - j - 1];
				if (v.name == name) {
					return Some(v);
				}
			}
		}

		return None;
	}

	@:pure public function getVar(name: String): Option<DeclaredVar> {
		var val = getLocal(name);
		return val;
	}

	@:pure public function getVarFromExpr(e: Expr): Option<DeclaredVar> {
		return switch (e.expr) {
			case EConst(CIdent(s)): getVar(s);
			default: None;
		}
	}

	public function getGetSetFromExpr(e: Expr): Array<Dynamic> {
		var getter:Void->Dynamic = () -> null;
		var setter:Dynamic = (val) -> null;
		switch(e.expr) {
			case EConst(CIdent(name)):
				switch getVar(name) {
					case Some(v):
						getter = () -> v.value;
						setter = (val) -> v.value = val;
					case None:
						throw "Unknown variable " + name;
				}
			case EField(e, name, s):
				switch getVarFromExpr(e) {
					case Some(v):
						if(s == EFSafe) {
							if(v.value == null)
								return null;
						}
						getter = () -> UnsafeReflect.getProperty(v.value, name);
						setter = (val) -> UnsafeReflect.setProperty(v.value, name, val);
					case None:
						throw "Unknown variable " + name;
				}
			case EArray(arr, index):
				var arr:Dynamic = expr(arr);
				var index:Dynamic = expr(index);
				if(arr is IMap) {
					var map = cast(arr, IMap<Dynamic, Dynamic>);
					getter = () -> map.get(index);
					setter = (val) -> map.set(index, val);
				} else {
					var arr = cast(arr, Array<Dynamic>);
					var index:Int = cast(index, Int);
					getter = () -> arr[index];
					setter = (val) -> arr[index] = val;
				}
			default: throw "Unknown getter/setter handing for expression " + e;
		}
		return [getter, setter];
	}

	public function expr(e: Expr):Dynamic {
		if (e == null)
			return null;
		switch (e.expr) {
			case EConst(c):
				return switch (c) {
					case CInt(i): i;
					case CFloat(f): f;
					case CString(s, _): s;
					case CIdent(s): switch (getVar(s)) {
						case Some(v): v.value;
						case None: null;
					}
					//case CRegexp(s, _): s;
					default: throw "Unknown constant";
				}
			case EArray(arr, index):
				var arr:Dynamic = expr(arr);
				var index:Dynamic = expr(index);
				if(arr is IMap) {
					return cast(arr, IMap<Dynamic, Dynamic>).get(index);
				} else {
					return arr[index];
				}
			case EBinop(op, e1, e2):
				switch (op) {
					// temp code
					case BOpEq:
						var v1:Dynamic = expr(e1);
						var v2:Dynamic = expr(e2);
						return v1 == v2;
					case BOpNotEq:
						var v1:Dynamic = expr(e1);
						var v2:Dynamic = expr(e2);
						return v1 != v2;
					case BOpGt:
						var v1:Dynamic = expr(e1);
						var v2:Dynamic = expr(e2);
						return v1 > v2;
					case BOpGte:
						var v1:Dynamic = expr(e1);
						var v2:Dynamic = expr(e2);
						return v1 >= v2;
					case BOpLt:
						var v1:Dynamic = expr(e1);
						var v2:Dynamic = expr(e2);
						return v1 < v2;
					case BOpLte:
						var v1:Dynamic = expr(e1);
						var v2:Dynamic = expr(e2);
						return v1 <= v2;
					case BOpAdd:
						var v1:Dynamic = expr(e1);
						var v2:Dynamic = expr(e2);
						return v1 + v2;
					case BOpSub:
						var v1:Float = expr(e1);
						var v2:Float = expr(e2);
						return v1 - v2;
					case BOpMult:
						var v1:Float = expr(e1);
						var v2:Float = expr(e2);
						return v1 * v2;
					case BOpDiv:
						var v1:Float = expr(e1);
						var v2:Float = expr(e2);
						return v1 / v2;
					case BOpMod:
						var v1:Float = expr(e1);
						var v2:Float = expr(e2);
						return v1 % v2;
					case BOpAnd:
						var v1:Int = expr(e1);
						var v2:Int = expr(e2);
						return v1 & v2;
					case BOpOr:
						var v1:Int = expr(e1);
						var v2:Int = expr(e2);
						return v1 | v2;
					case BOpXor:
						var v1:Int = expr(e1);
						var v2:Int = expr(e2);
						return v1 ^ v2;
					case BOpShr:
						var v1:Int = expr(e1);
						var v2:Int = expr(e2);
						return v1 >> v2;
					case BOpShl:
						var v1:Int = expr(e1);
						var v2:Int = expr(e2);
						return v1 << v2;
					case BOpUShr:
						var v1:Int = expr(e1);
						var v2:Int = expr(e2);
						return v1 >>> v2;
					case BOpBoolAnd:
						return expr(e1) && expr(e2);
					case BOpBoolOr:
						return expr(e1) || expr(e2);
					case BOpNullCoal:
						var v1 = expr(e1);
						return v1 == null ? expr(e2) : v1;
					case BOpAssign:
						var v = getVarFromExpr(e1);
						return switch (v) {
							case Some(v): v.value = expr(e2);
							case None: throw "Unknown variable " + e1;
						}
					case BOpAssignOp(op):
						//var v = getVarFromExpr(e1);
						//return switch (v) {
						//	case Some(v): v.value = expr(e2);
						//	case None: throw "Unknown variable " + e1;
						//}
						throw "Binop assign op not implemented";
					case BOpIn | BOpArrow:
						throw "Unknown binop " + op;
					case BOpInterval:
						return new IntIterator(expr(e1), expr(e2));
					//default:
				}
				throw "Unknown binop " + op;
			case EField(e, name, EFNormal):
				var e = expr(e);
				return Reflect.getProperty(e, name);
			case EField(e, name, EFSafe):
				var e = expr(e);
				return e != null ? UnsafeReflect.getProperty(e, name) : null;
			case EParenthesis(e):
				return expr(e);
			case EObjectDecl(fields):
				var obj = {};
				//depth++;
				for (f in fields) {
					UnsafeReflect.setField(obj, f.field, expr(f.expr));
				}
				//depth--;
				return obj;
			case EArrayDecl(exprs):
				var arr = new Vector<Dynamic>(exprs.length);
				//depth++; // cant declare in a array
				for(i in 0...exprs.length) {
					arr[i] = expr(exprs[i]);
				}
				//depth--;
				return arr;
			case ECall(e, args):
				var isSafe = switch (e.expr) {
					case EField(_, _, EFSafe): true;
					default: false;
				}
				var f = expr(e);
				if(f == null) // clean this up
					if(isSafe)
						return null;
					else
						throw "Cannot call null";
				var args = [for (a in args) expr(a)];
				if(!UnsafeReflect.isFunction(f))
					throw "Cannot call non function";
				// trace(HelperUtils.getIdentFromExpr(e) ,args, depth);
				return UnsafeReflect.callMethodUnsafe(null, f, args);
			case ENew(path, args):
				var pack = HelperUtils.getPackFromTypePath(path.path);
				var cls = switch(getVar(pack)) {
					case Some(v): v.value;
					case None: Type.resolveClass(pack);
				}
				if (cls == null)
					throw "Unknown class";
				if(!UnsafeReflect.isClass(cls))
					throw "Cannot create instance of non class";
				var args = [for (a in args) expr(a)];
				return Type.createInstance(cls, args);
			case EUnop(op, op_flag, e):
				switch(op) {
					case UIncrement | UDecrement:
						var __ = getGetSetFromExpr(e);
						var getter:Void->Dynamic = __[0];
						var setter:Dynamic = __[1];

						var delta = switch (op) {
							case UIncrement: 1;
							case UDecrement: -1;
							default: throw "Unknown unop";
						}

						var val = getter();
						setter(op_flag == UFPrefix ? val += delta : val + delta);
						return val;
					default:
						if(op_flag == UFPostfix) throw "Unknown postfix unop";
						var e:Dynamic = expr(e);
						return switch (op) {
							case UNot: !e;
							case UNeg: -e;
							case UNegBits: ~e;
							default: throw "Unknown unop";
						}
				}
			case EVars(vars):
				for(v in vars) {
					pushVar(v.name.string, expr(v.expr), null);
				}
				return null;
			case EFunction(fk, fun):
				var totalArgs = 0;
				var minArgs = 0;
				for (a in fun.args) {
					totalArgs += 1;
					if (a.opt) // Default args are treated as optional in the parser
						minArgs++;
				}

				var funcName = switch (fk) {
					case FAnonymous: "anonymous function";
					case FNamed(name, _): "function named " + name.string;
					case FArrow: "arrow function";
				}
				funcName += " (" + totalArgs + ")" + " at " + e.pos;

				// To make faster and more memory efficient generated code
				var closureFunc = funcName;
				var closureMinArgs = minArgs;
				// todo: make this not use reflection
				var f = function(args: Array<Dynamic>) {
					depth++;
					if(args.length < closureMinArgs) {
						throw "Not enough arguments for " + closureFunc + " got " + args.length + " expected " + closureMinArgs;
					}
					for (i=>v in fun.args) {
						//var type = null;
						//if (v.type_hint != null) {
						//	type = v.type_hint;
						//}
						var argValue = null;
						if(i > args.length) {
							if(v.value != null) {
								argValue = expr(v.value);
							}
						} else {
							argValue = args[i];
						}
						pushVar(v.name.string, argValue, null);
					}

					var ret = try {
						expr(fun.expr);
					} catch (err:Stop) {
						switch (err) {
							case SReturn(v): v;
							case SBreak: throw "Invalid break";
							case SContinue: throw "Invalid continue";
						}
					}
					depth--;
					return ret;
				}

				var pureFuncName = switch (fk) {
					case FAnonymous: null;
					case FNamed(name, _): name.string;
					case FArrow: null;
				};
				var argsFunc =  RuntimeUtils.getNamedVarArgsFunction(funcName, f);
				if (pureFuncName != null) pushVar(pureFuncName, argsFunc);
				return argsFunc;
			case EBlock(exprs):
				var ret = null;
				depth++;
				var exprs:Vector<Expr> = cast exprs;
				for (i in 0...exprs.length) {
					ret = expr(exprs[i]);
				}
				depth--;
				return ret;
			case EFor(iterator, e):
				var keyvar:DeclaredVar = null;
				var valuevar:DeclaredVar = null;
				var it:Dynamic = null;
				var hasKey:Bool = false;

				switch (iterator.expr) {
					case EBinop(BOpIn, e1, e2):
						switch (e1.expr) {
							case EBinop(BOpArrow, _.expr => EConst(CIdent(key)), _.expr => EConst(CIdent(value))):
								keyvar = {name: key, value: null};
								valuevar = {name: value, value: null};
								hasKey = true;
							default:
						}
						if(valuevar == null) {
							valuevar = {name: HelperUtils.getIdentFromExpr(e1), value: null}
						}

						if(valuevar.name == null || (hasKey && keyvar.name == null)) throw "Expected identifier";
						it = (hasKey ? RuntimeUtils.keyValueIterator : RuntimeUtils.iterator)(expr(e2));
					default:
						throw "Invalid for loop iterator";
				}

				var _hasNext = it.hasNext; var _next = it.next;

				if (hasKey) pushDecl(keyvar);
				pushDecl(valuevar);

				var ret = null;
				while (_hasNext()) {
					var next = _next();
					if(hasKey) {
						keyvar.value = next.key;
						valuevar.value = next.value;
					} else {
						valuevar.value = next;
					}
					try {
						ret = expr(e);
					} catch (err:Stop) {
						switch (err) {
							case SContinue:
							case SBreak: break;
							case SReturn(v): throw err;
						}
					}
				}
				return ret;
			case EIf(cond, true_expr, false_expr):
				var ret = expr(cond);
				if (ret) {
					return expr(true_expr);
				} else {
					return expr(false_expr);
				}
			case EWhile(cond, e, flag):
				switch (flag) {
					case WFNormalWhile:
						while (expr(cond) == true) {
							try {
								expr(e);
							} catch( e: Stop ) {
								switch (e) {
									case SReturn(v): throw e;
									case SBreak: break;
									case SContinue: continue;
								}
							}
						}
					case WFDoWhile:
						do {
							try {
								expr(e);
							} catch( e: Stop ) {
								switch (e) {
									case SReturn(v): throw e;
									case SBreak: break;
									case SContinue: continue;
								}
							}
						} while (expr(cond) == true);
				}
				return null;
			case ESwitch(e, cases, default_case):
				var val = expr(e);
				for (c in cases) {
					for(v in c.values) {
						if (val == expr(v)) {
							depth++;
							var ret = expr(c.expr);
							depth--;
							return ret;
						}
					}
				}
				return expr(default_case.expr);
			case ESwitchComplex(e, cases, default_case):
				throw "TODO: implement switch complex";
				//var ret = expr(e);
				//for (c in cases) {
				//	if (ret == c.expr) {
				//		return expr(c.expr);
				//	}
				//}
				//return expr(default_case.expr);
			case ETry(e, catches):
				try {
					return expr(e);
				}
				catch( e: Stop ) {
					throw e;
				}
				catch (e: Dynamic) {
					for (c in catches) {
						// TODO: handle catches
						//if (Std.isOfType(e, c.type.type)) {
						//	return expr(c.expr);
						//}
					}
					throw e;
				}
			case EReturn(e):
				throw Stop.SReturn(expr(e));
			case EBreak:
				throw Stop.SBreak;
			case EContinue:
				throw Stop.SContinue;
			case EUntyped(e):
				return expr(e); // TODO: untyped maybe?
			case EThrow(e):
				throw expr(e);
			case ECast(e, type_hint):
				return expr(e); // TODO: cast
			case EIs(e, type_hint):
				return expr(e); // TODO: is
			case ETernary(cond, true_expr, false_expr):
				return expr(cond) ? expr(true_expr) : expr(false_expr);
			case ECheckType(e, type_hint):
				return expr(e); // TODO: check type
			case EMeta(entry, e):
				return expr(e); // TODO: meta, handle @:bypassAccessor
		}
		return null;
	}
}

enum Stop {
	SReturn(v: Dynamic);
	SBreak;
	SContinue;
}
