package hxbytevm.syntax;

import hxbytevm.core.Ast;

enum Token {
	TEof;
	TConst(const:Const);
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
	public function new() {}

	public var input:String;
	public function parse(input:String):Array<Token> {
		if (input == null || input.length <= 0) return [];
		this.input = input;

		var tokens:Array<Token> = [];
		while (pos < input.length) tokens.push(token());

		return tokens;
	}

	public var identChars:Array<Bool> = {
		var ret = [];
		var str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";
		for(i in 0...str.length)
			ret[str.charCodeAt(i)] = true;
		ret;
	};
	public var startIdentChars:Array<Bool> = {
		var ret = [];
		var str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_";
		for(i in 0...str.length)
			ret[str.charCodeAt(i)] = true;
		ret;
	};

	function getOnlyIdent():String {
		var start = pos;
		while (pos < input.length) {
			var char = input.charCodeAt(pos);
			var items = start == pos ? startIdentChars : identChars;
			if (!items[char]) {
				break;
			}
			pos++;
		}
		var ret = input.substr(start, pos - start);
		return ret;
	}

	public function tokenString(quote:Int):String {
		var start = pos; pos++;
		while (pos < input.length) {
			// todo: check for escape sequences
			if (input.charCodeAt(pos) == quote) {
				pos++;
				return input.substr(start, pos - start - 1);
			}
			pos++;
		}
		throw "Unclosed String";
	}

	public var pos:Int = 0;
	public function token():Token {
		var char = input.charCodeAt(pos);
		if(StringTools.isEof(char))
			return TEof;

		if(char == 0)
			return TEof;

		switch (char) {
			case "+".code:
				switch (input.charCodeAt(pos - 1)) {
					case "+".code: TUnop(UIncrement);
					default: token();
				}
			case "-".code:
				switch (input.charCodeAt(pos - 1)) {
					case "-".code: TUnop(UDecrement);
					default: token();
				}
			case 0: return TEof;
			case '"'.code | "'".code: return TConst(CString(tokenString(char), char == '"'.code ? SDoubleQuotes : SSingleQuotes));
			case '('.code: return TPOpen;
			case ')'.code: return TPClose;
			case '['.code: return TBkOpen;
			case ']'.code: return TBkClose;
			case '{'.code: return TBrOpen;
			case '}'.code: return TBrClose;
			case ','.code: return TComma;
			case ';'.code: return TSemicolon;
			case '.'.code: return TDot;
			case ':'.code: return TDblDot;
			case '?'.code: return TQuestion;
			case '@'.code: return TAt;
			case '$'.code: return TDollar(getOnlyIdent());
			case '0'.code | '1'.code | '2'.code | '3'.code | '4'.code | '5'.code | '6'.code | '7'.code | '8'.code | '9'.code:
				return parseNumber(char);
			default:
				var buf = "";
				var char = char;
				var first = true;
				if((first ? startIdentChars : identChars)[char]) {
					while (true) {
						char = input.charCodeAt(pos);
						if(!(first ? startIdentChars : identChars)[char])
							break;
						buf += String.fromCharCode(char);
					}

					if(buf == "in") return TBinop(BOpIn);
					return TConst(CIdent(buf));
				}
		}

		return null;
	}

	function parseNumber(char:Int):Token {
		var buf = "0";
		return TConst(CInt(Std.parseInt(buf)));
	}
}

	/*
| "--" -> mk lexbuf (Unop Decrement)
| "~"  -> mk lexbuf (Unop NegBits)
| "%=" -> mk lexbuf (Binop (OpAssignOp OpMod))
| "&=" -> mk lexbuf (Binop (OpAssignOp OpAnd))
| "|=" -> mk lexbuf (Binop (OpAssignOp OpOr))
| "^=" -> mk lexbuf (Binop (OpAssignOp OpXor))
| "+=" -> mk lexbuf (Binop (OpAssignOp OpAdd))
| "-=" -> mk lexbuf (Binop (OpAssignOp OpSub))
| "*=" -> mk lexbuf (Binop (OpAssignOp OpMult))
| "/=" -> mk lexbuf (Binop (OpAssignOp OpDiv))
| "<<=" -> mk lexbuf (Binop (OpAssignOp OpShl))
| "||=" -> mk lexbuf (Binop (OpAssignOp OpBoolOr))
| "&&=" -> mk lexbuf (Binop (OpAssignOp OpBoolAnd))
| "??=" -> mk lexbuf (Binop (OpAssignOp OpNullCoal))
| ">>=" -> mk lexbuf (Binop (OpAssignOp OpShr)) *)
| ">>>=" -> mk lexbuf (Binop (OpAssignOp OpUShr)) *)
| "==" -> mk lexbuf (Binop OpEq)
| "!=" -> mk lexbuf (Binop OpNotEq)
| "<=" -> mk lexbuf (Binop OpLte)
| ">=" -> mk lexbuf (Binop OpGte) *)
| "&&" -> mk lexbuf (Binop OpBoolAnd)
| "||" -> mk lexbuf (Binop OpBoolOr)
| "<<" -> mk lexbuf (Binop OpShl)
| "->" -> mk lexbuf Arrow
| "..." -> mk lexbuf Spread
| "=>" -> mk lexbuf (Binop OpArrow)
| "!" -> mk lexbuf (Unop Not)
| "<" -> mk lexbuf (Binop OpLt)
| ">" -> mk lexbuf (Binop OpGt)
| ";" -> mk lexbuf Semicolon
| ":" -> mk lexbuf DblDot
| "," -> mk lexbuf Comma
| "." -> mk lexbuf Dot
| "?." -> mk lexbuf QuestionDot
| "%" -> mk lexbuf (Binop OpMod)
| "&" -> mk lexbuf (Binop OpAnd)
| "|" -> mk lexbuf (Binop OpOr)
| "^" -> mk lexbuf (Binop OpXor)
| "+" -> mk lexbuf (Binop OpAdd)
| "*" -> mk lexbuf (Binop OpMult)
| "/" -> mk lexbuf (Binop OpDiv)
| "-" -> mk lexbuf (Binop OpSub)
| "=" -> mk lexbuf (Binop OpAssign)
| "[" -> mk lexbuf BkOpen
| "]" -> mk lexbuf BkClose
| "{" -> mk lexbuf BrOpen
| "}" -> mk lexbuf BrClose
| "(" -> mk lexbuf POpen
| ")" -> mk lexbuf PClose
| "??" -> mk lexbuf (Binop OpNullCoal)
| "?" -> mk lexbuf Question
| "@" -> mk lexbuf At
*/