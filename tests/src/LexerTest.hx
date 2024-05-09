package;

import sys.io.File;
import hxbytevm.syntax.Lexer;

class LexerTest {

	public static var HELLO_WORLD:String = "trace('Hello World');";
	public static var WHILE_LOOP:String = "while (i < 10) { i++; trace(i); }";
	public static var FIBBONACCI:String = "function fib(n) { if (n <= 1) return n; return fib(n-1) + fib(n-2); }";
	public static var FUNCTION_RECURSIVE:String = "function RECURSIVE(n) { if (n <= 1) return n; trace('RECURSIVE N:', n); return RECURSIVE(n-1); }";
	public static var REGEX:String = "var re = ~/[a-z]+/g; var re = ~/[a-z]+/; re.match('abcdef');";
	public static var COMMENT:String = "/**/Hello World/* */TEST";
	public static var COMMENTSINGLE:String = "//Hello World\r\nTEST // TEST";

	public static function main() {
		Sys.println(Util.getTitle("LEXER TESTING"));

		var tokens = Lexer.parse(HELLO_WORLD);
		trace(tokens);

		trace(Lexer.parse(WHILE_LOOP));
		trace(Lexer.parse(FIBBONACCI));
		trace(Lexer.parse(FUNCTION_RECURSIVE));
		trace(Lexer.parse(REGEX));
		trace(Lexer.parse(COMMENT));
		trace(Lexer.parse(COMMENTSINGLE));
	}
}
