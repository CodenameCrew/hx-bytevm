/*
 * The Haxe Compiler
 * Copyright (C) 2005-2019  Haxe Foundation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
package hxbytevm.core.syntax;

// Copyright since a lot of this code is from https://github.com/HaxeFoundation/haxe/blob/development/src/syntax/lexer.ml

import hxbytevm.core.Ast;
import hxbytevm.core.Token;

import hxbytevm.printer.Printer;

import hxbytevm.utils.macros.DefinesMacro;
import hxbytevm.utils.Errors;
import hxbytevm.utils.ExprUtils;
import hxbytevm.utils.VersionUtils;
import hxbytevm.utils.FastUtils;

import hxbytevm.utils.RegexUtils;
import hxbytevm.utils.StringUtils;
import hxbytevm.utils.FastStringBuf;
import hxbytevm.utils.Stream;

import haxe.ds.Option;

using hxbytevm.utils.HelperUtils;
using StringTools;

// TODO: Add string interpolation
// TODO: Add string unescaping in StringUtils.unescape

enum SmallType {
	TNull;
	TBool(b:Bool);
	TFloat(f:Float);
	TString(s:String);
	TVersion(version:Version);
}

abstract DefineContext(Map<String, Dynamic>) from Map<String, Dynamic> to Map<String, Dynamic> {
	public inline function new() {
		this = new Map();
	}

	public inline function defined(name:String):Null<Dynamic> {
		return this.get(name);
	}

	public inline function isDefined(name:String):Bool {
		return this.exists(name);
	}

	public inline function set(name:String, value:Dynamic):Void {
		this.set(name, value);
	}
}

class Lexer extends CacheStream<Token> {
	public var lexer:LexerImpl = new LexerImpl();
	public var defines(get, set):DefineContext;
	public var line(get, set):Int;

	public function new() {
		super(Stream.create(function(i:Int):Option<Token> {
			var tk = null;
			do {
				tk = lexer.nextToken();
			} while (tk == null);
			//trace(tk);
			return Some(tk);
		}));
		lexer.stream = this; // TEMP, TODO: turn Lexer and LexerImpl into a single class
	}

	public inline function load(text:String) {
		cache.clear();
		lexer.load(text);
	}

	public static function parse(input:String):Lexer {
		//if (input == null || input.length <= 0) return [TEof];
		var lexer = new Lexer();
		lexer.load(input);
		return lexer;
	}

	public override function empty():Bool {
		return peek().get(TEof) == TEof;
	}

	// Getter and setters
	private inline function get_defines():DefineContext {
		return lexer.defines;
	}
	private inline function set_defines(value:DefineContext):DefineContext {
		return lexer.defines = value;
	}
	private inline function get_line():Int {
		return lexer.line;
	}
	private inline function set_line(value:Int):Int {
		return lexer.line = value;
	}
}

/**
 * A lexer and preprocessor for the Haxe language.
**/
@:allow(hxbytevm.core.syntax.Lexer)
class LexerImpl {
	public var defines:DefineContext;
	private var stream:Lexer;

	private function new() {
		reset();
	}

	public function reset():Void {
		this.defines = loadDefaultDefines();
		this.input = null;
		this.pos = 0;
		this.line = 1;
	}

	public function load(input:String):Void {
		this.input = input;
		this.pos = 0;

		var ch = peekChar();
		if(ch == 0xfeff) { // remove byte order mark
			advanceChar();
		}
		if(ch == "#".code && peekChar(1) == "!".code) {
			while(ch != "\n".code && ch != "\r".code) {
				ch = advanceCharDirect();
			}
		}
	}

	public function loadDefaultDefines():Map<String, Dynamic> {
		return DefinesMacro.getDefines();
	}

	public var pos:Int = 0;
	public var input:String;

	@:pure public inline function isAtEnd(): Bool {
		return pos >= input.length;
	}

	@:pure public inline function peek(offset:Int = 0): String {
		return input.charAt(pos + offset);
	}

	public inline function advance(): String {
		return input.charAt(pos++);
	}

	@:pure public inline function peekChar(offset:Int = 0): Int {
		return input.fastCodeAt(pos + offset);
	}

	public inline function advanceChar(): Int {
		return input.fastCodeAt(pos++);
	}

	public inline function advanceCharDirect(): Int {
		return input.fastCodeAt(++pos);
	}

	public var line:Int = 1;
	public inline function newline() {
		line++;
		return null;
	}

	private static final START:Rule = Str("^");
	private static final START_DIGIT = "[1-9]";
	private static final DIGIT = "[0-9]";
	private static final SEP_DIGIT:Array<Rule> = [Opt([Str("_")]), Str(DIGIT)];
	private static final INT_DIGITS:Array<Rule> = [Str(DIGIT), Star(SEP_DIGIT)];
	private static final INTEGER:Array<Rule> = [Either([Basic([Str(START_DIGIT), Star(SEP_DIGIT)]), Str("0")])];

	private static final HEX_DIGIT = "[0-9a-fA-F]";
	private static final SEP_HEX_DIGIT:Array<Rule> = [Opt([Str("_")]), Str(HEX_DIGIT)];
	private static final HEX_DIGITS:Array<Rule> = [Str(HEX_DIGIT), Star(SEP_HEX_DIGIT)];

	private static final BIN_DIGIT = "[01]";
	private static final SEP_BIN_DIGIT:Array<Rule> = [Opt([Str("_")]), Str(BIN_DIGIT)];
	private static final BIN_DIGITS:Array<Rule> = [Str(BIN_DIGIT), Star(SEP_BIN_DIGIT)];

	private static final INT_SUFFIX_SEP = "[iu]";
	private static final INT_SUFFIX:Array<Rule> = [Opt([Str("_")]), Str(INT_SUFFIX_SEP), Plus(INTEGER)];
	private static final FLOAT_SUFFIX:Array<Rule> = [Opt([Str("_")]), Str("f"), Plus(INTEGER)];

	private static final IDENT:Array<Rule> = [
		Either([
			Basic([
				Star([Str('_')]),
				Str("[a-z]"),
				Star([Str("[_a-zA-Z0-9]")])
			]),
			Plus([Str('_')]),
			Basic([
				Plus([Str('_')]),
				Str("[0-9]"),
				Star([Str("[_a-zA-Z0-9]")])
			])
		])
	];

	private static final IDTYPE:Array<Rule> = [
		Star([Str('_')]),
		Str("[A-Z]"),
		Star([Str("[_a-zA-Z0-9]")])
	];

	@:pure public static inline function re(...a:Rule) {
		return RegexUtils.makeRegexRule(a.toArray());
	}

	private function handleNewline(str:FastStringBuf, ch:Int) {
		switch (ch) {
			case "\r".code:
				var chh = peekChar();
				if(chh == "\n".code) {
					str.addChar(chh);
					pos++;
				}
				newline();
			case "\n".code:
				newline();
		}
	}

	public function parseSingleComment():Token {
		pos += 2; // to skip the //
		var str = new FastStringBuf();
		while (pos < input.length) {
			var ch = advanceChar();
			switch (ch) {
				case "\r".code:
					if(peekChar() == "\n".code)
						pos++;
					break;
				case "\n".code:
					break;
			}
			str.addChar(ch);
		}
		pos -= 2;
		return TCommentLine(str.toString());
	}

	public function parseBlockComment():Token {
		pos += 2; // to skip the /*
		var start = pos;
		var startLine = line;
		var str = new FastStringBuf();
		while (pos < input.length) {
			var ch = advanceChar();
			// hopefully we dont need to check for eof
			handleNewline(str, ch);
			switch (ch) {
				case "*".code:
					if (peekChar() == "/".code) {
						pos -= 1;
						return TComment(str.toString());
					}
			}
			str.addChar(ch);
		}
		throw "Unclosed block comment at line " + startLine;
	}

	public function parseStringDouble():Token {
		pos++; // to skip the "
		var start = pos;
		var startLine = line;
		var str = new FastStringBuf();
		while (pos < input.length) {
			var ch = advanceChar();
			// hopefully we dont need to check for eof
			handleNewline(str, ch);
			switch (ch) {
				case "\\".code:
					var ch = peekChar();
					switch (ch) {
						case "\"".code: str.addChar(ch); pos++; continue;
						case "\\".code: str.addChar(ch); pos++; continue;
					}
				case '"'.code:
					pos--;
					return TConst(CString(StringUtils.unescape(str.toString()), SDoubleQuotes));
			}
			str.addChar(ch);
		}
		throw "Unclosed Double String at line " + startLine;
	}

	public function parseStringSingle():Token {
		pos++; // to skip the '
		var start = pos;
		var startLine = line;
		var str = new FastStringBuf();
		while (pos < input.length) {
			var ch = advanceChar();
			// hopefully we dont need to check for eof
			handleNewline(str, ch);
			switch (ch) {
				case "\\".code:
					var ch = peekChar();
					switch (ch) {
						case "\'".code: str.addChar(ch); pos++; continue;
						case "\\".code: str.addChar(ch); pos++; continue;
						case "$".code: str.addChar(ch); pos++; continue; // escaped $
					}
				case "$".code:
					var ch = peekChar();
					switch (ch) {
						case "$".code: str.addChar(ch); pos++; continue; // escaped $
						case "{".code: pos++; str.flush(); str.addStr("UNSUPPORTED CODESTRING"); continue;//throw "Code String not supported";
					}
				case "'".code:
					pos--;
					return TConst(CString(StringUtils.unescape(str.toString()), SSingleQuotes));
			}
			str.addChar(ch);
		}
		throw "Unclosed Single String at line " + startLine;
	}

	public function parseRegex():Token {
		var headerLength = 2; //"~/".length;
		pos += headerLength; // to skip the ~/
		var start = pos;
		var startLine = line;
		var str = new FastStringBuf();
		while (pos < input.length) {
			var ch = advanceChar();
			// hopefully we dont need to check for eof
			switch (ch) {
				case "\r".code | "\n".code: throw "Unclosed Regex at line " + startLine;
				case "\\".code:
					var ch = peekChar();
					switch (ch) {
						case "/".code: str.addChar(ch); pos++; continue;
						case "r".code: str.addChar("\r".code); pos++; continue;
						case "n".code: str.addChar("\n".code); pos++; continue;
						case "t".code: str.addChar("\t".code); pos++; continue;

						case "\\".code | "$".code | ".".code | "*".code | "+".code | "^".code | "|".code | "{".code | "}".code |
							 "[".code | "]".code | "(".code | ")".code | "?".code | "-".code |
							 '0'.code | '1'.code | '2'.code | '3'.code | '4'.code | '5'.code | '6'.code | '7'.code | '8'.code | '9'.code:
							str.addChar("\\".code);
							str.addChar(ch);
							pos++;
							continue;

						case "w".code | "W".code | "b".code | "B".code | "s".code | "S".code | "d".code | "D".code | "x".code:
							str.addChar("\\".code);
							str.addChar(ch);
							pos++;
						   continue;

						case "u".code | "U".code:
							str.addChar("\\".code);
							str.addChar(ch);
							pos++;
							for(i in 0...4) {
								switch (ch = advanceChar()) {
									case '0'.code | '1'.code | '2'.code | '3'.code | '4'.code | '5'.code | '6'.code | '7'.code | '8'.code | '9'.code |
										 'a'.code | 'b'.code | 'c'.code | 'd'.code | 'e'.code | 'f'.code | 'A'.code | 'B'.code | 'C'.code | 'D'.code | 'E'.code | 'F'.code:
										str.addChar(ch);
									default:
										throw "Invalid Character in Regex at line " + startLine + " Character: " + StringUtils.getEscapedString(peek());
								}
							}
							continue;
						default:
							throw "Invalid Character in Regex at line " + startLine + " Character: " + StringUtils.getEscapedString(peek());
					}
				case '/'.code:
					// TODO: this might be broken
					var options = "";
					while(true) {
						switch ch = advanceChar() {
							case 'g'.code | 'i'.code | 'm'.code | 's'.code | 'u'.code:
								options += String.fromCharCode(ch);
							default:
								if(ch >= 'a'.code && ch <= 'z'.code) {
									throw "Invalid option in Regex at line " + startLine + " Character: " + StringUtils.getEscapedString(String.fromCharCode(ch));
								}
								pos--;
								break;
						}
					}

					pos -= headerLength;
					return TConst(CRegexp(str.toString(), options));
				default:
					str.addChar(ch);
			}
			/*and regexp lexbuf =
				match%sedlex lexbuf with
				| '\\', ('\\' | '$' | '.' | '*' | '+' | '^' | '|' | '{' | '}' | '[' | ']' | '(' | ')' | '?' | '-' | '0'..'9') -> add (lexeme lexbuf); regexp lexbuf
				| '\\', ('w' | 'W' | 'b' | 'B' | 's' | 'S' | 'd' | 'D' | 'x') -> add (lexeme lexbuf); regexp lexbuf
				| '\\', ('u' | 'U'), ('0'..'9' | 'a'..'f' | 'A'..'F'), ('0'..'9' | 'a'..'f' | 'A'..'F'), ('0'..'9' | 'a'..'f' | 'A'..'F'), ('0'..'9' | 'a'..'f' | 'A'..'F') -> add (lexeme lexbuf); regexp lexbuf
				| '\\', Compl '\\' -> error (Invalid_character (Uchar.to_int (lexeme_char lexbuf 0))) (lexeme_end lexbuf - 1)
				| '/' -> regexp_options lexbuf, lexeme_end lexbuf
				| Plus (Compl ('\\' | '/' | '\r' | '\n')) -> store lexbuf; regexp lexbuf
				| _ -> die "" __LOC__*/

		}
		throw "Unclosed Regex at line " + startLine;
	}

	/*function parseCodeString(b:Int):String {
		var start = pos;
		var startLine = line;
		var str = "";
		inline function store(s:String) { str += s; }
		while (pos < input.length) {
			var ch = advance();
			// hopefully we dont need to check for eof
			switch (ch) {
				case "\r": if(peek() == "\n") store(advance()); newline(); case "\n": newline();
				case "{":
					store(ch);
					store(parseCodeString(b+1));
				case "/":
					store(ch);
					store(parseCodeString(b+1));
				case "}":
					store(ch);
					if(b > 0)
						store(parseCodeString(b+1));
					else
						return str;
				case '"':
					store(ch);
					store(parseStringDouble());
					store(ch);

					*/

	/*
	and code_string lexbuf open_braces =
	match%sedlex lexbuf with
	| eof -> raise Exit
	| '\n' | '\r' | "\r\n" -> newline lexbuf; store lexbuf; code_string lexbuf open_braces
	| '{' -> store lexbuf; code_string lexbuf (open_braces + 1)
	| '/' -> store lexbuf; code_string lexbuf open_braces
	| '}' ->
		store lexbuf;
		if open_braces > 0 then code_string lexbuf (open_braces - 1)
	| '"' ->
		add "\"";
		let pmin = lexeme_start lexbuf in
		(try ignore(string lexbuf) with Exit -> error Unterminated_string pmin);
		add "\"";
		code_string lexbuf open_braces
	| "'" ->
		add "'";
		let pmin = lexeme_start lexbuf in
		(try ignore(string2 lexbuf) with Exit -> error Unterminated_string pmin);
		add "'";
		code_string lexbuf open_braces
	| "/*" ->
		let pmin = lexeme_start lexbuf in
		let save = contents() in
		reset();
		(try ignore(comment lexbuf) with Exit -> error Unclosed_comment pmin);
		reset();
		Buffer.add_string buf save;
		code_string lexbuf open_braces
	| "//", Star (Compl ('\n' | '\r')) -> store lexbuf; code_string lexbuf open_braces
	| Plus (Compl ('/' | '"' | '\'' | '{' | '}' | '\n' | '\r')) -> store lexbuf; code_string lexbuf open_braces
	| _ -> die "" __LOC__
	*/

	@:pure public static function splitSuffix(s: String, isInt: Bool): Array<String> {
		var len = s.length;

		function loop(i: Int, pivot: Null<Int>): Array<String> {
			if (i == len) {
				if(pivot == null)
					return [s, null];

				var literalLength = if (s.fastCodeAt(pivot - 1) == '_'.code) pivot - 1 else pivot;
				var literal = s.substr(0, literalLength);
				var suffix = s.substr(pivot, len - pivot);
				return [literal, suffix];
			} else {
				var c = s.fastCodeAt(i);
				switch (c) {
					case 'i'.code, 'u'.code:
						return loop(i + 1, i);
					case 'f'.code if(!isInt):
						return loop(i + 1, i);
				}
				return loop(i + 1, pivot);
			}
		}

		return loop(0, null);
	}

	@:pure function split_int_suffix(s: String): Token {
		var suffixInfo = splitSuffix(s, true);
		return TConst(CInt(suffixInfo[0], suffixInfo[1]));
	}

	@:pure function split_float_suffix(s: String): Token {
		var suffixInfo = splitSuffix(s, false);
		return TConst(CFloat(suffixInfo[0], suffixInfo[1]));
	}

	public var rules(get, null):Array<Array<Dynamic>> = null;
	function get_rules():Array<Array<Dynamic>> {
		if(rules == null) rules = [
			// EOF is handled outside
			//[" ", () -> null],
			//["\t", () -> null],
			["\r\n", () -> newline()],
			["\n", () -> newline()],
			["\r", () -> newline()],
			[re(START, Str("0x"), Basic(HEX_DIGITS), Opt(INT_SUFFIX)), (s) -> split_int_suffix(s)],
			[re(START, Str("0b"), Basic(BIN_DIGITS), Opt(INT_SUFFIX)), (s) -> split_int_suffix(s)],
			[re(START, Basic(INTEGER), Str("\\.\\.\\.")), (s) -> TIntInterval(s.substr(0, s.length - 3))], // Int Interval
			[re(START, Basic(INTEGER), Str("\\."), Star(INT_DIGITS), Str("[eE]"), Opt([Str("[+\\-]")]), Plus(INT_DIGITS), Opt(FLOAT_SUFFIX)), (s) -> split_float_suffix(s)], // Normal haxe was DIGITS after dot
			[re(START, Basic(INTEGER), Str("\\."), Plus(INT_DIGITS), Opt(FLOAT_SUFFIX)), (s) -> split_float_suffix(s)],
			[re(START, Basic(INTEGER), Str("[eE]"), Opt([Str("[+\\-]")]), Plus(INT_DIGITS), Opt(FLOAT_SUFFIX)), (s) -> split_float_suffix(s)],
			[re(START, Basic(INTEGER), Opt(INT_SUFFIX)), (s) -> split_int_suffix(s)],
			[re(START, Basic(INTEGER), Basic(FLOAT_SUFFIX)), (s) -> split_float_suffix(s)],
			[re(START, Str("\\."), Plus(INT_DIGITS), Opt(FLOAT_SUFFIX)), (s) -> split_float_suffix(s)],

			["//", () -> parseSingleComment()], // Single line comment
			["/*", () -> parseBlockComment()], // TODO: maybe make this use a regex instead

			["~/", () -> parseRegex()],

			["++", () -> TUnop(UIncrement)],
			["--", () -> TUnop(UDecrement)],
			["~", () -> TUnop(UNegBits)],
			["%=", () -> TBinop(BOpAssignOp(BOpMod))],
			["&=", () -> TBinop(BOpAssignOp(BOpAnd))],
			["|=", () -> TBinop(BOpAssignOp(BOpOr))],
			["^=", () -> TBinop(BOpAssignOp(BOpXor))],
			["+=", () -> TBinop(BOpAssignOp(BOpAdd))],
			["-=", () -> TBinop(BOpAssignOp(BOpSub))],
			["*=", () -> TBinop(BOpAssignOp(BOpMult))],
			["/=", () -> TBinop(BOpAssignOp(BOpDiv))],
			["<<=", () -> TBinop(BOpAssignOp(BOpShl))],
			["||=", () -> TBinop(BOpAssignOp(BOpBoolOr))],
			["&&=", () -> TBinop(BOpAssignOp(BOpBoolAnd))],
			["??"+"=", () -> TBinop(BOpAssignOp(BOpNullCoal))],
			// [">>=", () -> TBinop(BOpAssignOp(BOpShr))], // dont uncomment these, they are handled in the parser
			// [">>>=", () -> TBinop(BOpAssignOp(BOpUShr))],
			// [">=", () -> TBinop(BOpGte)],
			["==", () -> TBinop(BOpEq)],
			["!=", () -> TBinop(BOpNotEq)],
			["<=", () -> TBinop(BOpLte)],
			["&&", () -> TBinop(BOpBoolAnd)],
			["||", () -> TBinop(BOpBoolOr)],
			["<<", () -> TBinop(BOpShl)],
			["->", () -> TArrow],
			["...", () -> TSpread],
			["=>", () -> TBinop(BOpArrow)],
			["!", () -> TUnop(UNot)],
			["<", () -> TBinop(BOpLt)],
			[">", () -> TBinop(BOpGt)],
			[";", () -> TSemicolon],
			[":", () -> TDblDot],
			[",", () -> TComma],
			[".", () -> TDot],
			["?.", () -> TQuestionDot],
			["%", () -> TBinop(BOpMod)],
			["&", () -> TBinop(BOpAnd)],
			["|", () -> TBinop(BOpOr)],
			["^", () -> TBinop(BOpXor)],
			["+", () -> TBinop(BOpAdd)],
			["*", () -> TBinop(BOpMult)],
			["/", () -> TBinop(BOpDiv)],
			["-", () -> TBinop(BOpSub)],
			["=", () -> TBinop(BOpAssign)],
			["[", () -> TBkOpen],
			["]", () -> TBkClose],
			["{", () -> TBrOpen],
			["}", () -> TBrClose],
			["(", () -> TPOpen],
			[")", () -> TPClose],
			["??", () -> TBinop(BOpNullCoal)],
			["?", () -> TQuestion],
			["@", () -> TAt],

			["\"", () -> parseStringDouble()],
			["'", () -> parseStringSingle()],

			// typedecl
			["package", () -> TKwd(KPackage)],
			["import", () -> TKwd(KImport)],
			["using", () -> TKwd(KUsing)],
			["class", () -> TKwd(KClass)],
			["interface", () -> TKwd(KInterface)],
			["enum", () -> TKwd(KEnum)],
			["abstract", () -> TKwd(KAbstract)],
			["typedef", () -> TKwd(KTypedef)],
			// relations
			["extends", () -> TKwd(KExtends)],
			["implements", () -> TKwd(KImplements)],
			// modifier
			["extern", () -> TKwd(KExtern)],
			["static", () -> TKwd(KStatic)],
			["public", () -> TKwd(KPublic)],
			["private", () -> TKwd(KPrivate)],
			["override", () -> TKwd(KOverride)],
			["dynamic", () -> TKwd(KDynamic)],
			["inline", () -> TKwd(KInline)],
			["macro", () -> TKwd(KMacro)],
			["final", () -> TKwd(KFinal)],
			["operator", () -> TKwd(KOperator)],
			["overload", () -> TKwd(KOverload)],
			// fields
			["function", () -> TKwd(KFunction)],
			["var", () -> TKwd(KVar)],
			// values
			["null", () -> TKwd(KNull)],
			["true", () -> TKwd(KTrue)],
			["false", () -> TKwd(KFalse)],
			["this", () -> TKwd(KThis)],
			// expr
			["if", () -> TKwd(KIf)],
			["else", () -> TKwd(KElse)],
			["while", () -> TKwd(KWhile)],
			["do", () -> TKwd(KDo)],
			["for", () -> TKwd(KFor)],
			["break", () -> TKwd(KBreak)],
			["continue", () -> TKwd(KContinue)],
			["return", () -> TKwd(KReturn)],
			["switch", () -> TKwd(KSwitch)],
			["case", () -> TKwd(KCase)],
			["default", () -> TKwd(KDefault)],
			["throw", () -> TKwd(KThrow)],
			["try", () -> TKwd(KTry)],
			["catch", () -> TKwd(KCatch)],
			["untyped", () -> TKwd(KUntyped)],
			["new", () -> TKwd(KNew)],
			["in", () -> TKwd(KIn)],
			["cast", () -> TKwd(KCast)],

			[re(START, Basic(IDENT)), (s) -> TConst(CIdent(s))],
			[re(START, Basic(IDTYPE)), (s) -> TConst(CIdent(s))],

			[re(START, Str("\\#"), Basic(IDENT)), (s) -> TSharp(s.substr(1))],
			[re(START, Str("\\$"), Star([Str("[_a-zA-Z0-9]")])), (s) -> TDollar(s.substr(1))],
		];
		return rules;
	}

	private function processToken(tk:Token):Token {
		if(tk == null)
			return null;
		var tkpos = AstUtils.nullPos;
		return switch(tk) {
			case TSharp("if"):
				processToken(enterMacro(true, tkpos));
			case TSharp("else"):
				processToken(skipTokens(tkpos, false));
			case TSharp("elseif"):
				processToken(skipTokens(tkpos, false));
			case TSharp("end"):
				nextToken();
			case TSharp("error"):
				throw switch(getToken()) {
					case TConst(CString(s, _)): "Error: " + s;
					default: "Error: Expected String";
				}
			case TSharp("line"):
				switch(nextToken()) {
					case TConst(CInt(s, _)):
						var newLine:Null<Int> = try {
							FastUtils.parseIntLimit(s);
						} catch(e:Dynamic) null;

						if(newLine == null)
							throw "Could not parse ridiculous line number " + s;
						line = newLine;
					default:
						throw "Expected Int";
				}
				nextToken();
			case TSharp(s):
				trace(StringUtils.getEscapedString(StringUtils.getLine(input, pos-1)));
				throw "Unknown Preprocessor Directive: " + s;
			default:
				tk;
		}
	}

	public static var BUFFER_SIZE = 128; // Use lower values for performance, if it doesnt find a match it will try again with a larger buffer

	public function getToken():Token {
		var ch = peekChar();
		while(ch == " ".code || ch == "\t".code)
			ch = advanceCharDirect();
		if(StringTools.isEof(ch)) return TEof;

		switch(parseToken(BUFFER_SIZE)) {
			case Some(t): return t;
			default:
		}
		switch(parseToken()) { // Try again with a entire buffer
			case Some(t): return t;
			default:
		}

		throw "Invalid Character " + StringUtils.getEscapedString(input.substr(pos, 55));
	}

	public inline function nextToken():Token {
		return processToken(getToken());
	}

	// TODO: Use class for rules to make it more memory efficient
	public function parseToken(size:Null<Int> = null):Option<Token> {
		for(rule in rules) {
			var rule_case = rule[0];

			if(rule_case is EReg) {
				var rule_case:EReg = cast rule_case;
				var match = input.substr(pos, size);
				if(rule_case.match(match)) { // Might be better to use matchSub
					var rule_func:(String) -> Token = rule[1];
					var match = rule_case.matched(0);
					var token = rule_func(match);
					pos += match.length;
					return Some(token);
				}
			} else {
				var rule_case:String = cast rule_case;
				var match = input.substr(pos, rule_case.length);
				if(rule_case == match) {
					var rule_func:(String) -> Token = rule[1];
					var token = rule_func(match);
					pos += match.length;
					return Some(token);
				}
			}
		}
		return None;
	}

	// -- PREPROCESSOR --

	function enterMacro(is_if:Bool, pos:Pos) {
		var v = parseMacroCond();
		var tk:Option<Token> = v[0];
		var e:Expr = v[1];
		//if(is_if) {
		//	conds.condIf(e);
		//} else {
		//	conds.condElse(tk, e);
		//}

		var tk = switch(tk) {
			case None: getToken();
			case Some(tk): tk;
		}

		return if(isTrue(eval(e))) {
			tk;
		} else {
			//dbc.openDeadBlock(pos, e.pos);
			skipTokensLoop(pos, true, tk);
		}


		/*let tk, e = parse_macro_cond sraw in
		(if is_if then conds#cond_if e else conds#cond_elseif e p);
		let tk = (match tk with None -> Lexer.token code | Some tk -> tk) in
		if is_true (eval ctx e) then begin
			tk
		end else begin
			dbc#open_dead_block (pos e);
			skip_tokens_loop p true tk
		end*/
	}

	function skipTokens(p:Pos, test:Bool) {
		return skipTokensLoop(p, test, getToken());
	}

	function parseMacroCond():Tuple<Option<Token>, Expr> {
		var pos = AstUtils.nullPos;
		var parsing_macro_cond = false;
		try {
			var tk = getToken();
			var cond = switch(tk) {
				case TConst(CIdent(t)):
					Tuple.make(None, parseMacroIdent(t, pos));
				case TConst(CString(s, qs)):
					Tuple.make(None, mk(EConst(CString(s, qs)), pos));
				case TConst(CInt(i, s)):
					Tuple.make(None, mk(EConst(CInt(AstUtils.parseInt(i), s)), pos));
				case TConst(CFloat(f, s)):
					Tuple.make(None, mk(EConst(CFloat(AstUtils.parseFloat(f), s)), pos));
				case TKwd(keyword):
					Tuple.make(None, parseMacroIdent(Printer.getKwdString(keyword), pos));
				case TUnop(op):
					Tuple.make(Some(tk), Parser.makeUnop(op, parseMacroCond()[1], pos));
				case TPOpen:
					var e = Parser.giveExpr(this.stream);
					//var tk = nextToken();
					//if(tk != TPClose) {
					//	throw "Expected ')'";
					//}
					Tuple.make(None, mk(EParenthesis(validateMacroCond(e)), AstUtils.punion(pos, pos)));
				default: throw "Invalid conditional expression at " + pos.file + ":" + pos.max;
			}
			parsing_macro_cond = false;
			return cond;
		} catch(e:Dynamic) {
			parsing_macro_cond = false;
			throw e;
		}
	}

	function validateMacroCond(e: Expr): Expr {
		switch (e.expr) {
			case EConst(CIdent(_)), EConst(CString(_)), EConst(CInt(_, _)), EConst(CFloat(_, _)):
				return e;

			case EUnop(op, p, e1):
				return mk(EUnop(op, p, validateMacroCond(e1)), e.pos);

			case EBinop(op, e1, e2):
				return mk(EBinop(op, validateMacroCond(e1), validateMacroCond(e2)), e.pos);

			case EParenthesis(e1):
				return mk(EParenthesis(validateMacroCond(e1)), e.pos);

			case EField(e1, name, efk):
				return mk(EField(validateMacroCond(e1), name, efk), e.pos);

			case ECall(e1, args):
				switch (e1.expr) {
					case EConst(CIdent(_)):
						return mk(ECall(e1, args.map(arg -> validateMacroCond(arg))), e.pos);
					default:
				}

			default:
		}
		throw "Invalid conditional expression at " + e.pos.file + ":" + e.pos.max;
	}

	function parseMacroIdent(t:String, p:Pos):Expr {
		if(t == "display") {
			// if t = "display" then Hashtbl.replace special_identifier_files (Path.UniqueKey.create p.pfile) t;
		}
		return mk(EConst(CIdent(t)), p);
	}

	function skipTokensLoop(p:Pos, test:Bool, tk:Token) {
		var tkpos = AstUtils.nullPos;
		if(tk == null)
			return skipTokens(tkpos, test);

		return switch(tk) {
			case TSharp("end"):
				//conds.condEnd(tkpos);
				//dbc.closeDeadBlock(tkpos);
				getToken();
			case TSharp("elseif") if(!test):
				//dbc.closeDeadBlock(tkpos);
				//conds.condElseif(tkpos);
				skipTokens(tkpos, test);

			case TSharp("else") if(!test):
				skipTokens(tkpos, test);

			case TSharp("elseif"):
				enterMacro(false, tkpos);

			case TSharp("else"):
				getToken();

			case TSharp("if"):
				//var e = parseMacroCond();
				//conds.condIf(e);
				//dbc.openDeadBlock(tkpos);
				skipTokensLoop(tkpos, false, skipTokens(tkpos, false));

			case TSharp("error") | TSharp("line"):
				skipTokens(tkpos, test);

			case TSharp(s):
				throw "Unknown Preprocessor Directive: " + s;

			case TEof:
				throw "Unclosed conditional";

			default:
				skipTokens(tkpos, test);
		}
		/*match fst tk with


		| Sharp ("error" | "line") ->
			skip_tokens p test
		| Sharp s ->
			sharp_error s (pos tk)
		| Eof ->
			preprocessor_error UnclosedConditional p tk
		| _ ->
			skip_tokens p test*/

			/*
					| Sharp "end" ->
			conds#cond_end (snd tk);
			dbc#close_dead_block (pos tk);
			Lexer.token code
		| Sharp "elseif" when not test ->
			dbc#close_dead_block (pos tk);
			let _,(e,pe) = parse_macro_cond sraw in
			conds#cond_elseif (e,pe) (snd tk);
			dbc#open_dead_block pe;
			skip_tokens p test
		| Sharp "else" when not test ->
			conds#cond_else (snd tk);
			dbc#close_dead_block (pos tk);
			dbc#open_dead_block (pos tk);
			skip_tokens p test
		| Sharp "else" ->
			conds#cond_else (snd tk);
			dbc#close_dead_block (pos tk);
			Lexer.token code
		| Sharp "elseif" ->
			dbc#close_dead_block (pos tk);
			enter_macro false (snd tk)
			| Sharp "if" ->
			let _,e = parse_macro_cond sraw in
			conds#cond_if e;
			dbc#open_dead_block (pos e);
			let tk = skip_tokens p false in
			skip_tokens_loop p test tk
			*/
	}

	private function parseVersion(s:String, p:Pos):SmallType {
		var version = VersionUtils.tryParseVersion(s);
		return switch (version) {
			case Ok(v): TVersion(v);
			case Err(e): throw e;
		}
	}

	private function isTrue(v:SmallType):Bool {
		return switch (v) {
			case TBool(false), TNull: false;
			case TFloat(f) if (f == 0): false;
			default: true;
		}
	}

	private static function float_of_string(s:String):Float {
		var v:Null<Float> = Std.parseFloat(s);
		if(v == null || Math.isNaN(v)) throw "Invalid float";
		return v;
	}

	private function evalBinopExprs(e1:Expr, e2:Expr):Array<SmallType> {
		var v1 = eval(e1);
		var v2 = eval(e2);
		return switch ([v1, v2]) {
			case [TString(s1), TFloat(_)]:
				try
					[TFloat(float_of_string(s1)), v2]
				catch (e:Dynamic)
					[v1, v2];
			case [TFloat(_), TString(s2)]:
				try
					[v1, TFloat(float_of_string(s2))]
				catch (e:Dynamic)
					[v1, v2];
			case [TVersion(_), TString(s)]: [v1, parseVersion(s, e2.pos)];
			case [TString(s), TVersion(_)]: [parseVersion(s, e1.pos), v1];
			default: [v1, v2];
		}
	}

	private function cmp(v1:SmallType, v2:SmallType, _cmp:(Dynamic, Dynamic) -> Int):Int {
		return switch([v1, v2]) {
			case [TNull, _] | [_, TNull]: throw Errors.Exit;
			case [TFloat(a), TFloat(b)]: _cmp(a, b);
			case [TString(a), TString(b)]: _cmp(a, b);
			case [TBool(a), TBool(b)]: _cmp(a, b);
			case [TVersion(a), TVersion(b)]: VersionUtils.compare(a, b);
			case [TString(_), TFloat(_)]: throw "Invalid comparison";
			case [TFloat(_), TString(_)]: throw "Invalid comparison";
			case [TVersion(_), _]: throw "Invalid comparison";
			case [_, TVersion(_)]: throw "Invalid comparison";
			default: throw Errors.Exit;
		}
	}

	private function eval(expr:Expr):SmallType {
		var ctx:DefineContext = defines;
		switch (expr.expr) {
			case EConst(CIdent(i)):
				if(ctx.isDefined(i)) {
					var value = ctx.defined(i);
					if(value == null) return TNull;
					if((value is String)) {
						//var version = tryParseVersion(value);
						//return switch (version) {
						//	case Ok(v): TVersion(v);
						//	case Err(_): TString(value);
						//}
						return TString(value);
					}

					try {
						return TFloat(float_of_string(value));
					} catch (e:Dynamic) {
						return TString(value);
					}
				} else {
					return TNull;
				}
			case EConst(CString(s, _)):
				return TString(s);
			case EConst(CInt(i, _)):
				return TFloat(i);
			case EConst(CFloat(f, _)):
				return TFloat(f);
			case ECall(_.expr => EConst(CIdent("version")), [arg]):
				switch (arg.expr) {
					case EConst(CString(s, _)):
						return parseVersion(s, arg.pos);
					default:
						throw "Invalid version argument at " + arg.pos.file + ":" + arg.pos.max;
				}
			case EBinop(BOpBoolAnd, e1, e2):
				return TBool(isTrue(eval(e1)) && isTrue(eval(e2)));
			case EBinop(BOpBoolOr, e1, e2):
				return TBool(isTrue(eval(e1)) || isTrue(eval(e2)));
			case EUnop(UNot, _, e):
				return TBool(!isTrue(eval(e)));
			case EParenthesis(e):
				return eval(e);
			case EBinop(op, e1, e2):
				var v = evalBinopExprs(e1, e2);
				var v1 = v[0];
				var v2 = v[1];

				function compare(f:(Dynamic, Dynamic) -> Int):SmallType {
					return try
						TBool(cmp(v1, v2, f) == 0)
					catch (e:Errors) {
						switch (e) {
							case Exit: TBool(false);
							default: throw e;
						}
					}
				}

				inline function b2ic(b:Bool):Int {
					return b ? 0 : -1;
				}

				return switch (op) {
					case BOpEq | BOpNotEq:
						var cc = (a, b) -> b2ic(a == b);
						if(op == BOpNotEq)
							TBool(!isTrue(compare(cc)));
						else
							compare(cc);
					case BOpGt: compare((a, b) -> b2ic(a > b));
					case BOpGte: compare((a, b) -> b2ic(a >= b));
					case BOpLt: compare((a, b) -> b2ic(a < b));
					case BOpLte: compare((a, b) -> b2ic(a <= b));
					default: throw "Unknown operator " + op;
				}
			case EField(_, _, _):
				try {
					var i = ExprUtils.fieldToList(expr).join(".");
					trace(i);

					if(ctx.isDefined(i)) {
						var value = ctx.defined(i);
						if(value == null) return TNull;
						if((value is String)) {
							return TString(value);
						}
					} else {
						return TNull;
					}
				} catch (e:Errors) {
					switch (e) {
						case Exit: throw "Invalid condition expression at " + expr.pos.file + ":" + expr.pos.max;
						default: throw e;
					}
				}
			default:
				throw "Invalid condition expression at " + expr.pos.file + ":" + expr.pos.max;
		}
		return null;
	}

	@:pure public function mk(e : ExprDef, ?pos : Pos = null) : Expr {
		if(pos == null)
			pos = AstUtils.nullPos;
		return { expr : e, pos : pos };
	}
}
