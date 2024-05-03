package hxbytevm.vm;

import hxbytevm.core.Ast.Func;
import hxbytevm.core.Ast.FunctionKind;
import hxbytevm.utils.UnsafeReflect;

typedef Program = {
	var intructions:Array<OpCode>;
	var read_only_stack:Array<Dynamic>;
	var constant_stack:Array<Dynamic>;
	var varnames_stack:Array<String>;
}

class HVM {
	var stack:Stack = new Stack();
	var depth:Int = 0;

	var intructions:Array<OpCode>;
	var rom:Array<Dynamic>;

	// pointers
	var ip:Int = 0;
	var sp:Int = 0;

	// TODO: Handle scope, variablenames for each scope
	@:noCompletion public var _varnames:Array<String> = [];
	@:noCompletion public var _variables:Array<Dynamic> = [];

	@:noCompletion public var constants:Array<Dynamic> = [];

	public var variables:VarAccess;

	public function new() {}

	public function reset() {
		ip = 0; sp = 0;
		stack = new Stack();
		depth = 0;

		_varnames = [];
		_variables = [];
		constants = [];

		intructions = [];
		rom = [];

		ret = null;
	}

	public function run(program:Program):Dynamic {
		reset();

		intructions = program.intructions;
		rom = program.read_only_stack;
		constants = program.constant_stack;

		_varnames = program.varnames_stack;
		_variables = cast new haxe.ds.Vector<Dynamic>(_varnames.length);

		while (ip <= intructions.length-1) {
			instruction(intructions[ip]);
			ip++;

			// trace(intructions[ip-1], ip-1, sp-1, stack.stack, _variables);
		}

		return ret;
	}

	public inline function get_rom():Dynamic {
		var ret = rom[sp];
		sp++; return ret;
	}

	var ret:Dynamic = null;
	public function instruction(instruction:OpCode):Dynamic {
		switch (intructions[ip]) {
			case PUSH:
				stack.push(get_rom());
			case PUSHV: stack.push(_variables[get_rom()]);
			case PUSHC: stack.push(constants[get_rom()]);
			case POP: stack.pop();
			case SAVE: _variables[get_rom()] = stack.pop();
			case RET: ret = stack.pop();
			case DEPTH_INC: depth++;
			case DEPTH_DNC: depth--;
			case JUMP:
				var s = get_rom();
				var i = get_rom();
				sp = s; ip = i;
			case JUMP_COND:
				if (stack.pop() == true) {
					var s = get_rom();
					var i = get_rom();
					sp = s; ip = i;
				}
			case FUNC: // TODO: IMPLEMENT FUNCTIONS
				var kind:FunctionKind = cast get_rom();
				var func:Func = cast get_rom();
			case CALL:
				var args = stack.pop();
				var func = stack.pop();

				if(func == null) throw "Cannot call null";
				if(!UnsafeReflect.isFunction(func))
					throw "Cannot call non function";
				stack.push(UnsafeReflect.callMethodUnsafe(null, func, args));

			case FIELD: stack.push(UnsafeReflect.field(stack.pop(), get_rom()));
			case NEW: stack.push(Type.createInstance(_variables[get_rom()], stack.pop()));
			case PUSH_ARRAY: stack.push([]);
			case PUSH_TRUE: stack.push(true);
			case PUSH_FALSE: stack.push(false);
			case PUSH_NULL: stack.push(null);
			case ARRAY_GET:
				var array_i = get_rom();
				var array_s = get_rom();
				stack.push(stack.stack[array_s][array_i]);
			case ARRAY_SET:
				var array_i = get_rom();
				var array_s = get_rom();
				stack.stack[array_s][array_i] = stack.pop();
			case ARRAY_STACK:
				var array = [for (i in 0...get_rom()) stack.pop()];
				array.reverse();
				stack.push(array);
			case ADD:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1+v2);
			case MULT:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1*v2);
			case DIV:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1/v2);
			case SUB:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1-v2);
			case EQ:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1==v2);
			case NEQ:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1!=v2);
			case GT:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1>v2);
			case GTE:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1>=v2);
			case LT:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1<v2);
			case LTE:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1<=v2);
			case AND:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1&v2);
			case OR:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1|v2);
			case XOR:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1^v2);
			case BAND:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1&&v2);
			case BOR:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1||v2);
			case SHL:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1<<v2);
			case SHR:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1>>v2);
			case USHR:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1>>>v2);
			case MOD:
				var v2 = stack.pop();
				var v1 = stack.pop();
				stack.push(v1%v2);
			case INC:
				var v = stack.pop(); v++;
				stack.push(v);
			case DNC:
				var v = stack.pop(); v--;
				stack.push(v);
			case NOT: stack.push(!stack.pop());
			case NEG: stack.push(-stack.pop());
			case NGBITS: stack.push(~stack.pop());
		}
		return null;
	}
}
