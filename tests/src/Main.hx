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
		var hvm:HVM = new HVM();

		trace(hvm.run(program_add));
		trace(hvm.run(program_neg));
		trace(hvm.run(program_if));
	}
}
