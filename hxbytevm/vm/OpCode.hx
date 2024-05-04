package hxbytevm.vm;

enum abstract OpCode(#if cpp cpp.Int8 #else Int #end) {
	var PUSH:OpCode = 0; // 1 ROM SPACE: Pushes ROM1 to stack
	var PUSHV:OpCode = 1; // 1 ROM SPACE: Pushes variables[ROM1] to stack
	var PUSHC:OpCode = 2; // 1 ROM SPACE: Pushes constants[ROM1] to stack
	var POP:OpCode = 3; // 0 ROM SPACE: Pops stack

	var SAVE:OpCode = 4; // 1 ROM SPACE: Pushes stack[stacktop] to variables[ROM1], removing it from the stack
	var RET:OpCode = 5; // 0 ROM SPACE: Returns stack[stacktop], removing it from the stack

	var DEPTH_INC:OpCode = 6; // 0 ROM SPACE: Adds 1 to the depth
	var DEPTH_DNC:OpCode = 7; // 0 ROM SPACE: Subtracts 1 to the depth

	var JUMP:OpCode = 8; // 2 ROM SPACE: Moves instruction pointer to ROM1, Moves ROM pointer to ROM2
	var JUMP_COND:OpCode = 9; // 2 ROM SPACE: Moves instruction pointer to ROM1, Moves ROM pointer to ROM2 if stack[stacktop] is true
	var JUMP_N_COND:OpCode = 10; // 2 ROM SPACE: Moves instruction pointer to ROM1, Moves ROM pointer to ROM2 if stack[stacktop] is false

	var FUNC:OpCode = 11; // 2 ROM SPACE: Defines a function, ROM1 being FunctionKind and ROM2 being Func (refer to ExprDef in core/Ast.hx), expects a OBlock directly after
	var CALL:OpCode = 12; // 0 ROM SPACE: Calls stack[stacktop-1] (a function), with a array of args from stack[stacktop], return is pushed to stacktop
	var FIELD:OpCode = 13; // 1 ROM SPACE: Gets field ROM2 (a string) from stack[stacktop], pushing to stack
	var NEW:OpCode = 14; // 2 ROM SPACE: Creates a instance from variables[ROM1] being a class with args from stack[stacktop], removing ROM2 from stack and pushing the new instance to stack

	var PUSH_ARRAY:OpCode = 15; // 0 ROM SPACE: Pushes a empty array to stack
	var PUSH_TRUE:OpCode = 16; // 0 ROM SPACE: Pushes a true to stack
	var PUSH_FALSE:OpCode = 17; // 0 ROM SPACE: Pushes a false to stack
	var PUSH_NULL:OpCode = 18; // 0 ROM SPACE: Pushes a null to stack
	var PUSH_OBJECT:OpCode = 19; // 0 ROM SPACE: Pushes a {} to stack

	var ARRAY_GET:OpCode = 20; // 2 ROM SPACE: Gets index ROM1 from stack[ROM2], pushing to stack
	var ARRAY_SET:OpCode = 21; // 2 ROM SPACE: Sets index ROM1 from stack[ROM2], popping it from stack
	var ARRAY_STACK:OpCode = 22; // 1 ROM SPACE: Creates a array from stack[stacktop] to stack[stacktop-ROM1], popping all values from stack

	var ADD:OpCode = 23; // 0 ROM SPACE: added last 2 variables in stack v1+v2, popping both of them and pushing the result to the stack
	var MULT:OpCode = 24; // 0 ROM SPACE: mults last 2 variables in stack v1*v2, popping both of them and pushing the result to the stack
	var DIV:OpCode = 25; // 0 ROM SPACE: divs last 2 variables in stack v1/v2, popping both of them and pushing the result to the stack
	var SUB:OpCode = 26; // 0 ROM SPACE: subs last 2 variables in stack v1-v2, popping both of them and pushing the result to the stack
	var EQ:OpCode = 27; // 0 ROM SPACE: checks if the last 2 variables in stack are equal v1==v2, popping both of them and pushing the result to the stack
	var NEQ:OpCode = 28; // 0 ROM SPACE: checks if the last 2 variables in stack are NOT equal v1!=v2, popping both of them and pushing the result to the stack
	var GT:OpCode = 29; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is greater then v2, v1>v2, popping both of them and pushing the result to the stack
	var GTE:OpCode = 30; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is greater and EQAUL then v2, v1>=v2, popping both of them and pushing the result to the stack
	var LT:OpCode = 31; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is less then v2, v1<v2, popping both of them and pushing the result to the stack
	var LTE:OpCode = 32; // 0 ROM SPACE: uses last 2 variables in stack to see if v1 is less and EQAUL then v2, v1<=v2, popping both of them and pushing the result to the stack
	var AND:OpCode = 33; // 0 ROM SPACE: checks the last 2 variables, v1&v2, popping both of them and pushing the result to the stack
	var OR:OpCode = 34; // 0 ROM SPACE: checks the last 2 variables, v1|v2, popping both of them and pushing the result to the stack
	var XOR:OpCode = 35; // 0 ROM SPACE: uses the last 2 variables, v1^v2, popping both of them and pushing the result to the stack
	var BAND:OpCode = 36; // 0 ROM SPACE: checks if the last 2 variables are both true v1&&v2, popping both of them and pushing the result to the stack
	var BOR:OpCode = 37; // 0 ROM SPACE: checks if either the last 2 variables are true v1||v2, popping both of them and pushing the result to the stack

	var SHL:OpCode = 38; // 0 ROM SPACE: uses the last 2 variables, v1<<v2, popping both of them and pushing the result to the stack
	var SHR:OpCode = 39; // 0 ROM SPACE: uses the last 2 variables, v1>>v2, popping both of them and pushing the result to the stack
	var USHR:OpCode = 40; // 0 ROM SPACE: uses the last 2 variables, v1>>>v2, popping both of them and pushing the result to the stack

	var MOD:OpCode = 41; // 0 ROM SPACE: uses the last 2 variables, v1%v2, popping both of them and pushing the result to the stack

	var INC:OpCode = 42; // 0 ROM SPACE: increments the last variable in the stack, v++, pushing the result to the stack
	var DNC:OpCode = 43; // 0 ROM SPACE: decrements the last variable in the stack, v--, pushing the result to the stack
	var NOT:OpCode = 44; // 0 ROM SPACE: checks if the last variable is false then returning true, !v, pushing the result to the stack
	var NEG:OpCode = 45; // 0 ROM SPACE: negtives the last variable in stack, -v, pushing the result to the stack
	var NGBITS:OpCode = 46; // 0 ROM SPACE: negtive bits the last variable in stack, ~v, pushing the result to the stack
}
