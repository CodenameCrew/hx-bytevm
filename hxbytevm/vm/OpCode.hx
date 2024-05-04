package hxbytevm.vm;

enum abstract OpCode(#if cpp cpp.Int8 #else Int #end) {
	var PUSH:OpCode; // 1 ROM SPACE: Pushes ROM1 to stack

	var PUSHV:OpCode; // 1 ROM SPACE: Pushes _variables[scope][ROM1] to stack
	var PUSHV_D:OpCode; // 2 ROM SPACE: Pushes _variables[ROM1][ROM2] to stack
	var PUSHC:OpCode; // 1 ROM SPACE: Pushes constants[ROM1] to stack

	var POP:OpCode; // 0 ROM SPACE: Pops stack

	var SAVE:OpCode; // 1 ROM SPACE: Pushes stack[stacktop] to variables[depth][ROM1], removing it from the stack
	var SAVE_D:OpCode; // 2 ROM SPACE: Pushes stack[stacktop] to variables[ROM1][ROM2], removing it from the stack

	var RET:OpCode; // 0 ROM SPACE: Returns stack[stacktop], removing it from the stack

	var DEPTH_INC:OpCode; // 0 ROM SPACE: Adds 1 to the depth
	var DEPTH_DNC:OpCode; // 0 ROM SPACE: Subtracts 1 to the depth

	var JUMP:OpCode; // 2 ROM SPACE: Moves instruction pointer to ROM1, Moves ROM pointer to ROM2
	var JUMP_COND:OpCode; // 2 ROM SPACE: Moves instruction pointer to ROM1, Moves ROM pointer to ROM2 if stack[stacktop] is true
	var JUMP_N_COND:OpCode; // 2 ROM SPACE: Moves instruction pointer to ROM1, Moves ROM pointer to ROM2 if stack[stacktop] is false

	var CALL:OpCode; // 1 ROM SPACE: Calls stack[stacktop-1-ROM1] (a function), with a args with a length of ROM1 from stack, return is pushed to stacktop
	var LOCAL_CALL:OpCode; // 2 ROM SPACE:  Moves pointer to a ROM1 (a function pointer), and

	var FIELD_SET:OpCode; // 1 ROM SPACE: Sets field ROM2 (a string) from stack[stacktop], popping it from stack
	var FIELD_GET:OpCode; // 1 ROM SPACE: Gets field ROM2 (a string) from stack[stacktop], pushing to stack

	var FUNC:OpCode; // 2 ROM SPACE: Defines a function, ROM1 being FunctionKind and ROM2 being Func (refer to ExprDef in core/Ast.hx), expects a OBlock directly after
	var NEW:OpCode; // 0 ROM SPACE: Creates a instance from stack[stacktop] (args) being a class with args from stack[stacktop-1] (class), removing both from stack and pushing the new instance to stack

	var PUSH_ARRAY:OpCode; // 0 ROM SPACE: Pushes a empty array to stack
	var PUSH_TRUE:OpCode; // 0 ROM SPACE: Pushes a true to stack
	var PUSH_FALSE:OpCode; // 0 ROM SPACE: Pushes a false to stack
	var PUSH_NULL:OpCode; // 0 ROM SPACE: Pushes a null to stack
	var PUSH_OBJECT:OpCode; // 0 ROM SPACE: Pushes a {} to stack

	var ARRAY_GET:OpCode; // 0 ROM SPACE: Gets index stack[stacktop] from stack[stacktop], pushing to stack
	var ARRAY_SET:OpCode; // 0 ROM SPACE: Sets index stack[stacktop-1] from stack[stacktop-2] with value stack[stacktop], popping it from stack
	var ARRAY_GET_KNOWN:OpCode; // 1 ROM SPACE: Gets index ROM1 from stack[stacktop], pushing to stack
	var ARRAY_SET_KNOWN:OpCode; // 1 ROM SPACE: Sets index ROM1 from stack[stacktop-1] with value stack[stacktop], popping it from stack
	var ARRAY_STACK:OpCode; // 1 ROM SPACE: Creates a array from stack[stacktop] to stack[stacktop-ROM1], popping all values from stack

	var ADD:OpCode; // 0 ROM SPACE: added last 2 variables in stack v1+v2, popping both of them and pushing the result to the stack
	var MULT:OpCode; // 0 ROM SPACE: mults last 2 variables in stack v1*v2, popping both of them and pushing the result to the stack
	var DIV:OpCode; // 0 ROM SPACE: divs last 2 variables in stack v1/v2, popping both of them and pushing the result to the stack
	var SUB:OpCode; // 0 ROM SPACE: subs last 2 variables in stack v1-v2, popping both of them and pushing the result to the stack
	var EQ:OpCode; // 0 ROM SPACE: checks if the last 2 variables in stack are equal v1==v2, popping both of them and pushing the result to the stack
	var NEQ:OpCode; // 0 ROM SPACE: checks if the last 2 variables in stack are NOT equal v1!=v2, popping both of them and pushing the result to the stack
	var GT:OpCode; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is greater then v2, v1>v2, popping both of them and pushing the result to the stack
	var GTE:OpCode; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is greater and EQAUL then v2, v1>=v2, popping both of them and pushing the result to the stack
	var LT:OpCode; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is less then v2, v1<v2, popping both of them and pushing the result to the stack
	var LTE:OpCode; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is less and EQAUL then v2, v1<=v2, popping both of them and pushing the result to the stack
	var AND:OpCode; // 0 ROM SPACE: checks the last 2 variables, v1&v2, popping both of them and pushing the result to the stack
	var OR:OpCode; // 0 ROM SPACE: checks the last 2 variables, v1|v2, popping both of them and pushing the result to the stack
	var XOR:OpCode; // 0 ROM SPACE: uses the last 2 variables, v1^v2, popping both of them and pushing the result to the stack
	var BAND:OpCode; // 0 ROM SPACE: checks if the last 2 variables are both true v1&&v2, popping both of them and pushing the result to the stack
	var BOR:OpCode; // 0 ROM SPACE: checks if either the last 2 variables are true v1||v2, popping both of them and pushing the result to the stack
	var IS:OpCode; // 0 ROM SPACE: v1 == v2 (a type), v1 is v2, pushing the result to the stack

	var SHL:OpCode; // 0 ROM SPACE: uses the last 2 variables, v1<<v2, popping both of them and pushing the result to the stack
	var SHR:OpCode; // 0 ROM SPACE: uses the last 2 variables, v1>>v2, popping both of them and pushing the result to the stack
	var USHR:OpCode; // 0 ROM SPACE: uses the last 2 variables, v1>>>v2, popping both of them and pushing the result to the stack

	var MOD:OpCode; // 0 ROM SPACE: uses the last 2 variables, v1%v2, popping both of them and pushing the result to the stack

	var INC:OpCode; // 0 ROM SPACE: increments the last variable in the stack, v++, pushing the result to the stack
	var DNC:OpCode; // 0 ROM SPACE: decrements the last variable in the stack, v--, pushing the result to the stack
	var NOT:OpCode; // 0 ROM SPACE: checks if the last variable is false then returning true, !v, pushing the result to the stack
	var NEG:OpCode; // 0 ROM SPACE: negtives the last variable in stack, -v, pushing the result to the stack
	var NGBITS:OpCode; // 0 ROM SPACE: negtive bits the last variable in stack, ~v, pushing the result to the stack

	var DUP:OpCode; // 0 ROM SPACE: duplicates stack[stacktop], pushing it to stack
	var STK_OFF:OpCode; // 1 ROM SPACE: gets stack[stacktop+ROM1], pushing it to stack

	var LENGTH:OpCode; // 0 ROM SPACE: pushes the length of the last array in stack, pushing it to the stack




	var COMMENT:OpCode; // 1 ROM SPACE: Adds a comment to the program
}
