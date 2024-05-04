package hxbytevm.vm;

import hxbytevm.compiler.Compiler.Pointer;
import hxbytevm.utils.StringUtils;

typedef StackValue = Dynamic;

@:forward
abstract PrintingArray<T>(Array<T>) from Array<T> to Array<T> {

	public function add(v:T) {
		this.push(v);
	}
}

class Program {
	public var instructions:PrintingArray<OpCode>;
	public var read_only_stack:Array<StackValue>;
	public var constant_stack:Array<StackValue>;
	public var varnames_stack:Array<Array<String>>;
	public var function_pointers:Map<String, Pointer> = [];

	public function new(instructions:Array<OpCode>, read_only_stack:Array<StackValue>, constant_stack:Array<StackValue>, varnames_stack:Array<Array<String>>, function_pointers:Map<String, Pointer>) {
		this.instructions = instructions;
		this.read_only_stack = read_only_stack;
		this.constant_stack = constant_stack;
		this.varnames_stack = varnames_stack;
		this.function_pointers = function_pointers;
	}

	public function print() {
		var prints:Array<Array<String>> = [["IP"], ["RP"], ["D"], ["CODE"], ["ROM"]];
		var printsSizes:Array<Int> = [0, 0, 0];

		trace(instructions, read_only_stack, constant_stack, varnames_stack, function_pointers);

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

			trace(i, print_opcode(ip), rp, dp);

			switch (ip) {
				#if HXBYTEVM_DEBUG
				case COMMENT: prints[4].push('COMMENT:   ${constant_stack[get_rom()]}');
				#end
				case PUSH: prints[4].push('VAR:       ${get_rom()}');
				case PUSHV | SAVE:
					var v_id = get_rom();
					var isValid = varnames_stack[dp] != null;
					prints[4].push('VAR_ID:    $v_id  ("${ !isValid ? "invalid depth (propbably a error)" : varnames_stack[dp][v_id]}")');
				case PUSHV_D | SAVE_D:
					var d = get_rom();
					var v_id = get_rom();
					if(varnames_stack[d] == null) prints[4].push('VAR_ID DEPTH ERROR D: $d, V_ID: $v_id');
					else prints[4].push('VAR_ID:    $v_id  ("${varnames_stack[d][v_id]}") (D: $d)');
				case PUSHC:
					var c_id = get_rom();
					var const = constant_stack[c_id];
					var desc:String = '${const is String ? '"' : ''}$const${const is String ? '"' : ''}';
					prints[4].push('CONST_ID:  $c_id  ($desc)');
				case JUMP | JUMP_COND | JUMP_N_COND:
					var _ip = get_rom();
					var _rp = get_rom();
					prints[4].push('IP: ${_ip}, RP: ${_rp}');
				case FUNC:
					//var kind = get_rom();
					//var func = get_rom();
					//prints[4].push('K:  ${kind}, F:  ${func}');
					prints[4].push('FUNCTION');
				case FIELD_GET | FIELD_SET: prints[4].push('NAME:  ${get_rom()}');
				case ARRAY_GET | ARRAY_SET | ARRAY_GET_KNOWN | ARRAY_SET_KNOWN:
					var known = ip == ARRAY_GET_KNOWN || ip == ARRAY_SET_KNOWN;
					//var array_i = get_rom();
					//var array_r = get_rom();
					var array_i = known ? get_rom() : null;
					var array_r = "<STACK>";
					prints[4].push('A_ID:  ${array_r}, I_ID:  ${array_i}');
				case ARRAY_STACK: prints[4].push('SIZE:      ${get_rom()}');
				case STK_OFF: prints[4].push('OFFSET:  ${get_rom()}');
				case CALL: prints[4].push('ARGS:  ${get_rom()}');
				case LOCAL_CALL:
					var length = get_rom();
					var r = get_rom();
					var i = get_rom();
					prints[4].push('ARGS:  ${length}  IP: ${i}, RP: ${r}');
				default: prints[4].push("-");
			}
		}

		// Cleaner looking
		for (i in 0...prints.length) {
			var temparray:Array<String> = prints[i].copy();
			temparray.sort((a, b) -> {return b.length-a.length;});
			printsSizes[i] = temparray[0].length;
		}

		for (i in 0...prints.length)
			for (p in 0...prints[i].length) {
				prints[i][p] += StringTools.lpad("", " ", (printsSizes[i] - prints[i][p].length));
			}

		var header:String = ' ${prints[0].shift()}  |  ${prints[1].shift()}  |  ${prints[2].shift()}  |  ${prints[3].shift()}  |  ${prints[4].shift() : ""}';
		var result:String = '${StringUtils.getTitle("BYTE CODE:", header.length)}\n$header\n${StringTools.lpad("", "-", header.length)}\n';
		for (i in 0...instructions.length)
			result += ' ${prints[0][i]}  |  ${prints[1][i]}  |  ${prints[2][i]}  |  ${prints[3][i]}  |  ${prints[4][i].length > 0 ? prints[4][i] : ""} \n';

		return result;
	}

	public function print_opcode(o:OpCode):String {
		return switch (o) {
			case PUSH: "PUSH";

			case PUSHV: "PUSHV";
			case PUSHV_D: "PUSHV_D";
			case PUSHC: "PUSHC";

			case POP: "POP";

			case SAVE: "SAVE";
			case SAVE_D: "SAVE_D";

			case RET: "RET";

			case DEPTH_INC: "DEPTH_INC";
			case DEPTH_DNC: "DEPTH_DNC";

			case JUMP: "JUMP";
			case JUMP_COND: "JUMP_COND";
			case JUMP_N_COND: "JUMP_N_COND";

			case FUNC: "FUNC";
			case CALL: "CALL";
			case LOCAL_CALL: "LOCAL_CALL";
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
			case ARRAY_GET_KNOWN: "ARRAY_GET_KNOWN";
			case ARRAY_SET_KNOWN: "ARRAY_SET_KNOWN";
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

			case LENGTH: "LENGTH";
			#if HXBYTEVM_DEBUG
			case COMMENT: "COMMENT";
			#end
		}
	}

	public static function createEmpty():Program {
		return new Program([], [], [], [], []);
	}
}
