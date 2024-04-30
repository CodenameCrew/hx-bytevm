package hxbytevm.syntax;

import hxbytevm.syntax.Lexer;
import hxbytevm.core.Ast;

class Parser {
	public function new() {}

	public function parse( tokens : Array<Token> ) : Expr {
		return mk(EBlock([
			mk(ECall(mk(EConst(CIdent("trace")), 0), [
				mk(EConst(CString("Hello World", SSingleQuotes)), 0)
			]), 0)
		]), 0);
	}

	public function mk( e : ExprDef, ?pos : Pos = null ) : Expr {
		return { expr : e, pos : pos };
	}
}