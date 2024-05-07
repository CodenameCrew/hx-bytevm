package hxbytevm.vm;

import hxbytevm.compiler.Compiler.Pointer;
import hxbytevm.core.Ast.Func;
import hxbytevm.core.Ast.FunctionKind;
import hxbytevm.utils.UnsafeReflect;

class HVM {
	var stack:Stack = new Stack();
	var depth:Int = 0;

	var program:Program;

	var instructions:Array<OpCode>;
	var rom:Array<Dynamic>;

	// pointers
	var ip:Int;
	var rp:Int;

	@:noCompletion public var _varnames:Array<Array<String>> = [[]];
	@:noCompletion public var _variables:Array<Array<Dynamic>> = [[]];

	@:noCompletion public var constants:Array<Dynamic> = [];

	public var variables:VarAccess;

	public function new() {
		variables = new VarAccess(this);
	}

	public function reset() {
		ip = 0; rp = 0;
		stack = new Stack();
		depth = 0; program = null;

		_varnames = [[]];
		_variables = [[]];
		constants = [];

		instructions = [];
		rom = [];

		ret = null;

		func_pointers = []; func_ids = [];
		func_id = -1; fip = 0; frp = 0;
	}

	public function load(program:Program) {
		reset();

		this.program = program;

		instructions = program.instructions;
		rom = program.read_only_stack;
		constants = program.constant_stack;

		_varnames = program.varnames_stack;
		_variables = [for (scopenames in _varnames) cast new haxe.ds.Vector<Dynamic>(scopenames.length)];

		variables.set("trace", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
			var inf:haxe.PosInfos = @:fixed {
				fileName: "",
				lineNumber: 0,
				methodName: "", // TODO: get function name of function which called it,
				className: "", // Use class name, if not available, use filename
				customParams: []
			}
			var v = args.shift();
			if (args.length > 0)
				inf.customParams = args;
			haxe.Log.trace(Std.string(v), inf);
		}));
		variables.loadDefaults();
	}

	public function run(?program:Program):Dynamic {
		if (program != null) load(program);

		while (ip <= instructions.length-1) {
			instruction(instructions[ip]);
			ip++;
		}

		return ret;
	}

	public inline function get_rom():Dynamic {
		if (func_id != -1) {
			var ret = func_rom[frp];
			frp++; return ret;
		}
		var ret = rom[rp];
		rp++; return ret;
	}

	public inline function _jump(nip:Int, nrp:Int) {
		if (func_id != -1) {
			fip = nip; frp = nrp;
		} else {
			ip = nip; rp = nrp;
		}
	}

	var ret:Dynamic = null;
	public function instruction(instruction:OpCode):Dynamic {
		switch (instruction) {
			case PUSH:
				stack.push(get_rom());
			case PUSHV: stack.push(_variables[depth][get_rom()]); // ! Unused in compiler.hx
			case PUSHV_D:
				var d = get_rom();
				var v_id = get_rom();

				stack.push(_variables[d][v_id]);
			case PUSHC: stack.push(constants[get_rom()]);
			case POP: stack.pop();
			case SAVE:
				_variables[depth][get_rom()] = stack.pop();
			case SAVE_D:
				var v_id = get_rom();
				var d = get_rom();
				_variables[d][v_id] = stack.pop();
			case RET: ret = stack.pop();
			case DEPTH_INC: depth++;
			case DEPTH_DNC:
				depth--;
			case JUMP:
				var r = get_rom();
				var i = get_rom();
				_jump(i-1, r);
			case JUMP_COND:
				var r = get_rom();
				var i = get_rom();
				if (stack.pop() == true)
					_jump(i-1, r);
			case JUMP_N_COND:
				var r = get_rom();
				var i = get_rom();
				if (stack.pop() == false)
					_jump(i-1, r);
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

			case FIELD_GET: stack.push(UnsafeReflect.field(stack.pop(), get_rom()));
			case FIELD_SET:
				var val = stack.pop();
				var obj = stack.pop();
				UnsafeReflect.setField(obj, get_rom(), val); // TODO: DEBUG MODE, to prevent crash from obj being null
			case NEW:
				var args = stack.pop();
				var cls = stack.pop();
				stack.push(Type.createInstance(cls, args));
			case PUSH_ARRAY: stack.push([]);
			case PUSH_TRUE: stack.push(true);
			case PUSH_FALSE: stack.push(false);
			case PUSH_NULL: stack.push(null);
			case PUSH_OBJECT: stack.push({});
			case ARRAY_GET:
				var array_i = get_rom();
				var array_r = get_rom();
				stack.push(stack.stack[array_r][array_i]);
			case ARRAY_SET:
				var array_i = get_rom();
				var array_r = get_rom();
				stack.stack[array_r][array_i] = stack.pop();
			case ARRAY_STACK:
				var length = get_rom();
				var array = new haxe.ds.Vector<Dynamic>(length);
				for (i in 0...length) array[length-i-1] = stack.pop();
				stack.push(array);
			case ADD:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1+v2);
			case MULT:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1*v2);
			case DIV:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1/v2);
			case SUB:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1-v2);
			case EQ:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1==v2);
			case NEQ:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1!=v2);
			case GT:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1>v2);
			case GTE:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1>=v2);
			case LT:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1<v2);
			case LTE:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1<=v2);
			case AND:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1&v2);
			case OR:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1|v2);
			case XOR:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1^v2);
			case BAND:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1&&v2);
			case BOR:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1||v2);
			case IS:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(Std.isOfType(v1, v2));
			case SHL:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1<<v2);
			case SHR:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1>>v2);
			case USHR:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1>>>v2);
			case MOD:
				var v2:Dynamic = stack.pop();
				var v1:Dynamic = stack.pop();
				stack.push(v1%v2);
			case INC:
				var v:Dynamic = stack.pop();
				stack.push(v+1);
			case DNC:
				var v:Dynamic = stack.pop();
				stack.push(v-1);
			case NOT: stack.push(!stack.pop());
			case NEG: stack.push(-stack.pop());
			case NGBITS: stack.push(~stack.pop());
			case DUP:
				var stacktop = stack.top();
				stack.push(stacktop);
			case STK_OFF:
				var stacktop = stack.top(get_rom());
				stack.push(stacktop);
			case LOCAL_CALL: local_call(get_rom());
		}
		return null;
	}

	var func_instructions:Array<OpCode>;
	var func_rom:Array<Dynamic>;

	var func_pointers:Array<Pointer>;
	var func_ids:Array<Int>;

	var func_id:Int;

	var fip:Int;
	var frp:Int;

	public function local_call(func:Int) {
		inline function end_call() {
			var pointer = func_pointers.pop();
			var old_func = func_ids.pop();

			if (func_pointers.length <= 0)
				// return to regular run() function
				func_id = -1;
			else {
				// return to last func
				func_id = old_func;
				__updateFuncStacks();

				fip = pointer.ip;
				frp = pointer.rp;
			}
		}

		// backup last func point
		if (func_id != -1) {
			func_ids.push(func_id);
			func_pointers.push(new Pointer(fip, frp));
		}

		// reset func
		fip = 0; frp = 0;
		func_id = func;

		// do instructions
		__updateFuncStacks();
		while (fip <= func_instructions.length-1) {
			switch (func_instructions[fip]) {
				case RET: end_call(); return;
				default: instruction(func_instructions[fip]); fip++;
			}
		}

		end_call();
	}

	public inline function __updateFuncStacks() {
		func_instructions = program.program_funcs[func_id].instructions;
		func_rom = program.program_funcs[func_id].read_only_stack;
	}
}
