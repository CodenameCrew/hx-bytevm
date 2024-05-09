package hxbytevm.utils;

import hxbytevm.core.Ast.Expr;

class ExprUtils {
	public static function iter( e : Expr, f : Expr -> Void ) {
		if (e == null || e.expr == null) return;
		switch( e.expr ) {
			case EArray(arr, index): f(arr); f(index);
			case EArrayDecl(expr): for (e in expr) f(e);
			case EBinop(binop, expr1, expr2): f(expr1); f(expr2);
			case EBlock(exprs): for (e in exprs) f(e);
			case ECall(expr, args): f(expr); for (arg in args) f(arg);
			case ECast(expr, type): f(expr);
			case ECheckType(expr, type): f(expr);
			case EField(expr, name, kind): f(expr);
			case EFor(iterator, expr): f(iterator); f(expr);
			case EFunction(func_kind, func): f(func.expr); for (arg in func.args) f(arg.value);
			case EIf(cond, expr, else_expr): f(cond); f(expr); f(else_expr);
			case EIs(expr, type): f(expr);
			case EMeta(entry, expr): f(expr); for (e in entry.params) f(e);
			case ENew(path, expr): for (e in expr) f(e);
			case EObjectDecl(fields): for (field in fields) f(field.expr);
			case EParenthesis(expr): f(expr);
			case EReturn(expr): f(expr);
			case ESwitch(expr, cases, default_case):
				f(expr); f(default_case.expr);
				for (_case in cases) {
					f(_case.expr); for (v in _case.values) f(v);
				}
			case ESwitchComplex(expr, cases, default_case):
				f(expr); f(default_case.expr);
				for (_case in cases) {
					f(_case.expr); f(_case.guard); for (v in _case.values) f(v);
				}
			case ETernary(cond, true_expr, false_expr): f(cond); f(true_expr); f(false_expr);
			case EThrow(expr): f(expr);
			case ETry(expr, catches): f(expr); for (c in catches) f(c.expr);
			case EUnop(unop, unop_flag, expr): f(expr);
			case EUntyped(expr): f(expr);
			case EVars(vars): for (v in vars) f(v.expr);
			case EWhile(cond, expr, flag): f(cond); f(expr);
			default:
		}
	}

	public static function recursive( expr : Expr, f : Expr -> Void ) {
		f(expr);
		ExprUtils.iter(expr, (e:Expr) -> {
			ExprUtils.recursive(e, f);
		});
	}

	public static function fieldToList( field : Expr, _arr : Array<String> = null ) : Array<String> {
		if (_arr == null) _arr = [];
		if (field == null) return _arr;
		switch( field.expr ) {
			case EField(e, name, _): fieldToList(e, _arr); _arr.push(name);
			case EConst(CIdent(value)): _arr.push(value);
			default: throw Errors.Exit;
		}
		return _arr;
	}
}
