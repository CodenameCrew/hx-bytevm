package hxbytevm.vm;

class Stack<T> {
	public function new() {}

	public static final DEFAULT_STACK_SIZE:Int = 8;
	public static final MAX_STACK_GROW:Int = 32;

	public var stack:Array<T> = [for (i in 0...DEFAULT_STACK_SIZE) null];
	public var stackTop:Int = 0;

	public inline function push(v:T) {
		if (stackTop >= (stack.length)) grow();
		stack[stackTop] = v;
		return stack[(stackTop++) - 1];
	}

	public inline function pop():T {
		stackTop--;
		var ret = stack[stackTop];
		stack[stackTop] = null;
		return ret;
	}

	public inline function grow()
		stack.resize(stack.length + (stack.length > MAX_STACK_GROW ? MAX_STACK_GROW : stack.length));
}
