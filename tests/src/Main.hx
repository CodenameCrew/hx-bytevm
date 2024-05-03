package;

import hxbytevm.core.Ast.Unop;
import hxbytevm.vm.HVM;
import hxbytevm.core.Ast.Expr;
import hxbytevm.core.Ast.Binop;
import hxbytevm.interp.Interp;

class Main {
	public static var PROGRAM_ADD:Program = {
		intructions: [PUSHC, PUSHC, ADD, RET],
		read_only_stack: [0, 1],
		constant_stack: [2, 5],
		varnames_stack: []
	};

	public static var PROGRAM_NEG:Program = {
		intructions: [PUSHC, NEG, RET],
		read_only_stack: [0],
		constant_stack: [2],
		varnames_stack: []
	};

	public static var PROGRAM_IF:Program = {
		intructions: [PUSHC, PUSHC, EQ, RET],
		read_only_stack: [0, 1],
		constant_stack: [2, 8],
		varnames_stack: []
	};

	public static var PROGRAM_CALL:Program = {
		intructions: [PUSH, PUSHC, PUSH_TRUE, ARRAY_STACK, CALL, PUSH, RET],
		read_only_stack: [function_test, 0, 2, "FINISHED INTRUCTIONS"],
		constant_stack: [2],
		varnames_stack: []
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
