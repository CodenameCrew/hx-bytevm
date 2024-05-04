package;

import hxbytevm.vm.Program;
import hxbytevm.vm.HVM;

class VMTest {
	public static var PROGRAM_ADD:Program = new Program(
		[PUSHC, PUSHC, ADD, RET],
		[0, 1],
		[2, 5],
		[[]],
		[]
	);

	public static var PROGRAM_NEG:Program = new Program(
		[PUSHC, NEG, RET],
		[0],
		[2],
		[[]],
		[]
	);

	public static var PROGRAM_IF_ELSE:Program = new Program(
		[PUSHC, PUSHC, EQ, NOT, JUMP_COND, PUSH, JUMP, PUSH, RET],
		[0, 1, 7, 6, "YEAH :D", 8, 7, "NAH :("],
		[2, 8],
		[[]],
		[]
	);

	public static var PROGRAM_CALL:Program = new Program(
		[PUSH, PUSHC, PUSH_TRUE, CALL],
		[function_test, 0, 2],
		[2],
		[[]],
		[]
	);

	public static var PROGRAM_DO_WHILE:Program = new Program(
		[PUSHC, SAVE, PUSH, PUSHC, PUSHV, ADD, CALL, POP, PUSHV, INC, SAVE, PUSHV, PUSHC, LT, JUMP_COND],
		[0, 0, Sys.println, 2, 0, 1, 0, 0, 0, 1, 2, 1],
		[0, 10, "DO WHILE LOOP (i):  "],
		[["i"]],
		[]
	);

	public static function main() {
		Sys.println(Util.getTitle("HVM TESTING"));
		var hvm:HVM = new HVM();

		Sys.println(Util.getTitle("PROGRAM ADD"));
		trace(hvm.run(PROGRAM_ADD));

		Sys.println(Util.getTitle("PROGRAM NEG"));
		trace(hvm.run(PROGRAM_NEG));

		Sys.println(Util.getTitle('PROGRAM IF ELSE (${PROGRAM_IF_ELSE.constant_stack[0]} == ${PROGRAM_IF_ELSE.constant_stack[1]})'));
		trace(hvm.run(PROGRAM_IF_ELSE));

		PROGRAM_IF_ELSE.constant_stack = [10, 10];
		Sys.println(Util.getTitle('PROGRAM IF ELSE (${PROGRAM_IF_ELSE.constant_stack[0]} == ${PROGRAM_IF_ELSE.constant_stack[1]})'));
		trace(hvm.run(PROGRAM_IF_ELSE));

		Sys.println(Util.getTitle("PROGRAM CALL"));
		hvm.run(PROGRAM_CALL);

		Sys.println("\n");

		Sys.println(Util.getTitle("PROGRAM DO WHILE"));
		hvm.run(PROGRAM_DO_WHILE);

		Sys.println(PROGRAM_DO_WHILE.print());
	}

	public static function function_test(arg1:Int, arg2:Bool) {
		trace("CALL" , arg1, arg2);
	}
}
