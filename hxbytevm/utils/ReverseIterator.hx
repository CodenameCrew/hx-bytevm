package hxbytevm.utils;

// Code from https://code.haxe.org/category/data-structures/reverse-iterator.html

class ReverseArrayIterator<T> {
	final arr:Array<T>;
	var i:Int;

	public inline function new(arr:Array<T>) {
		this.arr = arr;
		this.i = this.arr.length - 1;
	}

	@:pure public inline function hasNext() return i > -1;
	public inline function next() {
		return arr[i--];
	}

	@:pure public static inline function reversedValues<T>(arr:Array<T>) {
		return new ReverseArrayIterator(arr);
	}
}
class ReverseArrayKeyValueIterator<T> {
	final arr:Array<T>;
	var i:Int;

	public inline function new(arr:Array<T>) {
		this.arr = arr;
		this.i = this.arr.length - 1;
	}

	@:pure public inline function hasNext() return i > -1;
	public inline function next() {
		return @:fixed {value: arr[i], key: i--};
	}

	@:pure public static inline function reversedKeyValues<T>(arr:Array<T>) {
		return new ReverseArrayKeyValueIterator(arr);
	}
}

