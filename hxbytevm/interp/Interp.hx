package hxbytevm.interp;

import hxbytevm.utils.RuntimeUtils;
import hxbytevm.core.Ast;

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
	public function new() {}

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

	public function getLocal(name: String): DeclaredVar {
		var len = decls.length;
		for (i in 0...len) {
			var idx = len - i - 1; // make it go from the end to the beginning
			var scope = decls[idx];
			var scopeLength = scope.length;
			for(j in 0...scopeLength) {
				var v = scope[scopeLength - j - 1];
				if (v.name == name) {
					return v;
				}
			}
		}

		return null;
	}

	public function getVar(name: String): DeclaredVar {
		var val = getLocal(name);
		if (val != null) {
			return val;
		}

		return null;
	}

	public function getIdentFromExpr(e: Expr): String {
		switch (e.expr) {
			case EConst(c):
				return switch (c) {
					case CIdent(s): s;
					default: null;
				}
			default:
		}
		return null;
	}

	public function getVarFromExpr(e: Expr): DeclaredVar {
		switch (e.expr) {
			case EConst(c):
				return switch (c) {
					case CIdent(s): getVar(s);
					default: null;
				}
			default:
		}
		return null;
	}

	public function expr(e: Expr):Dynamic {
		switch (e.expr) {
			case EConst(c):
				return switch (c) {
					case CInt(i): i;
					case CFloat(f): f;
					case CString(s, _): s;
					case CIdent(s): getVar(s).value;
					//case CRegexp(s, _): s;
					default: throw "Unknown constant";
				}
			case EArray(arr, index):
				var arr = expr(arr);
				var index = expr(index);
				return arr[index];
			case EBinop(op, e1, e2):
				switch (op) {
					case BOpAssign:
						var v = getVarFromExpr(e1);
						if (v == null) {
							throw "Unknown variable";
						}

						return v.value = expr(e2);
					default:
				}
				throw "Unknown binop";
			case EField(e, name, EFNormal):
				var e = expr(e);
				return Reflect.field(e, name);
			case EField(e, name, EFSafe):
				var e = expr(e);
				return e != null ? Reflect.field(e, name) : null;
			case EParenthesis(e):
				return expr(e);
			case EObjectDecl(fields):
				var obj = {};
				depth++;
				for (f in fields) {
					Reflect.setField(obj, f.name, expr(f.expr));
				}
				depth--;
				return obj;
			case EArrayDecl(exprs):
				var arr = [];
				depth++;
				for (e in exprs) {
					arr.push(expr(e));
				}
				depth--;
				return arr;
			case ECall(e, args):
				var e = expr(e);
				var args = [for (a in args) expr(a)];
				return Reflect.callMethod(null, e, args);
			case ENew(path, args):
				var pack = "";
				for(p in path.path.tpackage) {
					pack += p + ".";
				}
				pack += path.path.tname;
				var cls = Type.resolveClass(pack);
				var args = [for (a in args) expr(a)];
				return Type.createInstance(cls, args);
			case EUnop(op, op_flag, e):
				var e:Dynamic = expr(e);
				return switch (op) {
					case UIncrement if (op_flag == UFPostfix): e++;
					case UDecrement if (op_flag == UFPostfix): e--;
					case UIncrement if (op_flag == UFPrefix): ++e;
					case UDecrement if (op_flag == UFPrefix): --e;
					case UNot: !e;
					case UNeg: ~e;
					case UNegBits: Std.int(~e);
					// case USpread: throw "Unknown unop";
					default: throw "Unknown unop";
				}
			case EVars(vars):
				for(v in vars) {
					pushVar(v.ev_name.string, expr(v.ev_expr), null);
				}
				return null;
			case EFunction(fk, f):
				// var args = [for (a in f.f_params) a.tp_name.string];
				var f = function(args: Array<Dynamic>) {
					for (i=>v in f.f_args) {
						var type = null;
						if (v.type_hint != null) {
							type = v.type_hint;
						}
						pushVar(v.name.string, args[i], null);
					}
					return expr(f.f_expr);
				}
				return Reflect.makeVarArgs(f);
			case EBlock(exprs):
				var ret = null;
				depth++;
				for (i => e in exprs)
					if (i < exprs.length)
						ret = expr(e);
				depth--;
				return ret;
			case EFor(ident, iterator):
				var keyvar:DeclaredVar = null;
				var valuevar:DeclaredVar = null;

				switch (ident.expr) {
					case EBinop(BOpArrow, _.expr => EConst(CIdent(key)), _.expr => EConst(CIdent(value))):
						keyvar = {name: key, value: null};
						valuevar = {name: value, value: null};
					default:
						valuevar = {name: getIdentFromExpr(ident), value: null}
				}

				var hasKey:Bool = keyvar != null;

				var it = (hasKey ? RuntimeUtils.keyValueIterator : RuntimeUtils.iterator)(expr(iterator));
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
				return expr(e);
			case EThrow(e):
				throw expr(e);
			case ECast(e, type_hint):
				return expr(e);
			case EIs(e, type_hint):
				return expr(e);
			case ETernary(cond, true_expr, false_expr):
				var ret = expr(cond);
				if (ret) {
					return expr(true_expr);
				} else {
					return expr(false_expr);
				}
			case ECheckType(e, type_hint):
				return expr(e);
			case EMeta(entry, e):
				return expr(e);
		}
		return null;
	}
}

enum Stop {
	SReturn(v: Dynamic);
	SBreak;
	SContinue;
}