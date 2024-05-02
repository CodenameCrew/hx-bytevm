package hxbytevm.vm;

enum OpCode {
	OPush; // 1 STORAGE SPACE: Pushes storage1 to stack
	OSave; // 2 STORAGE SPACE: Pushes stack[storage1] to variables[storage2], removing it from the stack
	ORet; // 1 STORAGE SPACE: Returns stack[storage1], removing it from the stack

	OJump; // 1 STORAGE SPACE: Moves instruction pointer to storage1

	OBlockStart; // 1 STORAGE SPACE: Defines a the start of a block section, storage1 being the instruction pointer of the end block
	OBlockEnd; // 1 STORAGE SPACE: Defines a the end of a block section, storage1 being the instruction pointer of the start block

	OFunc; // 2 STORAGE SPACE: Defines a function, storage1 being FunctionKind and storage2 being Func (refer to ExprDef in core/Ast.hx), expects a OBlock directly after
	OWhile; // 2 STORAGE SPACE: Defines a while loop, storage1 being the stack postion of condition of the while, storage2 being the while flag (refer to WhileFlag in core/Ast.hx), expects a OBlock directly after

	OCall; // 2 STORAGE SPACE: Calls storage1 (a function), with a array of args from storage2
	OField; // 2 STORAGE SPACE: Gets field storage2 (a string) from storage1 (anything that has fields)

	OArray; // 1 STORAGE SPACE: Creates a array from stack top, going down by storage1 and pushes it to stack (while removing all values added to the array)
	ONew; // 2 STORAGE SPACE: Creates a instance from storage1 being PlacedTypePath (refer to PlacedTypePath in core/Ast.hx) with args from stack[storage2], removing storage2 from stack and pushing the new instance to stack

	OAdd; // 0 STORAGE SPACE: Adds the last 2 in stack, which is then added back to stack, removing the 2 values
	OSub; // 0 STORAGE SPACE: Subtracts the last 2 in stack, which is then added back to stack, removing the 2 values
	OMult; // 0 STORAGE SPACE: Multiplys the last 2 in stack, which is then added back to stack, removing the 2 values
	ODiv; // 0 STORAGE SPACE: Divides the last 2 in stack, which is then added back to stack, removing the 2 values
}

typedef Program = {
	var intructions:Array<OpCode>;
	var storage:Array<Dynamic>;
}


class HVM {
	public function new() {}

	var depth:Int = 0;

	var intructions:Array<OpCode>;
	var storage:Array<Dynamic>;
	public function run(program:Program) {
		intructions = program.intructions;
		storage = program.storage;
	}
}
