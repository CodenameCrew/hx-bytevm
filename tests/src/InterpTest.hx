package;

import hxbytevm.interp.Interp;
import hxbytevm.printer.Printer;
import hxbytevm.core.Ast;

class InterpTest {

	public static var HELLO_WORLD_EXPR:Expr = mk(EBlock([
		mk(ECall(mk(EConst(CIdent("trace"))), [
			mk(EConst(CString("Hello World", SSingleQuotes)))
		]))
	]));

	public static var WHILE_LOOP_EXPR:Expr = mk(EBlock([
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
	))]));

	public static var FIBBONACCI_FUNCTION_RECURSIVE = {
		mk(EFunction(
			FNamed({
				string : "fib",
				pos: {
					min : 0,
					max : 0,
					file : "InterpTest.hx",
				}
			}, false),
			{
				//var ?params : Array<TypeParam>;
				args : [
					{
						name : {
							string : "n",
							pos: {
								min : 0,
								max : 0,
								file : "InterpTest.hx",
							}
						},
						opt : false,
						meta: null,
						type: CTPath({ path: TypePath({ pack: [], name: "Int", params: [], sub: "" }), pos_full: { min: 0, max: 0, file: "InterpTest.hx" }, pos_path: { min: 0, max: 0, file: "InterpTest.hx" } }),
						value: null
					}
				],
				ret: CTPath({ path: TypePath({ pack: [], name: "Int", params: [], sub: "" }), pos_full: { min: 0, max: 0, file: "InterpTest.hx" }, pos_path: { min: 0, max: 0, file: "InterpTest.hx" } }),
				expr: mk(EBlock([
					mk(EIf(
						mk(EBinop(BOpLte, mk(EConst(CIdent("n"))), mk(EConst(CInt(1))))), // if n <= 1
						mk(EReturn(mk(EConst(CIdent("n"))))), // return 0
						null
					)),
					mk(EReturn(
						mk(EBinop(
							BOpAdd,
							mk(ECall(EConst(CIdent("fib")), [
								mk(EBinop(BOpSub, mk(EConst(CIdent("n"))), mk(EConst(CInt(1)))))
							])),
							mk(ECall(EConst(CIdent("fib")), [
								mk(EBinop(BOpSub, mk(EConst(CIdent("n"))), mk(EConst(CInt(2)))))
							]))
						))
					))
				]))}
		));
	};

	public static function mk( e : ExprDef, ?pos : Pos = null ) : Expr {
		if(pos == null) pos = {
			min : 0,
			max : 0,
			file : "InterpTest.hx",
		}
		return { expr : e, pos : pos };
	}

	public static function main() {
		Sys.println(Util.getTitle("INTERP TESTING"));

		Sys.println(Util.getTitle("CALL TEST"));
		run(HELLO_WORLD_EXPR);

		Sys.println(Util.getTitle("WHILE LOOP TEST"));
		run(WHILE_LOOP_EXPR);
	}

	public static function run( e : Expr ) {
		var interp = new Interp();
		interp.run(e);
		Sys.println(Util.getTitle("EXPR PRINTED:") + "\n" + Printer.printExpr(e));
	}
}
