/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package hxbytevm.printer;

// Copyright included since a lot of it is from the haxe.macro.Printer class

import hxbytevm.vm.Program;
import hxbytevm.core.Ast;

using StringTools;

class Printer {
	var indentation : Int;

	private function new() {
		indentation = 0;
	}

	static function isJson(s:String) {
		var len = s.length;
		var i = 0;
		while (i < len) {
			var c = StringTools.fastCodeAt(s, i++);
			if(c >= 'a'.code && c <= 'z'.code) continue;
			if(c >= 'A'.code && c <= 'Z'.code) continue;
			if(c >= '0'.code && c <= '9'.code) continue;
			if(c == '_'.code) continue;
			return false;
		}
		return true;
	}

	static inline function isPrintable( c : Int ) {
		return c >= 32 && c <= 126;
	}

	static inline function hex( c : Int, ?len : Int = 2 ) {
		return StringTools.hex(c, len).toLowerCase();
	}

	public static function getEscapedString( s : String ) {
		var buf = new StringBuf();
		#if target.unicode
		var s = new UnicodeString(s);
		#end
		for( i in 0...s.length ) {
			#if target.unicode
			var c:Null<Int> = s.charCodeAt(i);
			#else
			var c:Null<Int> = StringTools.unsafeCodeAt(s, i);
			#end
			switch( c ) {
				case '"'.code: buf.add('\\"');
				case '\\'.code: buf.add('\\\\');
				case '\n'.code: buf.add('\\n');
				case '\r'.code: buf.add('\\r');
				case '\t'.code: buf.add('\\t');
				default:
					if(c == null) continue;
					if(isPrintable(c))
						buf.addChar(c);
					else {
						if(c > 0xFF) {
							buf.add("\\u{");
							buf.add(hex(c, null));
							buf.add("}");
						} else {
							buf.add("\\x");
							buf.add(hex((c & 0xFF)));
						}
					}
			}
		}
		return buf.toString();
	}

	public function printUnop(op:Unop)
		return switch (op) {
			case UIncrement: "++";
			case UDecrement: "--";
			case UNot: "!";
			case UNeg: "-";
			case UNegBits: "~";
			case USpread: "...";
		}

	public function printBinop(op:Binop)
		return switch (op) {
			case BOpAdd: "+";
			case BOpMult: "*";
			case BOpDiv: "/";
			case BOpSub: "-";
			case BOpAssign: "=";
			case BOpEq: "==";
			case BOpNotEq: "!=";
			case BOpGt: ">";
			case BOpGte: ">=";
			case BOpLt: "<";
			case BOpLte: "<=";
			case BOpAnd: "&";
			case BOpOr: "|";
			case BOpXor: "^";
			case BOpBoolAnd: "&&";
			case BOpBoolOr: "||";
			case BOpShl: "<<";
			case BOpShr: ">>";
			case BOpUShr: ">>>";
			case BOpMod: "%";
			case BOpInterval: "...";
			case BOpArrow: "=>";
			case BOpIn: "in";
			case BOpNullCoal: "??";
			case BOpAssignOp(op):
				printBinop(op) + "=";
		}

	public function printExprs(el:Array<Expr>, sep:String) {
		return el.map(expr).join(sep);
	}

	public function printArray<T>(el:Array<T>, map:T->String, sep:String) {
		return el.map(map).join(sep);
	}

	public static function printCompiledProgram(program:Program):String {
		return program.print();
	}

	public static function printExpr(e:Expr):String {
		return new Printer().expr(e);
	}

	public function indent() {
		indentation++;
	}

	public function outdent() {
		indentation--;
	}

	public function getIndent() {
		return StringTools.lpad("", "\t", indentation);
	}

	public static function isBlock(e:Expr):Bool {
		return switch e.expr {
			case EBlock(_): true;
			default: false;
		}
	}

	public function printConstant(c:Constant)
		return switch (c) {
			case CString(s, SSingleQuotes): "'" + s + "'";
			case CString(s, _): '"' + s + '"';
			case CIdent(value): value;
			case CInt(value, suffix): value + (suffix == null ? "" : suffix);
			case CFloat(value, suffix): value + (suffix == null ? "" : suffix);
			case CRegexp(s, opt): '~/$s/$opt';
		}

	public function printComplexType(ct:ComplexType) {
		return switch (ct) {
			case CTPath(tp): printTypePath(tp.path);
			case CTFunction(args, ret):
				var wrapArgumentsInParentheses = switch args {
					// type `:(a:X) -> Y` has args as [TParent(TNamed(...))], i.e `a:X` gets wrapped in `TParent()`. We don't add parentheses to avoid printing `:((a:X)) -> Y`
					case [CTParent(t)]: false;
					// this case catches a single argument that's a type-path, so that `X -> Y` prints `X -> Y` not `(X) -> Y`
					case [CTPath(_) | CTOptional(CTPath(_))]: false;
					default: true;
				}
				var argStr = args.map((v)->printComplexType(v)).join(", ");
				(wrapArgumentsInParentheses ? '($argStr)' : argStr) + " -> " + (switch ret {
					// wrap return type in parentheses if it's also a function
					case CTFunction(_): '(${printComplexType(ret)})';
					default: (printComplexType(ret) : String);
				});
			case CTAnonymous(fields): "{ " + [for (f in fields) printField(f) + "; "].join("") + "}";
			case CTParent(ct): "(" + printComplexType(ct) + ")";
			case CTOptional(ct): "?" + printComplexType(ct);
			case CTNamed(n, ct): n + ":" + printComplexType(ct);
			case CTExtend(tpl, fields):
				var types = [for (t in tpl) "> " + printTypePath(t.path) + ", "].join("");
				var fields = [for (f in fields) printField(f) + "; "].join("");
				'{${types}${fields}}';
			case CTIntersection(tl): tl.map((v)->printComplexType(v)).join(" & ");
		}
	}

	public function printField(field:ClassField) {
		inline function orderAccess(access:Array<Access>) {
			// final should always be printed last
			// (does not modify input array)
			return access.contains(AFinal) ? access.filter(a -> !a.match(AFinal)).concat([AFinal]) : access;
		}

		var s = "";
		function add(st:String) {s += st;}

		//add(field.cff_doc != null && field.cff_doc != "" ? "/**\n"
		//	+ tabs
		//	+ tabString
		//	+ StringTools.replace(field.cff_doc, "\n", "\n" + tabs + tabString)
		//	+ "\n"
		//	+ tabs
		//	+ "**/\n"
		//	+ tabs : "");
		add(orderAccess(field.cff_access).map(printAccess).join(" ") + " ");
		add(switch (field.cff_kind) {
			case CFKVar(t, eo): '${field.cff_name.string}' + opt(t, printComplexType, " : ") + opt(eo, expr, " = ");
			case CFKProp(get, set, t, eo): 'var ${field.cff_name.string}(${get.string}, ${set.string})' + opt(t, printComplexType, " : ") + opt(eo, expr, " = ");
			case CFKFun(func): 'function ${field.cff_name.string}' + printFunction(func);
		});

		return s;
	}

	public function printTypeParamDecl(tpd:TypeParamDecl) {
		return (tpd.meta != null && tpd.meta.length > 0 ? tpd.meta.map(printMetadata).join(" ") + " " : "")
			+ tpd.name
			//+ (tpd.params != null && tpd.params.length > 0 ? "<" + tpd.params.map(printTypeParamDecl).join(", ") + ">" : "")
			+ (tpd.constraints != null ? ":(" + printComplexType(tpd.constraints) + ")" : "")
			+ (tpd.defaultType != null ? "=" + printComplexType(tpd.defaultType) : "");
	}

	public function printFunctionArg(arg:FuncArg) {
		return (arg.opt ? "?" : "") + arg.name.string + opt(arg.type, printComplexType, ":") + opt(arg.value, expr, " = ");
	}

	public function printFunction(func:Func, ?kind:FunctionKind) {
		var skipParentheses = switch func.args {
			case [{type: null}]: kind == FArrow;
			case _: false;
		}
/*(func.params == null ? "" : func.params.length > 0 ? "<" + func.params.map(printTypeParamDecl).join(", ") + ">" : "")
			+ */

		return (skipParentheses ? "" : "(")
			+ func.args.map(printFunctionArg).join(", ")
			+ (skipParentheses ? "" : ")")
			+ (kind == FArrow ? " ->" : "")
			+ opt(func.ret, printComplexType, ":")
			+ opt(func.expr, expr, " ");
	}

	public function printTypePath(tp:TypePath) {
		return (tp.pack.length > 0 ? tp.pack.join(".") + "." : "")
			+ tp.name
			+ (tp.sub != null && tp.sub.length > 0 ? '.${tp.sub}' : "")
			+ (tp.params != null && tp.params.length > 0 ? "<" + tp.params.map(printTypeParam).join(", ") + ">" : "");
	}

	public function printTypeParam(param:TypeParam)
		return switch (param) {
			case TPType(ct): printComplexType(ct);
			case TPExpr(e): expr(e);
		}

	public function printAccess(access:Access)
		return switch (access) {
			case AStatic: "static";
			case APublic: "public";
			case APrivate: "private";
			case AOverride: "override";
			case AInline: "inline";
			case ADynamic: "dynamic";
			case AMacro: "macro";
			case AFinal: "final";
			case AExtern: "extern";
			case AAbstract: "abstract";
			case AOverload: "overload";
			case AEnum: "enum";
		}

	public function expr(e:Expr) {
		if(e == null) return "??NULL??";
		var s = "";
		inline function add(st:String) {
			s += st;
		}

		switch(e.expr) {
			case EBlock(exprs):
				add("{");
				indent();
					if(exprs.length > 0) add("\n" + getIndent());
					add(printExprs(exprs, ";\n" + getIndent()));
				outdent();
				if(!s.endsWith("}")) add(";");
				if(exprs.length > 0) add("\n" + getIndent());
				add("}");
			case EBinop(op, e1, e2):
				add(expr(e1));
				add(" ");
				add(printBinop(op));
				add(" ");
				add(expr(e2));
			case EUnop(op, flag, e):
				add(printUnop(op));
				add(" ");
				add(expr(e));
			case EConst(c):
				switch(c) {
					case CInt(i, suffix):
						return i + (suffix == null ? "" : suffix);
					case CFloat(f, suffix):
						return f + (suffix == null ? "" : suffix);
					case CString(s, q):
						switch (q) {
							case SSingleQuotes: return ("'" + s + "'");
							case SDoubleQuotes: return ('"' + s + '"');
						}
					case CIdent(s):
						return s;
					case CRegexp(value, options):
						return "~/" + value + "/" + options;
				}
			case EField(e, f, flag):
				add(expr(e));
				switch(flag) {
					case EFNormal: add(".");
					case EFSafe: add("?.");
				}
				add(f);
			case EArray(e, e1):
				return expr(e) + "[" + expr(e1) + "]";
			case EIf(econd, eif, eelse):
				add("if(");
				add(expr(econd));
				add(")");
				if(!isBlock(eif)) add(" ");
				add(expr(eif));
				if(eelse != null) {
					if(!isBlock(eif)) add(" ");
					add("else");
					if(!isBlock(eelse)) add(" ");
					add(expr(eelse));
				}
			case EWhile(econd, e, flag):
				switch (flag) {
					case WFNormalWhile:
						add("while(");
						add(expr(econd));
						add(") ");
						add(expr(e));
					case WFDoWhile:
						add("do ");
						add(expr(e));
						add(" while(");
						add(expr(econd));
						add(")");
				}
			case EFor(iterator, e):
				add("for(");
				add(expr(iterator));
				add(")");
				add(expr(e));
			case EFunction(kind, func):
				switch (kind) {
					case FArrow: add("(");
					case FAnonymous: add("function");
					case FNamed(name, isInline):
						if (isInline) add("inline ");
						add("function ");
						add(name.string);
				}
				add(printFunction(func, kind));
			case EArrayDecl(exprs):
				add("[");
				for(e in exprs) {
					add(expr(e));
					add(",");
				}
				add("]");
			case EObjectDecl(fields):
				add("{");
				indent();
				for(field in fields) {
					switch(field.quotes) {
						case null | QUnquoted:
							add(field.field);
						case QQuoted:
							add('"' + getEscapedString(field.field) + '"');
					}
					add(": ");
					add(expr(field.expr));
					add(",");
				}
				outdent();
				add("}");
			case ETry(e, catches):
				add("try");
				add("{");
				indent();
				add(expr(e));
				outdent();
				add("}");
				for(ctch in catches) {
					add("catch(");
					add(ctch.v);
					add(":");
					add(printComplexType(ctch.type));
					add(")");
					add("{");
					indent();
					add(expr(ctch.expr));
					outdent();
					add("}");
				}
			case EThrow(e):
				add("throw ");
				add(expr(e));
			case EReturn(e):
				if(e != null) {
					add("return ");
					add(expr(e));
				} else {
					add("return");
				}
			case EBreak:
				add("break");
			case EContinue:
				add("continue");
			case ECall(e, args):
				add(expr(e));
				add("(");
				add(printExprs(args, ", "));
				add(")");
			case ECast(e, type):
				add("cast(");
				expr(e);
				add(", ");
				add(printComplexType(type));
				add(")");
			case ECheckType(e, type):
				add("(");
				expr(e);
				add(" : ");
				add(printComplexType(type));
				add(")");
			case EIs(e, type):
				add(expr(e));
				add(" is ");
				add(printComplexType(type));
			case EMeta(meta, e):
				add(printMetadata(meta));
				add(" ");
				add(expr(e));
			case ENew(path, e):
				add("new ");
				var path = path.path;
				if(path.pack != null && path.pack.length > 0) {
					add(path.pack.join("."));
					add(".");
				}
				add(path.name);
				if(e != null) {
					add("(");
					add(printExprs(e, ", "));
					add(")");
				}
			case EParenthesis(e): "(" + expr(e) + ")";
			case ESwitch(e, cases, default_case):
				var s = "";
				function add(st:String) s += st;
				add("switch ");
				add(expr(e));
				add(" {");
				indent();
				for(c in cases) {
					add("case ");
					add(printExprs(c.values, ", "));
					add(":");
					add(expr(c.expr));
					add(";");
				}
				if(default_case != null) {
					add("default: ");
					add(expr(default_case.expr));
					add(";");
				}
				outdent();
				add("}");
			case ESwitchComplex(expr, cases, default_case):
				throw "Not implemented";
			case ETernary(cond, true_expr, false_expr): expr(cond) + " ? " + expr(true_expr) + " : " + expr(false_expr);
			case EUntyped(e): "untyped " + expr(e);
			case EVars([]): "var ";
			case EVars(v):
				if(v[0].isPublic) add("public ");
				if(v[0].isStatic) add("static ");
				add(v[0].isFinal ? "final " : "var ");

				for(v in v) {
					add(printVar(v));
				}
		}

		return s;
	}

	function opt<T>(v:T, f:T->String, prefix = "")
		return v == null ? "" : (prefix + f(v));

	public function printVar(v:Evar) {
		var s = v.name.string + opt(v.type, printComplexType, ":") + opt(v.expr, expr, " = ");
		return switch v.meta {
			case null | []: s;
			case meta: meta.map(printMetadata).join(" ") + " " + s;
		}
	}

	function printMetadata(meta:MetadataEntry):String {
		var s = "";
		inline function add(st:String) {s += st;}
		add("@" + meta.name);
		if(meta.params != null && meta.params.length > 0) {
			add("(");
			printExprs(meta.params, ", ");
			add(")");
		}
		return s;
	}
}
