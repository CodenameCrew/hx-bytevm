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

import hxbytevm.core.Ast;
import hxbytevm.utils.RegexUtils;
import hxbytevm.utils.StringUtils;
import hxbytevm.utils.FastStringBuf;

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

class Lexer {
	private function new(input:String) {
		this.input = input;
		this.pos = 0;
	}

	public var pos:Int = 0;
	public var input:String;
	public static function parse(input:String):Array<Token> {
		if (input == null || input.length <= 0) return [TEof];
		var lexer = new Lexer(input);
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

	public function parseBlockComment(s:String):Token {
		pos += 2; // to skip the /*
		var start = pos;
		var startLine = line;
		var str = new FastStringBuf();
		//trace("Current char: " + pos, input.length, start, startLine);
		while (pos < input.length) {
			var ch = advanceChar();
			// hopefully we dont need to check for eof
			handleNewline(str, ch);
			switch (ch) {
				case "*".code:
					if (peekChar() == "/".code) {
						//pos++;
						//trace("Adding comment: " + str);
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

			[re(START, Str("\\/\\/"), Star([Str("[^\\n\\r]")])), (s) -> TCommentLine(s)], // Single line comment
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
			[re(START, Str("\\#"), Basic(IDENT)), (s) -> TSharp(s)],
			[re(START, Str("\\$"), Star([Str("[_a-zA-Z0-9]")])), (s) -> TConst(CIdent(s))],

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

		var tokens:Array<Token> = [];
		while (pos < input.length) {
			{
				var ch = peekChar();
				while(ch == " ".code || ch == "\t".code) {
					ch = advanceCharDirect();
				}
				if(StringTools.isEof(ch)) {
					tokens.push(TEof);
					break;
				}
			}
			var found = false;
			for(rule in rules) {
				var rule_case = rule[0];

				//var length = input.indexOf("\n", pos) - pos;

				if(rule_case is EReg) {
					var rule_case:EReg = cast rule_case;
					//trace("Testing " + rule_case + " with " + input.substr(pos, input.length - pos));
					//trace("Length: " + length);
					//Sys.stdout().flush();

					if(rule_case.match(input.substr(pos))) {
						var rule_func:(String) -> Token = rule[1];
						//trace(input.substr(pos, length));
						//trace(input.substr(pos, length));
						var match = rule_case.matched(0);
						//trace("Match: '" + StringUtils.getEscapedString(match) + "' Pos: " + pos + " Length: " + match.length);
						var token = rule_func(match);
						//if(token != null) {
							tokens.push(token);
							//trace("Adding token: " + token);
						//} else {
						//	trace("Not adding token since its null: '" + StringUtils.getEscapedString(match) + "'");
						//}
						pos += match.length;
						found = true;
						break;
					}
				} else {
					var rule_case:String = cast rule_case;
					var match = input.substr(pos, rule_case.length);
					//trace("Testing " + rule_case + " with " + match);
					if(rule_case == match) {
						var rule_func:(String) -> Token = rule[1];
						//trace(input.substr(pos, length));
						//try {
							//trace("Match: '" + StringUtils.getEscapedString(match) + "' Pos: " + pos + " Length: " + match.length);
							var token = rule_func(match);
							//if(token != null) {
								tokens.push(token);
								//trace("Adding token: " + token);
							//}
							//else
							//	if(match != "\n" && match != "\r" && match != "\r\n" && match != " " && match != "\t")
							//		trace("Not adding token since its null: '" + StringUtils.getEscapedString(match) + "'");
							pos += match.length;
							found = true;
							break;
						//} catch(e:Dynamic) {
						//	trace("Current Tokens: " + tokens);
						//	trace("Error: " + e);
						//	Sys.exit(1);
						//}
					}
				}
			}
			if(!found) {
				trace("Current Tokens: " + tokens);
				throw "Invalid Character " + StringUtils.getEscapedString(input.substr(pos, 55));
			}

			if(StringTools.isEof(peekChar())) {
				tokens.push(TEof);
				break;
			}
		}

		return tokens;
	}
}
