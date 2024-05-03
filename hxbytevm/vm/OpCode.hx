package hxbytevm.vm;

enum abstract OpCode(#if cpp cpp.Int8 #else Int #end) {
	var PUSH:OpCode = 0; // 1 get_rom SPACE: Pushes get_rom1 to stack
	var PUSHV:OpCode = 1; // 1 get_rom SPACE: Pushes variables[get_rom1] to stack
	var PUSHC:OpCode = 2; // 1 get_rom SPACE: Pushes constants[get_rom1] to stack
	var POP:OpCode = 3; // 0 get_rom SPACE: Pops stack

	var SAVE:OpCode = 4; // 1 get_rom SPACE: Pushes stack[stacktop] to variables[get_rom1], removing it from the stack
	var RET:OpCode = 5; // 0 get_rom SPACE: Returns stack[stacktop], removing it from the stack

	var DEPTH_INC:OpCode = 6; // 0 get_rom SPACE: Adds 1 to the depth
	var DEPTH_DNC:OpCode = 7; // 0 get_rom SPACE: Subtracts 1 to the depth

	var JUMP:OpCode = 8; // 2 get_rom SPACE: Moves instruction pointer to get_rom1, Moves get_rom pointer to get_rom2
	var JUMP_COND:OpCode = 9; // 2 get_rom SPACE: Moves instruction pointer to get_rom1, Moves get_rom pointer to get_rom2 if stack[stacktop] is true

	var FUNC:OpCode = 10; // 2 get_rom SPACE: Defines a function, get_rom1 being FunctionKind and get_rom2 being Func (refer to ExprDef in core/Ast.hx), expects a OBlock directly after
	var CALL:OpCode = 11; // 0 get_rom SPACE: Calls stack[stacktop-1] (a function), with a array of args from stack[stacktop], return is pushed to stacktop
	var FIELD:OpCode = 12; // 1 get_rom SPACE: Gets field get_rom2 (a string) from stack[stacktop], pushing to stack
	var NEW:OpCode = 13; // 2 get_rom SPACE: Creates a instance from variables[get_rom1] being a class with args from stack[stacktop], removing get_rom2 from stack and pushing the new instance to stack

	var PUSH_ARRAY:OpCode = 14; // 0 get_rom SPACE: Pushes a empty array to stack
	var PUSH_TRUE:OpCode = 15; // 0 get_rom SPACE: Pushes a true to stack
	var PUSH_FALSE:OpCode = 16; // 0 get_rom SPACE: Pushes a false to stack
	var PUSH_NULL:OpCode = 17; // 0 get_rom SPACE: Pushes a null to stack

	var ARRAY_GET:OpCode = 18; // 2 get_rom SPACE: Gets index get_rom1 from stack[get_rom2], pushing to stack
	var ARRAY_SET:OpCode = 19; // 2 get_rom SPACE: Sets index get_rom1 from stack[get_rom2], popping it from stack
	var ARRAY_STACK:OpCode = 20; // 1 get_rom SPACE: Creates a array from stack[stacktop] to stack[stacktop-get_rom1], popping all values from stack

	var ADD:OpCode = 21; // 0 get_rom SPACE: added last 2 variables in stack v1+v2, popping both of them and pushing the result to the stack
	var MULT:OpCode = 22; // 0 get_rom SPACE: mults last 2 variables in stack v1*v2, popping both of them and pushing the result to the stack
	var DIV:OpCode = 23; // 0 get_rom SPACE: divs last 2 variables in stack v1/v2, popping both of them and pushing the result to the stack
	var SUB:OpCode = 24; // 0 get_rom SPACE: subs last 2 variables in stack v1-v2, popping both of them and pushing the result to the stack
	var EQ:OpCode = 25; // 0 get_rom SPACE: checks if the last 2 variables in stack are equal v1==v2, popping both of them and pushing the result to the stack
	var NEQ:OpCode = 26; // 0 get_rom SPACE: checks if the last 2 variables in stack are NOT equal v1!=v2, popping both of them and pushing the result to the stack
	var GT:OpCode = 27; // 0 get_rom SPACE: uses last 2 variables in stack to see if v1 is greater then v2, v1>v2, popping both of them and pushing the result to the stack
	var GTE:OpCode = 28; // 0 get_rom SPACE: uses last 2 variables in stack to see if v1 is greater and EQAUL then v2, v1>=v2, popping both of them and pushing the result to the stack
	var LT:OpCode = 29; // 0 get_rom SPACE: uses last 2 variables in stack to see if v1 is less then v2, v1<v2, popping both of them and pushing the result to the stack
	var LTE:OpCode = 30; // 0 get_rom SPACE: uses last 2 variables in stack to see if v1 is less and EQAUL then v2, v1<=v2, popping both of them and pushing the result to the stack
	var AND:OpCode = 31; // 0 get_rom SPACE: checks the last 2 variables, v1&v2, popping both of them and pushing the result to the stack
	var OR:OpCode = 32; // 0 get_rom SPACE: checks the last 2 variables, v1|v2, popping both of them and pushing the result to the stack
	var XOR:OpCode = 33; // 0 get_rom SPACE: uses the last 2 variables, v1^v2, popping both of them and pushing the result to the stack
	var BAND:OpCode = 34; // 0 get_rom SPACE: checks if the last 2 variables are both true v1&&v2, popping both of them and pushing the result to the stack
	var BOR:OpCode = 35; // 0 get_rom SPACE: checks if either the last 2 variables are true v1||v2, popping both of them and pushing the result to the stack

	var SHL:OpCode = 36; // 0 get_rom SPACE: uses the last 2 variables, v1<<v2, popping both of them and pushing the result to the stack
	var SHR:OpCode = 37; // 0 get_rom SPACE: uses the last 2 variables, v1>>v2, popping both of them and pushing the result to the stack
	var USHR:OpCode = 38; // 0 get_rom SPACE: uses the last 2 variables, v1>>>v2, popping both of them and pushing the result to the stack

	var MOD:OpCode = 39; // 0 get_rom SPACE: uses the last 2 variables, v1%v2, popping both of them and pushing the result to the stack

	var INC:OpCode = 40; // 0 get_rom SPACE: increments the last variable in the stack, v++, pushing the result to the stack
	var DNC:OpCode = 41; // 0 get_rom SPACE: decrements the last variable in the stack, v--, pushing the result to the stack
	var NOT:OpCode = 42; // 0 get_rom SPACE: checks if the last variable is false then returning true, !v, pushing the result to the stack
	var NEG:OpCode = 43; // 0 get_rom SPACE: negtives the last variable in stack, -v, pushing the result to the stack
	var NGBITS:OpCode = 44; // 0 get_rom SPACE: negtive bits the last variable in stack, ~v, pushing the result to the stack
}
