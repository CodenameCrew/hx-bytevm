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
		var block = [];
		block.push(mk(EFunction(
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
						type: CTPath({ path: { pack: [], name: "Int", params: [], sub: "" }, pos_full: { min: 0, max: 0, file: "InterpTest.hx" }, pos_path: { min: 0, max: 0, file: "InterpTest.hx" } }),
						value: null
					}
				],
				ret: CTPath({ path: { pack: [], name: "Int", params: [], sub: "" }, pos_full: { min: 0, max: 0, file: "InterpTest.hx" }, pos_path: { min: 0, max: 0, file: "InterpTest.hx" } }),
				expr: mk(EBlock([
					mk(EIf(
						mk(EBinop(BOpLte, mk(EConst(CIdent("n"))), mk(EConst(CInt(1))))), // if n <= 1
						mk(EReturn(mk(EConst(CIdent("n"))))), // return 0
						null
					)),
					mk(EReturn(
						mk(EBinop(
							BOpAdd,
							mk(ECall(mk(EConst(CIdent("fib"))), [
								mk(EBinop(BOpSub, mk(EConst(CIdent("n"))), mk(EConst(CInt(1)))))
							])),
							mk(ECall(mk(EConst(CIdent("fib"))), [
								mk(EBinop(BOpSub, mk(EConst(CIdent("n"))), mk(EConst(CInt(2)))))
							]))
						))
					))
				]))}
		)));
		block.push(mk(ECall(mk(EConst(CIdent("trace"))), [
			mk(EBinop(BOpAdd,
				mk(EConst(CString("fib(10) (Expected: 55) = ", SSingleQuotes))),
				mk(ECall(mk(EConst(CIdent("fib"))), [
					mk(EConst(CInt(10)))
				]))
			))
		])));
		block.push(mk(ECall(mk(EConst(CIdent("trace"))), [
			mk(EBinop(BOpAdd,
				mk(EConst(CString("fib(14) (Expected: 377) = ", SSingleQuotes))),
				mk(ECall(mk(EConst(CIdent("fib"))), [
					mk(EConst(CInt(14)))
				]))
			))
		])));
		mk(EBlock(block));
	};

	public static var FUNCTION_RECURSIVE = {
		var block = [];
		block.push(mk(EFunction(
			FNamed({
				string : "RECURSIVE",
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
						type: CTPath({ path: { pack: [], name: "Int", params: [], sub: "" }, pos_full: { min: 0, max: 0, file: "InterpTest.hx" }, pos_path: { min: 0, max: 0, file: "InterpTest.hx" } }),
						value: null
					}
				],
				ret: CTPath({ path: { pack: [], name: "Int", params: [], sub: "" }, pos_full: { min: 0, max: 0, file: "InterpTest.hx" }, pos_path: { min: 0, max: 0, file: "InterpTest.hx" } }),
				expr: mk(EBlock([
					mk(EIf(
						mk(EBinop(BOpLte, mk(EConst(CIdent("n"))), mk(EConst(CInt(1))))), // if n <= 1
						mk(EReturn(mk(EConst(CIdent("n"))))), // return 0
						null
					)),
					mk(ECall(mk(EConst(CIdent("trace"))), [
						mk(EBinop(BOpAdd,
							mk(EConst(CString("RECURSIVE N:", SSingleQuotes))),
							mk(EConst(CIdent("n")))
						))
					])),
					mk(EReturn(
						mk(ECall(mk(EConst(CIdent("RECURSIVE"))), [
							mk(EBinop(BOpSub, mk(EConst(CIdent("n"))), mk(EConst(CInt(1)))))
						]))
					))
				]))}
		)));
		block.push(mk(ECall(mk(EConst(CIdent("trace"))), [
			mk(EBinop(BOpAdd,
				mk(EConst(CString("RECURSIVE(10) (THIS IS LAST CALL) = ", SSingleQuotes))),
				mk(ECall(mk(EConst(CIdent("RECURSIVE"))), [
					mk(EConst(CInt(10)))
				]))
			))
		])));
		mk(EBlock(block));
	};

	public static var IF_STATEMENT:Expr = mk(EBlock([
		mk(EIf(
			mk(EBinop(BOpEq, mk(EConst(CInt(2))), mk(EConst(CInt(1))))), // if 2 == 1
			mk(ECall(mk(EConst(CIdent("trace"))), [
				mk(EConst(CString("Hello World", SSingleQuotes)))
			])),
			mk(ECall(mk(EConst(CIdent("trace"))), [
				mk(EConst(CString("NUH UH", SSingleQuotes)))
			]))
		)),
	]));


	public static var TEST_FUNCTION = {
		var block = [];
		block.push(mk(EFunction(
			FNamed({
				string : "test",
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
							string : "awesome",
							pos: {
								min : 0,
								max : 0,
								file : "InterpTest.hx",
							}
						},
						opt : false,
						meta: null,
						type: CTPath({ path: { pack: [], name: "String", params: [], sub: "" }, pos_full: { min: 0, max: 0, file: "InterpTest.hx" }, pos_path: { min: 0, max: 0, file: "InterpTest.hx" } }),
						value: mk(EConst(CString("default", SSingleQuotes))),
					}
				],
				expr: mk(EBlock([
					mk(ECall(mk(EConst(CIdent("trace"))), [
						mk(EBinop(BOpAdd, mk(EConst(CString("Hello World", SSingleQuotes))), mk(EConst(CIdent("awesome")))))
					]))
				]))}
		)));
		block.push(mk(ECall(mk(EConst(CIdent("test"))), [mk(EConst(CString(" Cool arguement", SSingleQuotes)))])));
		block.push(mk(ECall(mk(EConst(CIdent("test"))), [mk(EConst(CString(" Cool arguement 2", SSingleQuotes)))])));
		mk(EBlock(block));
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

		// Sys.println(Util.getTitle("CALL TEST"));
		// run(HELLO_WORLD_EXPR);

		// Sys.println(Util.getTitle("WHILE LOOP TEST"));
		// run(WHILE_LOOP_EXPR);

		// Sys.println(Util.getTitle("FIBBONACCI TEST"));
		// run(FIBBONACCI_FUNCTION_RECURSIVE);

		// Sys.println(Util.getTitle("FUNCTION RECURSIVE"));
		// run(FUNCTION_RECURSIVE);

		Sys.println(Util.getTitle("IF_STATEMENT"));
		run(IF_STATEMENT);

		// Sys.println(Util.getTitle("FUNCTION TEST"));
		// run(TEST_FUNCTION);
	}

	public static function run( e : Expr ) {
		Sys.println(Util.getTitle("EXPR PRINTED:") + "\n" + Printer.printExpr(e));

		var interp = new Interp();
		interp.run(e);
	}
}
