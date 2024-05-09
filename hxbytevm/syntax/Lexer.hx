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
package hxbytevm.syntax;

// Copyright since a lot of this code is from https://github.com/HaxeFoundation/haxe/blob/development/src/syntax/lexer.ml

import hxbytevm.utils.Errors;
import hxbytevm.utils.ExprUtils;
import hxbytevm.utils.VersionUtils;
import hxbytevm.utils.FastUtils;
import hxbytevm.core.Ast;
import hxbytevm.utils.RegexUtils;
import hxbytevm.utils.StringUtils;
import hxbytevm.utils.FastStringBuf;
import hxbytevm.utils.macros.DefinesMacro;
using hxbytevm.utils.HelperUtils;

using StringTools;

// TODO: Add string interpolation
// TODO: Add string unescaping in StringUtils.unescape

enum Token {
	TEof;
	TConst(const:TConstant);
	TKwd(keyword:Keyword);
	TComment(comment:String);
	TCommentLine(commentline:String);
	TBinop(op:Binop);
	TUnop(unop:Unop);
	TSemicolon;
	TComma;
	TBrOpen;
	TBrClose;
	TBkOpen;
	TBkClose;
	TPOpen;
	TPClose;
	TDot;
	TDblDot; // Should we name this TColon? aka :
	TQuestionDot;
	TArrow;
	TIntInterval(string:String);
	TSharp(string:String); // preprocessor directive
	TQuestion;
	TAt;
	TDollar(string:String);
	TSpread;
}

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


/**
 * A lexer and preprocessor for the Haxe language.
**/
class Lexer {
	public var defines:DefineContext;

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
	}

	public function loadDefaultDefines():Map<String, Dynamic> {
		return DefinesMacro.getDefines();
	}

	public var pos:Int = 0;
	public var input:String;
	public static function parse(input:String):Array<Token> {
		if (input == null || input.length <= 0) return [TEof];
		var lexer = new Lexer();
		lexer.load(input);
		return lexer.tokenize();
	}

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

	public function parseSingleComment(s:String):Token {
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

	public function parseBlockComment(s:String):Token {
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
						case "{".code: pos++; str.flush(); str.add("UNSUPPORTED CODESTRING"); continue;//throw "Code String not supported";
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

	public var rules:Array<Array<Dynamic>> = null;

	public function tokenize():Array<Token> {
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

			["//", (s) -> parseSingleComment(s)], // Single line comment
			["/*", (s) -> parseBlockComment(s)], // TODO: maybe make this use a regex instead

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

			[re(START, Str("\\#"), Basic(IDENT)), (s) -> TSharp(s)],
			[re(START, Str("\\$"), Star([Str("[_a-zA-Z0-9]")])), (s) -> TDollar(s)],

			[re(START, Basic(IDENT)), (s) -> TConst(CIdent(s))],
			[re(START, Basic(IDTYPE)), (s) -> TConst(CIdent(s))],
		];

		var ch = peekChar();
		if(ch == 0xfeff) { // remove byte order mark
			advanceChar();
		}
		if(ch == "#".code && peekChar(1) == "!".code) {
			while(ch != "\n".code && ch != "\r".code) {
				ch = advanceCharDirect();
			}
		}

		var lastToken:Token = null;

		var tokens:Array<Token> = [];
		while (lastToken != TEof) {
			lastToken = getToken();

			switch(lastToken) {
				case TSharp("error"):
					throw switch(getToken()) {
						case TConst(CString(s, _)): "Error: " + s;
						default: "Error: Expected String";
					}
				case TSharp("line"):
					switch(getToken()) {
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
				case TSharp(s):
					throw "Unknown Preprocessor Directive: " + s;
				default:
					tokens.push(lastToken);
			}

			if(StringTools.isEof(peekChar())) {
				tokens.push(TEof);
				break;
			}
		}

		return tokens;
	}

	public static var BUFFER_SIZE = 128; // Use lower values for performance, if it doesnt find a match it will try again with a larger buffer

	private function getToken():Token {
		var ch = peekChar();
		while(ch == " ".code || ch == "\t".code)
			ch = advanceCharDirect();
		if(StringTools.isEof(ch)) return TEof;

		var t = parseToken(BUFFER_SIZE);
		if(t != null) return t;
		var t = parseToken(); // Try again with a entire buffer
		if(t != null) return t;

		throw "Invalid Character " + StringUtils.getEscapedString(input.substr(pos, 55));
	}

	// TODO: Use class for rules to make it more memory efficient
	public function parseToken(size:Null<Int> = null):Token {
		for(rule in rules) {
			var rule_case = rule[0];

			if(rule_case is EReg) {
				var rule_case:EReg = cast rule_case;
				if(rule_case.match(input.substr(pos, size))) {
					var rule_func:(String) -> Token = rule[1];
					var match = rule_case.matched(0);
					var token = rule_func(match);
					pos += match.length;
					return token;
				}
			} else {
				var rule_case:String = cast rule_case;
				var match = input.substr(pos, rule_case.length);
				if(rule_case == match) {
					var rule_func:(String) -> Token = rule[1];
					var token = rule_func(match);
					pos += match.length;
					return token;
				}
			}
		}
		return null;
	}

	// -- PREPROCESSOR --

	function enter_macro(is_if:Bool, token:Token):Void {
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

	function skip_tokens_loop(p:Token, test:Bool, tk:Token) {
		while(true) {
			tk = getToken();
			switch(tk) {
				case TSharp("end"):
					break;
				case TSharp("elseif"):
					// TODO: Evaluate the conditional

				default:
			}
		}
		/*match fst tk with
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
		| Sharp ("error" | "line") ->
			skip_tokens p test
		| Sharp s ->
			sharp_error s (pos tk)
		| Eof ->
			preprocessor_error UnclosedConditional p tk
		| _ ->
			skip_tokens p test*/
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
}


/*
and process_token tk =
		match fst tk with
		| Comment s ->
			(* if encloses_resume (pos tk) then syntax_completion SCComment (pos tk); *)
			let l = String.length s in
			if l > 0 && s.[0] = '*' then last_doc := Some (String.sub s 1 (l - (if l > 1 && s.[l-1] = '*' then 2 else 1)), (snd tk).pmin);
			let tk = next_token() in
			tk
		| CommentLine s ->
			if !in_display_file then begin
				let p = pos tk in
				(* Completion at the / should not pick up the comment (issue #9133) *)
				let p = if is_completion() then {p with pmin = p.pmin + 1} else p in
				(* The > 0 check is to deal with the special case of line comments at the beginning of the file (issue #10322) *)
				if display_position#enclosed_in p && p.pmin > 0 then syntax_completion SCComment None (pos tk);
			end;
			next_token()
		| Sharp "end" ->
			conds#cond_end (snd tk);
			next_token()
		| Sharp "elseif" ->
			let _,(e,pe) = parse_macro_cond sraw in
			conds#cond_elseif (e,pe) (snd tk);
			dbc#open_dead_block pe;
			let tk = skip_tokens (pos tk) false in
			process_token tk
		| Sharp "else" ->
			conds#cond_else (snd tk);
			dbc#open_dead_block (pos tk);
			let tk = skip_tokens (pos tk) false in
			process_token tk
		| Sharp "if" ->
			process_token (enter_macro true (snd tk))
		| Sharp "error" ->
			(match Lexer.token code with
			| (Const (String(s,_)),p) -> error (Custom s) p
			| _ -> error Unimplemented (snd tk))
		| Sharp "line" ->
			let line = (match next_token() with
				| (Const (Int (s, _)),p) -> (try int_of_string s with _ -> error (Custom ("Could not parse ridiculous line number " ^ s)) p)
				| (t,p) -> error (Unexpected t) p
			) in
			!(Lexer.cur).Lexer.lline <- line - 1;
			next_token();
		| Sharp s ->
			sharp_error s (pos tk)
		| _ ->
			tk

	and enter_macro is_if p =
		let tk, e = parse_macro_cond sraw in
		(if is_if then conds#cond_if e else conds#cond_elseif e p);
		let tk = (match tk with None -> Lexer.token code | Some tk -> tk) in
		if is_true (eval ctx e) then begin
			tk
		end else begin
			dbc#open_dead_block (pos e);
			skip_tokens_loop p true tk
		end

	and skip_tokens_loop p test tk =
		match fst tk with
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
		| Sharp ("error" | "line") ->
			skip_tokens p test
		| Sharp s ->
			sharp_error s (pos tk)
		| Eof ->
			preprocessor_error UnclosedConditional p tk
		| _ ->
			skip_tokens p test

	and skip_tokens p test = skip_tokens_loop p test (Lexer.token code)
	*/

class ConditionHandler {
	var conditionalExpressions:Array<Expr> = [];
	var conditionalStack:Array<{e:Expr, elseIf:Bool}> = [];
	var depths:Array<Int> = [];

	public function new() {
		conditionalExpressions = [];
		conditionalStack = [];
		depths = [];
	}

	private function mk(e:ExprDef, ?p:Pos = null):Expr {
		if(p == null) {
			trace("Possible missing position");
			p = AstUtils.nullPos;
		}
		return { expr: e, pos: p };
	}

	private function maybeParent(allowAnd:Bool, e:Expr):Expr {
		return switch(e.expr) {
			case EBinop(BOpBoolAnd, _, _) if(allowAnd): e;
			case EBinop(_, _, _): mk(EParenthesis(e), e.pos);
			default: e;
		}
	}

	private function negate(e:Expr):Expr {
		return switch(e.expr) {
			case EUnop(UNot, UFPrefix, e1): e1;
			case EBinop(BOpBoolAnd, e1, e2): mk(EBinop(BOpBoolOr, negate(e1), negate(e2)), e.pos);
			case EBinop(BOpBoolOr, e1, e2): mk(EBinop(BOpBoolAnd, negate(e1), negate(e2)), e.pos);
			default: mk(EUnop(UNot, UFPrefix, e), e.pos);
		}
	}

	private function conjoin(lhs:Expr, rhs:Expr):Expr {
		var lhs = maybeParent(true, lhs);
		var rhs = maybeParent(true, rhs);
		return mk(EBinop(BOpBoolAnd, lhs, rhs), AstUtils.punion(lhs.pos, rhs.pos));
	}
	private function condIfPriv(e:Expr) {
		conditionalExpressions.push(e);
		conditionalStack.push({e: e, elseIf: false});
		// depths <- 1 :: depths
	}

	public function condIf(e:Expr) {
		condIfPriv(e);
		depths.insert(0, 1);
		// depths <- 1 :: depths
	}

	public function condElse(p:Pos) {
		if(conditionalStack.length == 0) {
			throw "Internal Error: Invalid Else at " + p.file + ":" + p.max;
		}
		var top = conditionalStack.last();
		if(top.elseIf) {
			throw "Internal Error: Invalid Else at " + p.file + ":" + p.max;
		}

		conditionalStack.insert(0, {e: negate(top.e), elseIf: true});
		//	//match conditional_stack with
		//	//| (_,true) :: _ ->
		//	//	error (Preprocessor_error InvalidElse) p
		//	//| (e,false) :: el ->
		//	//	conditional_stack <- (self#negate e,true) :: el
		//	//| [] ->
		//	//	error (Preprocessor_error InvalidElse) p
	}

	public function condElseif(e:Expr) {
		condElse(e.pos);
		condIfPriv(e);
		if(depths.length == 0) {
			throw "Preprocessor error: Invalid else if";
		}

		depths.insert(0, depths.first() + 1);
		// | depth :: depths' ->
		//	depths <- (depth + 1) :: depths'
	}

	public function condEnd(p:Pos) {
		function recLoop(d:Int, el:Array<{e:Expr, elseIf:Bool}>) {
			return if(d == 0) {
				el;
			} else {
				recLoop(d - 1, el.slice(1));
			}
		}
		if(depths.length == 0) {
			throw "Preprocessor error: Invalid end";
		}

		//var depth = depths.first();
		//depths = depths.slice(1);
		// this is very likely wrong
		var depth = depths.shift();
		conditionalStack = recLoop(depth, conditionalStack);

		/*method cond_end (p : pos) =
		let rec loop d el =
			if d = 0 then el
			else loop (d - 1) (List.tl el)
		in
		match depths with
			| [] ->
				error (Preprocessor_error InvalidEnd) p
			| depth :: depths' ->
				conditional_stack <- loop depth conditional_stack;
				depths <- depths'
*/
	}

	public function getCurrentCondition():Expr {
		if(conditionalStack.length == 0) {
			return mk(EConst(CIdent("true")), AstUtils.nullPos);
		}

		// I have no fucking clue what fold_left means here, help

		return switch(conditionalStack) {
			default: mk(EConst(CIdent("true")), AstUtils.nullPos);
			//| (e,_) :: el ->
			//	List.fold_left self#conjoin e (List.map fst el)
			//| [] ->
			//	(EConst (Ident "true"),null_pos)
		}
	}

	public function getConditions():Array<Expr> {
		return conditionalExpressions;
	}
}

	/*class condition_handler = object(self)
	val mutable conditional_expressions = []
	val mutable conditional_stack = []
	val mutable depths = []

	method private maybe_parent allow_and e = match fst e with
		| EBinop(op,_,_) ->
			if op = OpBoolAnd && allow_and then e
			else (EParenthesis e,pos e)
		| _ -> e

	method private negate (e : expr) = match fst e with
		| EUnop(Not,_,e1) -> e1
		| EBinop(OpBoolAnd,e1,e2) -> (EBinop(OpBoolOr,self#negate e1,self#negate e2),(pos e))
		| EBinop(OpBoolOr,e1,e2) -> (EBinop(OpBoolAnd,self#negate e1,self#negate e2),(pos e))
		| _ -> (EUnop(Not,Prefix,e),(pos e))

	method private conjoin (lhs : expr) (rhs : expr) =
		let lhs = self#maybe_parent true lhs in
		let rhs = self#maybe_parent true rhs in
		(EBinop(OpBoolAnd,lhs,rhs),punion (pos lhs) (pos rhs))

	method private cond_if' (e : expr) =
		conditional_expressions <- e :: conditional_expressions;
		conditional_stack <- (e,false) :: conditional_stack

	method cond_if (e : expr) =
		self#cond_if' e;
		depths <- 1 :: depths

	method cond_else (p : pos) =
		match conditional_stack with
		| (_,true) :: _ ->
			error (Preprocessor_error InvalidElse) p
		| (e,false) :: el ->
			conditional_stack <- (self#negate e,true) :: el
		| [] ->
			error (Preprocessor_error InvalidElse) p

	method cond_elseif (e : expr) (p : pos) =
		self#cond_else p;
		self#cond_if' e;
		match depths with
		| [] ->
			error (Preprocessor_error InvalidElseif) p
		| depth :: depths' ->
			depths <- (depth + 1) :: depths'

	method cond_end (p : pos) =
		let rec loop d el =
			if d = 0 then el
			else loop (d - 1) (List.tl el)
		in
		match depths with
			| [] ->
				error (Preprocessor_error InvalidEnd) p
			| depth :: depths' ->
				conditional_stack <- loop depth conditional_stack;
				depths <- depths'

	method get_current_condition = match conditional_stack with
		| (e,_) :: el ->
			List.fold_left self#conjoin e (List.map fst el)
		| [] ->
			(EConst (Ident "true"),null_pos)

	method get_conditions =
		conditional_expressions
end*/

typedef DeadBlock = {
	var p:Pos;
	var cond:Expr;
}

/*class DeadBlockCollector {
	public var preprocessor:Preprocessor;

	var deadBlocks:Array<DeadBlock> = [];
	var currentBlock:Array<DeadBlock> = [];

	public function new() {
		deadBlocks = [];
		currentBlock = [];
	}

	public function openDeadBlock(p:Pos) {
		currentBlock.insert(0, {p: {file: p.file, max: p.max, min: p.max}, cond: preprocessor.conds.getCurrentCondition()});
		//currentBlock.push({p: {pos: p., pmax: p.pmax, pmin: p.pmax}, cond: Preprocessor.conds.getCurrentCondition()});
	}

	public function closeDeadBlock(p:Pos) {
		if(currentBlock.length == 0) {
			throw "Internal error: Trying to close dead block that's not open";
		}

		var top = currentBlock.pop();

		var p0 = top.p;
		var cond = top.cond;

		deadBlocks.push({
			p: {file: p0.file, max: p0.max, min: p0.max},
			cond: cond
		});
		//switch(currentBlock) {
		//	case []:
		//		throw "Internal error: Trying to close dead block that's not open";
		//	case [{p0, cond}] :: pl:
		//		currentBlock = pl;
		//		deadBlocks.push({p: {pos: p0.pos, pmax: p0.pmax, pmin: p0.pmax}, cond: cond});
		//}
	}

	public function getDeadBlocks():Array<{p:Pos, cond:Expr}> {
		if(currentBlock.length > 0) {
			throw "Internal error: Trying to close dead block that's not open";
		}
		return deadBlocks;
	}
}*/

	/*
class dead_block_collector conds = object(self)
	val dead_blocks = DynArray.create ()
	val mutable current_block = []

	method open_dead_block (p : pos) =
		current_block <- ({p with pmin = p.pmax},conds#get_current_condition) :: current_block

	method close_dead_block (p : pos) = match current_block with
		| [] ->
			error (Custom "Internal error: Trying to close dead block that's not open") p;
		| (p0,cond) :: pl ->
			current_block <- pl;
			DynArray.add dead_blocks ({p0 with pmax = p.pmin},cond)

	method get_dead_blocks : (pos * expr) list =
		assert(current_block = []);
		DynArray.to_list dead_blocks
end*/
