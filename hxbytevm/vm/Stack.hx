package hxbytevm.vm;

class Stack {
	public function new() {}

	public static final DEFAULT_STACK_SIZE:Int = 8;
	public static final MAX_STACK_GROW:Int = 32;

	public var stack:Array<Dynamic> = [for (i in 0...DEFAULT_STACK_SIZE) null];
	public var stackTop:Int = 0;

	public inline function push(v:Dynamic) {
		if (stackTop >= (stack.length)) grow();
		stack[stackTop] = v;
		return stack[(stackTop++) - 1];
	}

	public inline function pop():Dynamic {
		stackTop--;
		var ret = stack[stackTop];
		stack[stackTop] = null;
		return ret;
	}

	public inline function grow()
		stack.resize(stack.length + (stack.length > MAX_STACK_GROW ? MAX_STACK_GROW : stack.length));

	public inline function top():Dynamic
		return stack[stackTop-1];
}
