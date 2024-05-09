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
		if(func == null)
			throw "Stream function cannot be null";
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

@:allow(hxbytevm.utils.StreamCacheAccessor)
class CacheStream<T> extends Stream<T> {
	var stream:Stream<T>;
	var cache:Cache<T> = new Cache<T>();

	public function new(stream:Stream<T>) {
		super(function(i:Int):Option<T> {
			var t = stream.func(i);
			switch t {
				case Some(t): cache.add(t);
				case None:
			}
			return t;
		});
	}

	public function getEntire():Array<T> {
		while(!empty())
			next();
		return cache.arr;
	}

	public override function empty():Bool {
		return stream.empty();
	}
}

@:forward
@:notNull abstract StreamCacheAccessor<T>(CacheStream<T>) from CacheStream<T> to CacheStream<T> {
	public inline function new(stream:CacheStream<T>) {
		this = stream;
	}

	public function last():T {
		if(this.cache.length == 0)
			return this.peek().get();
		return this.cache.get(this.cache.length - 1);
	}
}
