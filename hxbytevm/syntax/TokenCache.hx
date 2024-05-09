package hxbytevm.syntax;

import hxbytevm.core.Ast;
import hxbytevm.core.Token;

class TokenCache {
	public var tokens:Array<Token> = []; // TODO: use a linked list
	public var length(get, never):Int;

	public function new() {}

	public inline function add(tk:Token) {
		tokens.push(tk);
	}

	public inline function get(idx:Int):Token {
		return tokens[idx];
	}

	private inline function get_length():Int {
		return tokens.length;
	}

	public function clear() {
		tokens = [];
	}
}
