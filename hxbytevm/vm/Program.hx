package hxbytevm.vm;

import hxbytevm.utils.FastStringBuf;
import hxbytevm.utils.FastUtils;
import hxbytevm.utils.StringUtils;

typedef StackValue = Dynamic;

typedef ProgramFunc = {
	var instructions:Array<OpCode>;
	var read_only_stack:Array<StackValue>;

	var args:Array<Variable>;
	var depth:Int;
}

enum Variable {
	Defined(v:Dynamic);
	UnDefined;
}

class Program {
	public var instructions:Array<OpCode>;
	public var read_only_stack:Array<StackValue>;
	public var constant_stack:Array<StackValue>;
	public var varnames_stack:Array<String>;

	public var program_funcs:Array<ProgramFunc>;
	public var func_names:Array<String>;

	public function new(instructions:Array<OpCode>, read_only_stack:Array<StackValue>, constant_stack:Array<StackValue>, varnames_stack:Array<String>, program_funcs:Array<ProgramFunc>, func_names:Array<String>) {
		this.instructions = instructions;
		this.read_only_stack = read_only_stack;
		this.constant_stack = constant_stack;
		this.varnames_stack = varnames_stack;
		this.program_funcs = program_funcs;
		this.func_names = func_names;
	}

	public function print() {
		trace(varnames_stack);
		if (func_names.length <= 0) return print_bytecode(instructions, read_only_stack);
		var function_prints:Array<String> = [
			for (i in 0...func_names.length)
				print_bytecode(program_funcs[i].instructions, program_funcs[i].read_only_stack, '\t')
		];

		var result:String = print_bytecode(instructions, read_only_stack, "", 8);
		result += '\n${StringUtils.getTitle('FUNCTIONS (${function_prints.length}):', headerLength+8)}\n';
		for (i => func_name in func_names) {
			result += '-   FUNCTION: $func_name ($i, D: ${program_funcs[i].depth}) BYTE CODE:';
			result += '\n${function_prints[i]}\n';
		}

		return result;
	}

	public var headerLength:Int = 0;
	public function print_bytecode(instructions:Array<OpCode>, read_only_memory:Array<StackValue>, ?lineprefix:String = "", ?extraHeading:Int = 0):String {
		var prints:Array<Array<String>> = [["IP"], ["RP"], ["D"], ["CODE"], ["ROM"]];
		var printsSizes:Array<Int> = [0, 0, 0, 0, 0];

		var dp:Int = 0;
		var rp:Int = 0;
		inline function get_rom():Dynamic {
			var ret = read_only_stack[rp];
			rp++; return ret;
		}

		for (i => ip in instructions) {
			prints[0].push('I: $i');
			prints[1].push('R: $rp');
			prints[2].push('D: $dp');
			prints[3].push(print_opcode(ip));

			switch (ip) {
				case DEPTH_INC: dp++;
				case DEPTH_DNC: dp--;
				default:
			}

			switch (ip) {
				case PUSH: prints[4].push('VAR:       ${get_rom()}');
				case PUSHV | SAVE:
					var v_id = get_rom();
					prints[4].push('VAR_ID:    $v_id  ("${varnames_stack[v_id]}")');
				case PUSHC:
					var c_id = get_rom();
					var const = constant_stack[c_id];
					var desc:String = '${const is String ? '"' : ''}$const${const is String ? '"' : ''}';
					prints[4].push('CONST_ID:  $c_id  ($desc)');
				case JUMP | JUMP_COND | JUMP_N_COND:
					var _ip = get_rom();
					var _rp = get_rom();
					prints[4].push('IP: ${_ip}, RP: ${_rp}');
				case FIELD_GET | FIELD_SET: prints[4].push('NAME:  ${get_rom()}');
				case ARRAY_GET | ARRAY_SET:
					var array_i = get_rom();
					var array_r = get_rom();
					prints[4].push('A_ID:  ${array_i}, I_ID:  ${array_r}');
				case ARRAY_STACK: prints[4].push('SIZE:      ${get_rom()}');
				case STK_OFF: prints[4].push('OFFSET:  ${get_rom()}');
				case LOCAL_CALL:
					var func_id = get_rom();
					prints[4].push('FUNCTION:  ${func_id}  (${func_names[func_id]})');
				default: prints[4].push("-");
			}
		}

		// Cleaner looking
		for (i in 0...prints.length) {
			var temparray:Array<String> = prints[i].copy();
			temparray.sort((a, b) -> {return b.length-a.length;});
			printsSizes[i] = temparray[0].length;
		}

		for (i in 0...prints.length) {
			for (p in 0...prints[i].length) {
				prints[i][p] += FastUtils.repeatString(" ", (printsSizes[i] - prints[i][p].length));
			}
		}

		var header:String = '$lineprefix ${prints[0].shift()}  |  ${prints[1].shift()}  |  ${prints[2].shift()}  |  ${prints[3].shift()}  |  ${prints[4].length > 0 ? prints[4].shift() : ""}';
		if (header.length > headerLength)
			headerLength = header.length;
		var buf = new FastStringBuf();
		buf.addStr('$lineprefix${StringUtils.getTitle("BYTE CODE:", headerLength+extraHeading)}\n$lineprefix$header\n$lineprefix${FastUtils.repeatString("-", headerLength+extraHeading)}\n');
		for (i in 0...instructions.length)
			buf.addStr('$lineprefix ${prints[0][i]}  |  ${prints[1][i]}  |  ${prints[2][i]}  |  ${prints[3][i]}  |  ${prints[4][i].length > 0 ? prints[4][i] : ""} \n');

		return buf.toString();
	}

	public function print_opcode(o:OpCode):String {
		return switch (o) {
			case PUSH: "PUSH";

			case PUSHV: "PUSHV";
			case PUSHC: "PUSHC";

			case POP: "POP";

			case SAVE: "SAVE";

			case RET: "RET";

			case DEPTH_INC: "DEPTH_INC";
			case DEPTH_DNC: "DEPTH_DNC";

			case JUMP: "JUMP";
			case JUMP_COND: "JUMP_COND";
			case JUMP_N_COND: "JUMP_N_COND";

			case CALL: "CALL";
			case FIELD_SET: "FIELD_SET";
			case FIELD_GET: "FIELD_GET";
			case NEW: "NEW";

			case PUSH_ARRAY: "PUSH_ARRAY";
			case PUSH_TRUE: "PUSH_TRUE";
			case PUSH_FALSE: "PUSH_FALSE";
			case PUSH_NULL: "PUSH_NULL";
			case PUSH_OBJECT: "PUSH_OBJECT";

			case ARRAY_GET: "ARRAY_GET";
			case ARRAY_SET: "ARRAY_SET";
			case ARRAY_STACK: "ARRAY_STACK";

			case ADD: "ADD";
			case MULT: "MULT";
			case DIV: "DIV";
			case SUB: "SUB";
			case EQ: "EQ";
			case NEQ: "NEQ";
			case GT: "GT";
			case GTE: "GTE";
			case LT: "LT";
			case LTE: "LTE";
			case AND: "AND";
			case OR: "OR";
			case XOR: "XOR";
			case BAND: "BAND";
			case BOR: "BOR";
			case IS: "IS";

			case SHL: "SHL";
			case SHR: "SHR";
			case USHR: "USHR";

			case MOD: "MOD";

			case INC: "INC";
			case DNC: "DNC";
			case NOT: "NOT";
			case NEG: "NEG";
			case NGBITS: "NGBITS";
			case DUP: "DUP";
			case STK_OFF: "STK_OFF";

			case LOCAL_CALL: "LOCAL_CALL";
		}
	}

	public inline static function createEmpty():Program {
		return new Program([], [], [], [], [], []);
	}
}
