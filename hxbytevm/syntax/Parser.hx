package hxbytevm.syntax;

import hxbytevm.syntax.Lexer;
import hxbytevm.core.Ast;

class Parser {
	public function new() {}

	public function parse(tokens : Array<Token>) : Expr {
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

	@:pure public function mk(e : ExprDef, ?pos : Pos = null) : Expr {
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
