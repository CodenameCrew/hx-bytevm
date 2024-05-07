package hxbytevm.vm;

#if cpp
import cpp.NativeArray;
#end

class Stack {
	public function new() {}

	public static final DEFAULT_STACK_SIZE:Int = 8;
	public static final MAX_STACK_GROW:Int = 32;

	#if cpp
	public var stack = NativeArray.create(DEFAULT_STACK_SIZE);
	#else
	public var stack:Array<Dynamic> = [for (i in 0...DEFAULT_STACK_SIZE) null];
	#end
	public var stackTop:Int = 0;

	public inline function push(v:Dynamic) {
		if (stackTop >= (stack.length)) grow();
		untyped stack.__unsafe_set(stackTop, v);
		return untyped stack.__unsafe_get((stackTop++) - 1);
	}

	public inline function pop():Dynamic {
		stackTop--;
		#if cpp
		var ret = untyped stack.__unsafe_get(stackTop);
		untyped stack.__unsafe_set(stackTop, null);
		#else
		var ret = stack[stackTop];
		stack[stackTop] = null;
		#end
		return ret;
	}

	public inline function grow()
		#if cpp untyped stack.__SetSizeExact #else stack.resize #end (stack.length + (stack.length > MAX_STACK_GROW ? MAX_STACK_GROW : stack.length));

	public inline function top(?offset:Int = 0):Dynamic
		return #if cpp untyped stack.__unsafe_get(stackTop-1+offset) #else stack[stackTop-1+offset] #end;

	public inline function getShortVersion():Array<Dynamic>
		return stackTop >= 0 ? stack.slice(0, stackTop) : [];

	public function toString():String {
		return "Stack([" + getShortVersion().join(", ") + "])";
	}
}
