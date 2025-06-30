package hxbytevm.vm;

import hxbytevm.utils.UnsafeReflect;
import hxbytevm.vm.ByteCode;
import haxe.io.Bytes;
import haxe.io.BytesInput;

typedef Data = Dynamic;
typedef Memory = Array<Data>;

class HVMState {
	public var stack:Stack;
	public var reader:BytesInput;

	public function new(bytes:Bytes) {
		reader = new BytesInput(bytes);
		stack = new Stack();
	}

	public function clone(state:HVMState) {}
}

/**
 * Stores the program, the state, and the memory.
 */
class HVM {
	/**
	 * The program to execute.
	 */
	public var bytes:Bytes;
	public var state:HVMState;
	public var stack:Stack;

	private var reader:BytesInput;
	private var memory:Memory;

	public function new(?bytes:Bytes = null) {
		if (bytes != null) load(bytes);
	}

	public function reset() {
		this.bytes = null;
		this.reader = null;
		this.memory = null;
		this.state = null;
		this.stack = null;
	}

	public function load(bytes:Bytes) {
		state = new HVMState(this.bytes = bytes);
		this.reader = state.reader;
		this.stack = state.stack;
		memory = new Memory();
	}

	public function execute() {
		// TODO: STORE STATE OF THREAD
		while (reader.position < bytes.length) {
			execute_instruction();
			// trace(sys.thread.Thread.current());
		};
	}

	public function execute_instruction():Void {
		var opcode:ByteCode = reader.readByte();
		switch (opcode) {
			case ByteCode.PUSH_INT8:
				stack.push(reader.readInt8());
			case ByteCode.PUSH_INT16:
				stack.push(reader.readInt16());
			case ByteCode.PUSH_INT32:
				stack.push(reader.readInt32());
			case ByteCode.PUSH_FLOAT:
				stack.push(reader.readDouble());
			case ByteCode.PUSH_STRING8:
				var len = reader.readInt8();
				stack.push(reader.readString(len));
			case ByteCode.PUSH_STRING16:
				var len = reader.readInt16();
				stack.push(reader.readString(len));
			case ByteCode.PUSH_STRING32:
				var len = reader.readInt32();
				stack.push(reader.readString(len));

			case ByteCode.PUSH_NULL:
				stack.push(null);
			case ByteCode.PUSH_TRUE:
				stack.push(true);
			case ByteCode.PUSH_FALSE:
				stack.push(false);
			case ByteCode.PUSH_OBJECT:
				stack.push({});
			case ByteCode.PUSH_ZERO:
				stack.push(0);
			case ByteCode.PUSH_POSITIVE_ONE:
				stack.push(1);
			case ByteCode.PUSH_NEGATIVE_ONE:
				stack.push(-1);
			case ByteCode.PUSH_POSITIVE_INFINITY:
				stack.push(Math.POSITIVE_INFINITY);
			case ByteCode.PUSH_PI:
				stack.push(Math.PI);

				/*
			case ByteCode.PUSH_FUNCTION:
				var index = reader.readInt32();
				var func = function(args:Array<Dynamic>) {
					// ! PSEUDOCODE
					var old = reader.position;
					reader.position = index;
					stack.push(args);
					execute_instruction();
					reader.position = old;
					return return_value;
				}
				stack.push(Reflect.makeVarArgs(func));
				*/
			case ByteCode.BINOP_ADD:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a + b);
			case ByteCode.BINOP_SUB:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a - b);
			case ByteCode.BINOP_MULT:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a * b);
			case ByteCode.BINOP_DIV:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a / b);
			case ByteCode.BINOP_MOD:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a % b);
			case ByteCode.BINOP_AND:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a & b);
			case ByteCode.BINOP_OR:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a || b);
			case ByteCode.BINOP_XOR:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a ^ b);
			case ByteCode.BINOP_SHL:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a << b);
			case ByteCode.BINOP_SHR:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a >> b);
			case ByteCode.BINOP_USHR:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a >>> b);
			case ByteCode.BINOP_EQ:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a == b);
			case ByteCode.BINOP_NEQ:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a != b);
			case ByteCode.BINOP_GTE:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a >= b);
			case ByteCode.BINOP_LTE:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a <= b);
			case ByteCode.BINOP_GT:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a > b);
			case ByteCode.BINOP_LT:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a < b);
			case ByteCode.BINOP_BOR:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a | b);
			case ByteCode.BINOP_BAND:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(a && b);
			case ByteCode.BINOP_IS:
				var b = stack.pop();
				var a = stack.pop();
				stack.push(Std.isOfType(a, b));

			case ByteCode.UNOP_NEG:
				stack.setTop(-stack.getTop());
			case ByteCode.UNOP_NOT:
				stack.setTop(!stack.getTop());
			case ByteCode.UNOP_BNOT:
				stack.setTop(~stack.getTop());
			case ByteCode.UNOP_INC:
				stack.setTop(stack.getTop() + 1);
			case ByteCode.UNOP_DEC:
				stack.setTop(stack.getTop() - 1);

			case ByteCode.PUSH_MEMORY8:
				var index:Int = reader.readInt8();
				stack.push(memory[index]);
			case ByteCode.PUSH_MEMORY16:
				var index:Int = reader.readInt16();
				stack.push(memory[index]);
			case ByteCode.PUSH_MEMORY24:
				var index:Int = reader.readInt24();
				stack.push(memory[index]);

			case ByteCode.SAVE_MEMORY8:
				var index:Int = reader.readInt8();
				memory[index] = stack.pop();
			case ByteCode.SAVE_MEMORY16:
				var index:Int = reader.readInt16();
				memory[index] = stack.pop();
			case ByteCode.SAVE_MEMORY24:
				var index:Int = reader.readInt24();
				memory[index] = stack.pop();

			case ByteCode.GOTO8:
				var pos = reader.readInt8();
				reader.position = pos;
			case ByteCode.GOTO16:
				var pos = reader.readInt16();
				reader.position = pos;
			case ByteCode.GOTO32:
				var pos = reader.readInt32();
				reader.position = pos;

			case ByteCode.CALL:
				var args = stack.pop();
				var func = stack.pop();
				if(!Reflect.isFunction(func))
					throw "Cannot call non function";

				var ret = UnsafeReflect.callMethod(null, func, args);
				stack.push(ret);

			case ByteCode.CALL_NOARG:
				var func = stack.pop();
				if(!Reflect.isFunction(func))
					throw "Cannot call non function";

				var ret = UnsafeReflect.callMethod(null, func, []);
				stack.push(ret);

			case ByteCode.FIELD_GET:
				var field = stack.pop(); // String
				var obj = stack.pop(); // Object
				stack.push(Reflect.field(obj, field));

			case ByteCode.FIELD_SET:
				var field = stack.pop(); // String
				var obj = stack.pop(); // Object
				var value = stack.pop(); // Dynamic
				Reflect.setField(obj, field, value);

			case ByteCode.NEW:
				var args = stack.pop();
				var cls = stack.pop();
				stack.push(Type.createInstance(cls, args));

			case ByteCode.ARRAY_GET:
				var index = stack.pop();
				var array = stack.pop();
				stack.push(array[index]);
			case ByteCode.ARRAY_SET:
				var index = stack.pop();
				var array = stack.pop();
				var value = stack.pop();
				array[index] = value;

			// case ByteCode.RETURN:
				// TODO: check how lua does this
				// return_value = stack.pop();
				// reader.position = callStack.pop();

			default:
				throw "Unknown opcode: " + opcode;
		}
	}
}
