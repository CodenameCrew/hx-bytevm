package hxbytevm.utils;

import hxbytevm.core.Ast;
import hxbytevm.core.Token;

class Cache<T> {
	public var arr:Array<T> = []; // TODO: use a linked list
	public var length(get, never):Int;

	public function new() {}

	public inline function add(tk:T) {
		arr.push(tk);
	}

	@:pure public inline function get(idx:Int):T {
		return arr[idx];
	}

	@:pure private inline function get_length():Int {
		return arr.length;
	}

	public inline function clear() {
		arr = [];
	}
}
