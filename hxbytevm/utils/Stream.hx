package hxbytevm.utils;

import haxe.Exception;
import haxe.ds.Option;

using hxbytevm.utils.HelperUtils;

class StreamError extends Exception {
}

class Stream<T> {
	public var count:Int;
	public var curr:Option<T>;
	public var func:Int->Option<T>;

	public function new(func:Int->Option<T>) {
		this.count = 0;
		this.curr = None;
		this.func = func;
	}

	public function next():T {
		switch(peek()) {
			case Some(value):
				junk();
				return value;
			case None:
				throw new StreamError("Stream is empty");
		}
	}

	public function peek():Option<T> {
		if (curr == None) {
			curr = func(count);
		}

		return curr;
	}

	public function junk():Void {
		curr = None;
		count++;
	}

	public function empty():Bool {
		return peek() == None;
	}

	public inline static function create<T>(func:Int->Option<T>):Stream<T> {
		return new Stream(func);
	}

	public inline static function createFromArray<T>(array:Array<T>):Stream<T> {
		return create(function(i:Int):Option<T> {
			return if (i < array.length) Some(array[i]) else None;
		});
	}
}
