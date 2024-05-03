package hxbytevm.vm;

import hxbytevm.core.Ast.Unop;
import hxbytevm.core.Ast.Binop;
import hxbytevm.core.Ast.WhileFlag;
import hxbytevm.core.Ast.Func;
import hxbytevm.core.Ast.FunctionKind;
import hxbytevm.utils.UnsafeReflect;

enum abstract OpCode(Int) {
	var PUSH:OpCode = 0; // 1 STORAGE SPACE: Pushes storage1 to stack
	var POP:OpCode = 1; // 0 STORAGE SPACE: Pops stack

	var SAVE:OpCode = 2; // 1 STORAGE SPACE: Pushes stack[stacktop] to variables[storage1], removing it from the stack
	var RET:OpCode = 3; // 0 STORAGE SPACE: Returns stack[stacktop], removing it from the stack

	var JUMP:OpCode = 4; // 2 STORAGE SPACE: Moves instruction pointer to storage1, Moves storage pointer to storage2

	var FUNC:OpCode = 5; // 2 STORAGE SPACE: Defines a function, storage1 being FunctionKind and storage2 being Func (refer to ExprDef in core/Ast.hx), expects a OBlock directly after
	var WHILE:OpCode = 6; // 1 STORAGE SPACE: Defines a while loop, stack[stacktop] being the stack postion of condition of the while, storage2 being the while flag (refer to WhileFlag in core/Ast.hx), expects a OBlock directly after

	var CALL:OpCode = 7; // 0 STORAGE SPACE: Calls stack[stacktop-1] (a function), with a array of args from stack[stacktop], return is pushed to stacktop
	var FIELD:OpCode = 8; // 1 STORAGE SPACE: Gets field storage2 (a string) from stack[stacktop], pushing to stack
	var ARRAYACCESS:OpCode = 9; // 1 STORAGE SPACE: Gets index storage1 from stack[stacktop], pushing to stack

	var NEW:OpCode = 10; // 2 STORAGE SPACE: Creates a instance from variables[storage1] being a class with args from stack[stacktop], removing storage2 from stack and pushing the new instance to stack

	var BINOP:OpCode = 11; // 1 STORAGE SPACE: Prefroms storage1 being Binop (refer to Binop in core/Ast.hx, BINOPASSIGN WILL NOT WORK!!) on last 2 in stack, popping them and pushing the result to stack
	var UNOP:OpCode = 12; // 1 STORAGE SPACE: Preformas storage1 being Unop (refer to Unop in core/Ast.hx, BINOPASSIGN WILL NOT WORK!!) on stack[stacktop], popping it and pushing the result
}

typedef Program = {
	var intructions:Array<OpCode>;
	var storages:Array<Dynamic>;
}

class HVM {
	var stack:Stack = new Stack();
	var depth:Int = 0;

	var intructions:Array<OpCode>;
	var storages:Array<Dynamic>;

	// pointers
	var ip:Int = 0;
	var sp:Int = 0;

	var _varnames:Array<String> = [];
	var _variables:Array<Dynamic> = [];

	public var variables:Variables;

	public function new() {}

	public function reset() {
		ip = 0; sp = 0;
		stack = new Stack();
		depth = 0;

		_varnames = [];
		_variables = [];

		intructions = [];
		storages = [];
	}

	public function run(program:Program):Dynamic {
		reset();

		intructions = program.intructions;
		storages = program.storages;

		while (ip <= intructions.length-1) {
			instruction(intructions[ip]);
			ip++;
		}

		return ret;
	}

	public inline function storage():Dynamic {
		var ret = storages[sp];
		sp++; return ret;
	}

	var ret:Dynamic = null;
	public function instruction(instruction:OpCode):Dynamic {
		switch (intructions[ip]) {
			case PUSH: stack.push(storage());
			case POP: stack.pop();
			case SAVE: _variables[storage()] = stack.pop();
			case RET: ret = stack.pop();
			case JUMP: sp = storage(); ip = storage();
			case FUNC: // TODO: IMPLEMENT FUNCTIONS
				var kind:FunctionKind = cast storage();
				var func:Func = cast storage();

			case WHILE: // TODO: IMPLEMENT WHILE LOOPS
				var flag:WhileFlag = storage();
				var condition:Bool = stack.pop();

			case CALL:
				var args = storage();
				var func = storage();

				if(func == null) throw "Cannot call null";
				if(!UnsafeReflect.isFunction(func))
					throw "Cannot call non function";
				stack.push(UnsafeReflect.callMethodSafe(null, func, args));
			case FIELD: stack.push(UnsafeReflect.field(stack.pop(), storage()));
			case ARRAYACCESS: stack.push(stack.top()[storage()]);
			case NEW: stack.push(Type.createInstance(_variables[storage()], stack.pop()));
			case BINOP:
				var v2 = stack.pop();
				var v1 = stack.pop();

				var binop:Binop = cast storage();
				switch (binop) {
					case BOpAdd: stack.push(v1 + v2);
					case BOpEq: stack.push(v1 == v2);
					default: throw "Unknown Binop";
				}
			case UNOP:
				var v = stack.pop();

				var unop:Unop = cast storage();
				switch (unop) {
					case UNeg: stack.push(-v);
					default: throw "Unknown Unop";
				}
		}
		return null;
	}
}

class Variables {} // TODO: BACKWARDS COMPAT
