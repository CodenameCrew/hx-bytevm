package;

import hxbytevm.vm.Program;
import hxbytevm.vm.HVM;

class VMTest {
	public static var PROGRAM_ADD:Program = new Program(
		[PUSHC, PUSHC, ADD, RET],
		[0, 1],
		[2, 5],
		[[]],
		[[]],
		[[]],
		[]
	);

	public static var PROGRAM_NEG:Program = new Program(
		[PUSHC, NEG, RET],
		[0],
		[2],
		[[]],
		[[]],
		[[]],
		[]
	);

	public static var PROGRAM_IF_ELSE:Program = new Program(
		[PUSHC, PUSHC, EQ, NOT, JUMP_COND, PUSH, JUMP, PUSH, RET],
		[0, 1, 8, 6, "YEAH :D", 9, 7, "NAH :("],
		[2, 8],
		[[]],
		[[]],
		[[]],
		[]
	);

	public static var PROGRAM_CALL:Program = new Program(
		[PUSH, PUSHC, PUSH_TRUE, ARRAY_STACK, CALL],
		[function_test, 0, 2],
		[2],
		[[]],
		[[]],
		[[]],
		[]
	);

	public static var PROGRAM_DO_WHILE:Program = new Program(
		[PUSHC, SAVE, PUSH, PUSHC, PUSHV, ADD, CALL, POP, PUSHV, INC, SAVE, PUSHV, PUSHC, LT, JUMP_COND],
		[0, 0, Sys.println, 2, 0, 1, 0, 0, 0, 1, 3, 1],
		[0, 10, "DO WHILE LOOP (i):  "],
		[["i"]],
		[[]],
		[[]],
		[]
	);

	public static var PROGRAM_TEST_FUNCTION:Program = new Program(
		[DEPTH_INC, LOCAL_CALL, DEPTH_DNC, DEPTH_INC, LOCAL_CALL, DEPTH_DNC],
		[0, 0],
		[2],
		[["just here for not crashing lmao -lunar"], ["just here for not crashing lmao -lunar"]],
		[[PUSH, PUSHC, PUSH_TRUE, ARRAY_STACK, CALL]],
		[[function_test, 0, 2]],
		["test_call"]
	);

	public static var PROGRAM_TEST_FUNCTION_ARGS:Program = new Program(
		[PUSHC, PUSH_TRUE, DEPTH_INC, LOCAL_CALL, DEPTH_DNC, PUSHC, PUSH_FALSE, DEPTH_INC, LOCAL_CALL, DEPTH_DNC],
		[0, 0, 1, 0],
		[2, 10],
		[["test_call"], ["int", "bool"]],
		[[SAVE, SAVE, PUSH, PUSHV, PUSHV, ARRAY_STACK, CALL, POP]],
		[[1, 0, function_test, 0, 1, 2]],
		["test_call"]
	);

	public static function main() {
		Sys.println(Util.getTitle("HVM TESTING"));
		var hvm:HVM = new HVM();

		// Sys.println(Util.getTitle("PROGRAM ADD"));
		// trace(hvm.run(PROGRAM_ADD));

		// Sys.println(Util.getTitle("PROGRAM NEG"));
		// trace(hvm.run(PROGRAM_NEG));

		// Sys.println(Util.getTitle('PROGRAM IF ELSE (${PROGRAM_IF_ELSE.constant_stack[0]} == ${PROGRAM_IF_ELSE.constant_stack[1]})'));
		// trace(hvm.run(PROGRAM_IF_ELSE));

		// PROGRAM_IF_ELSE.constant_stack = [10, 10];
		// Sys.println(Util.getTitle('PROGRAM IF ELSE (${PROGRAM_IF_ELSE.constant_stack[0]} == ${PROGRAM_IF_ELSE.constant_stack[1]})'));
		// trace(hvm.run(PROGRAM_IF_ELSE));

		// Sys.println(Util.getTitle("PROGRAM CALL"));
		// hvm.run(PROGRAM_CALL);

		// Sys.println("\n");

		// Sys.println(Util.getTitle("PROGRAM DO WHILE"));
		// hvm.run(PROGRAM_DO_WHILE);

		// Sys.println(PROGRAM_DO_WHILE.print());

		//Sys.println(Util.getTitle("PROGRAM FUNCTION"));

		// Sys.println(Util.getTitle("TEST FUNCTION (NO ARGS)"));

		// hvm.run(PROGRAM_TEST_FUNCTION);
		// Sys.println(PROGRAM_TEST_FUNCTION.print());

		Sys.println(Util.getTitle("TEST FUNCTION (2 ARGS)"));

		hvm.run(PROGRAM_TEST_FUNCTION_ARGS);
		Sys.println(PROGRAM_TEST_FUNCTION_ARGS.print());
	}

	public static function function_test(arg1:Int, arg2:Bool) {
		trace("CALL" , arg1, arg2);
	}
}
