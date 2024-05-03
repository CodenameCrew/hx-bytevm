package;

import hxbytevm.interp.Interp;
import hxbytevm.printer.Printer;
import hxbytevm.core.Ast;

class InterpTest {
	public static function mk( e : ExprDef, ?pos : Pos = null ) : Expr {
		if(pos == null) pos = {
			min : 0,
			max : 0,
			file : "InterpTest.hx",
		}
		return { expr : e, pos : pos };
	}

	public static function main() {
		run(mk(EBlock([
			mk(ECall(mk(EConst(CIdent("trace"))), [
				mk(EConst(CString("Hello World", SSingleQuotes)))
			]))
		])));

		run(mk(EBlock([
			mk(EVars([
				{
					name : {
						string : "i",
						pos: {
							min : 0,
							max : 0,
							file : "InterpTest.hx",
						}
					},
					isFinal : false,
					isStatic : false,
					isPublic : false,
					expr : mk(EConst(CInt(0))),
					meta : null
				}
			])),
			mk(EWhile(
				mk(
					EBinop(BOpLt, mk(EConst(CIdent("i"))), mk(EConst(CInt(10)))
				)),
				mk(EBlock([
					mk(EBinop(BOpAssign, mk(EConst(CIdent("i"))), mk(EBinop(BOpAdd, mk(EConst(CIdent("i"))), mk(EConst(CInt(1))))))),
					mk(ECall(mk(EConst(CIdent("trace"))), [
						{
							var op = mk(EBinop(
								BOpAdd,
								mk(EConst(CString("i = ", SSingleQuotes))),
								mk(EConst(CIdent("i")))
							));
							op;
						}
					]))
				])),
				WFNormalWhile
		))])));
	}

	public static function run( e : Expr ) {
		var interp = new Interp();
		interp.run(e);
		trace(Printer.printExpr(e));
	}
}
