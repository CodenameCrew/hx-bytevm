package;

import hxbytevm.core.Ast.Unop;
import hxbytevm.vm.HVM;
import hxbytevm.core.Ast.Expr;
import hxbytevm.core.Ast.Binop;
import hxbytevm.interp.Interp;

class Main {
	public static var PROGRAM_ADD:Program = {
		intructions: [PUSHC, PUSHC, ADD, RET],
		storages: [0, 1],
		constants: [2, 5],
		varnames: []
	};

	public static var PROGRAM_NEG:Program = {
		intructions: [PUSHC, NEG, RET],
		storages: [0],
		constants: [2],
		varnames: []
	};

	public static var PROGRAM_IF:Program = {
		intructions: [PUSHC, PUSHC, EQ, RET],
		storages: [0, 1],
		constants: [2, 8],
		varnames: []
	};

	public static var PROGRAM_CALL:Program = {
		intructions: [PUSH, PUSHC, PUSH_TRUE, ARRAY_STACK, CALL, PUSH, RET],
		storages: [function_test, 0, 2, "FINISHED INTRUCTIONS"],
		constants: [2],
		varnames: []
	};

	public static function main() {
		var hvm:HVM = new HVM();

		trace(hvm.run(PROGRAM_ADD));
		trace(hvm.run(PROGRAM_NEG));
		trace(hvm.run(PROGRAM_IF));
		trace(hvm.run(PROGRAM_CALL));
	}

	public static function function_test(arg1:Int, arg2:Bool) {
		trace("CALL" , arg1, arg2);
	}
}
