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
		if (curr == None)
			curr = func(count);

		return curr;
	}

	public function junk():Void {
		curr = None;
		count++;
	}

	public function empty():Bool {
		return Type.enumEq(peek(), None);
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

	var storedItems:Array<T> = [];
	var stack:Array<Tuple<Int, Option<T>>> = [];

	public function new(stream:Stream<T>) {
		this.stream = stream;
		super(function(i:Int):Option<T> {
			if(storedItems.length > 0)
				return Some(storedItems.pop());
			var t = stream.func(i);
			switch t {
				case Some(t): cache.add(t);
				case None:
			}
			return t;
		});
	}

	public function match(...args:T):Bool {
		store();
		for (arg in args) {
			if (arg != null && !CompareUtils.deepEqual(peek(), Some(arg))) {
				restore();
				return false;
			}
			stream.junk();
		}
		discard();
		return true;
	}

	public macro function matchSpecial(args: Array<haxe.macro.Expr>):haxe.macro.Expr {
		var self = args.shift();
		var func = args.pop();
		//for(arg in args) {
		//	trace(new haxe.macro.Printer().printExpr(arg), "############", arg);
		//}
		var f = [];
		var combinedExpr = macro {
			${self}.discard();
			${func}
		};
		args.reverse();
		for(arg in args) {
			switch arg.expr {
				case EParenthesis(_.expr => EBinop(OpAssign, _.expr => EConst(CIdent(s)), e2)):
					var varName = s;
					//combinedExpr = macro ($combinedExpr; var $i{varName} = ${e2});
					combinedExpr = macro {
						var $s = ${e2};
						if($i{s} != null)
							${combinedExpr};
						else
							${self}.restore();
					};
				default:
					var cf = haxe.macro.Context.typeExpr(arg);
					var isEnum = cf.t.match(TEnum(_, _));
					if(isEnum) {
						combinedExpr = macro if(${self}.peek().match(Some($arg))) {
							${self}.junk();
							${combinedExpr};
						} else {
							${self}.restore();
						};
					} else {
						if(arg.expr.match(EConst(CIdent(_)))) {
							combinedExpr = macro {
								${self}.junk();
								${combinedExpr};
							}
						}
						throw "Unsupported type";
					}
			}
		}
		var finalExpr = macro {
			${self}.store();
			${combinedExpr};
		};
		//trace(new haxe.macro.Printer().printExpr(finalExpr));
		return finalExpr;
	}

	public inline function store():Void {
		stack.push(Tuple.make(cache.arr.length, curr));
	}
	public inline function discard():Void {
		stack.pop();
	}
	public function restore():Void {
		var tup = stack.pop();
		var len = tup.t1;
		var curr = tup.t2;
		for (i in 0...len)
			storedItems.insert(0, cache.arr.pop());
		this.curr = curr;
	}

	public function getEntire():Array<T> {
		while(!empty())
			next();
		return cache.arr;
	}

	public override function empty():Bool {
		return stream.empty();
	}

	public function last():T {
		if(cache.length == 0)
			return stream.peek().get();
		return cache.get(cache.length - 1);
	}
}
