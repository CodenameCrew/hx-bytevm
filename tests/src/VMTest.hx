package;

import hxbytevm.vm.HVM;

class VMTest {
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
		intructions: [PUSH, PUSHC, PUSH_TRUE, ARRAY_STACK, CALL],
		read_only_stack: [function_test, 0, 2],
		constant_stack: [2],
		varnames_stack: []
	};

	public static var PROGRAM_WHILE:Program = {
		intructions: [PUSHC, SAVE, PUSH, PUSHC, PUSHV, ADD, ARRAY_STACK, CALL, POP, PUSHV, INC, SAVE, PUSHV, PUSHC, LT, JUMP_COND],
		read_only_stack: [0, 0, Sys.println, 2, 0, 1, 0, 0, 0, 1, 2, 1],
		constant_stack: [0, 10, "DO WHILE LOOP (i):  "],
		varnames_stack: ["i"]
	};

	public static function main() {
		Sys.println(Util.getTitle("HVM TESTING"));
		var hvm:HVM = new HVM();

		Sys.println(Util.getTitle("PROGRAM ADD"));
		trace(hvm.run(PROGRAM_ADD));
		Sys.println(Util.getTitle("PROGRAM NEG"));
		trace(hvm.run(PROGRAM_NEG));
		Sys.println(Util.getTitle("PROGRAM IF"));
		trace(hvm.run(PROGRAM_IF));
		Sys.println(Util.getTitle("PROGRAM CALL"));
		hvm.run(PROGRAM_CALL);
		Sys.println(Util.getTitle("PROGRAM WHILE"));
		hvm.run(PROGRAM_WHILE);
	}

	public static function function_test(arg1:Int, arg2:Bool) {
		trace("CALL" , arg1, arg2);
	}
}
