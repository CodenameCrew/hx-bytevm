package;

import hxbytevm.core.Ast.Unop;
import hxbytevm.vm.HVM;
import hxbytevm.core.Ast.Expr;
import hxbytevm.core.Ast.Binop;
import hxbytevm.interp.Interp;

class Main {
	public static function main() {
		var program_add:Program = {
			intructions: [PUSH, PUSH, BINOP, RET],
			storages: [2, 5, BOpAdd]
		};
		var program_neg:Program = {
			intructions: [PUSH, UNOP, RET],
			storages: [2, UNeg]
		};
		var program_if:Program = {
			intructions: [PUSH, PUSH, BINOP, RET],
			storages: [2, 8, BOpEq]
		};
		var program_call:Program = {
			intructions: [PUSH, PUSH_ARRAY, PUSH, ARRAY_SET, PUSH_TRUE, ARRAY_SET, CALL, PUSH, RET],
			storages: [function_test, 2, 0, 1, 1, 1, "FINISHED INTRUCTIONS"]
		};
		var hvm:HVM = new HVM();

		trace(hvm.run(program_add));
		trace(hvm.run(program_neg));
		trace(hvm.run(program_if));
		trace(hvm.run(program_call));
	}

	public static function function_test(arg1:Int, arg2:Bool) {
		trace("CALL" , arg1, arg2);
	}
}
