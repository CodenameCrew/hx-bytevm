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
		if (stackTop <= 0) return null;
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

	public var length(get, never):Int;
	public inline function get_length():Int
		return stackTop;

	public inline function isEmpty():Bool
		return stackTop == 0;

	public inline function clear() {
		stackTop = 0;
	}

	public inline function get(index:Int):Dynamic
		#if cpp
		return untyped stack.__unsafe_get(index);
		#else
		return stack[index];
		#end

	public inline function set(index:Int, value:Dynamic):Dynamic
		#if cpp
		return untyped stack.__unsafe_set(index, value);
		#else
		return stack[index] = value;
		#end

	public inline function getTop():Dynamic {
		if (stackTop <= 0) return null;
		#if cpp
		return untyped stack.__unsafe_get(stackTop - 1);
		#else
		return stack[stackTop - 1];
		#end
	}

	public inline function setTop(value:Dynamic):Dynamic {
		if (stackTop <= 0) return null;
		#if cpp
		return untyped stack.__unsafe_set(stackTop - 1, value);
		#else
		return stack[stackTop - 1] = value;
		#end
	}

	public inline function grow()
		#if cpp untyped stack.__SetSizeExact #else stack.resize #end (stack.length + (stack.length > MAX_STACK_GROW ? MAX_STACK_GROW : stack.length));

	public inline function top(?offset:Int = 0):Dynamic
		return #if cpp untyped stack.__unsafe_get(stackTop-1+offset) #else stack[stackTop-1+offset] #end;

	public inline function getShortVersion():Array<Dynamic>
		return stackTop >= 0 ? stack.copy().slice(0, stackTop) : [];

	public function toString():String {
		return "Stack([" + getShortVersion().join(", ") + "])";
	}
}
