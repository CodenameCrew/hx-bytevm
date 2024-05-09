package hxbytevm.syntax;

import hxbytevm.syntax.Lexer;
import hxbytevm.core.Ast;

class Parser {
	public function new() {}

	public function parseTokens(tokens : Array<Token>) : Expr {
		var pos = 0;
		var getter = () -> tokens[pos++];
		return parse(getter);
	}

	public function parse(getter : Void -> Token) : Expr {
		var exprs:Array<Expr> = [];



		//return mk(EBlock([
		//	mk(ECall(mk(EConst(CIdent("trace"))), [
		//		mk(EConst(CString("Hello World", SSingleQuotes)))
		//	]))
		//]));

		if(exprs.length == 1)
			return exprs[0];
		return mk(EBlock(exprs));
	}

	public static function giveExpr(getter : Void -> Token) : Expr {
		var parser = new Parser();
		var expr = parser.parse(getter);
		return expr;
	}

	public static function makeUnop(op:Unop, e:Expr, pos:Pos):Expr {
		var p2 = e.pos;
		var p1 = pos;
		//function neg(s:String):String {
		//	if(s.charAt(0) == '-') return s.substr(1);
		//	return "-" + s;
		//}
		return switch(e.expr) {
			case EBinop(bop, e1, e2): mk(EBinop(bop, makeUnop(op, e1, p1), e2), AstUtils.punion(p1, p2));
			case ETernary(e1, e2, e3): mk(ETernary(makeUnop(op, e1, p1), e2, e3), AstUtils.punion(p1, p2));
			case EIs(e, t): mk(EIs(makeUnop(op, e, p1), t), AstUtils.punion(p1, p2));
			// Originally in haxe these are strings, but here they are ints and floats, so we *-1
			case EConst(CInt(i, suffix)): mk(EConst(CInt((i)*-1, suffix)), AstUtils.punion(p1, p2));
			case EConst(CFloat(j, suffix)): mk(EConst(CFloat((j)*-1, suffix)), AstUtils.punion(p1, p2));
			default: mk(EUnop(op, UFPrefix, e), AstUtils.punion(p1, p2));
		}
	}

	@:pure public static function mk(e : ExprDef, ?pos : Pos = null) : Expr {
		if(pos == null)
			pos = AstUtils.nullPos;
		return { expr : e, pos : pos };
	}
}

@:structInit // perhaps ?
class FileInfo {
	public var path:String;
	public var packageName:String;
	public var className:String;
	public var imports:Array<String>;
}
