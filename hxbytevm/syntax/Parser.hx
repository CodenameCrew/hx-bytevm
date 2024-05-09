package hxbytevm.syntax;

import haxe.ds.Option;
import hxbytevm.utils.enums.Result;
import hxbytevm.core.Token;
import hxbytevm.utils.Stream;
import hxbytevm.syntax.Lexer;
import hxbytevm.core.Ast;

using hxbytevm.utils.HelperUtils;

enum TypeDeclMode {
	TCBeforePackage;
	TCAfterImport;
	TCAfterType;
}

class Parser {
	public var s:Stream<Token>;
	var cache:TokenCache;

	public function new(s : Stream<Token>) {
		this.s = s;
	}

	function lastToken():Token {
		if(cache.length == 0)
			return s.peek().get();
		return cache.get(cache.length - 1);
	}

	function nextToken():Token {
		return switch s.peek() { // TODO: position
			//case Some(TEof): TEof;
			case Some(tk): tk;
			case None: TEof;
		}
	}

	/*public static function parseExprFromTokens(tokens : Array<Token>) : Expr {
		return new Parser(new ArrayStream(tokens)).parseExpr();
	}*/

	public inline static function giveExpr(s : Stream<Token>) : Expr {
		return new Parser(s).parseExpr();
	}

	public function parseExpr() : Expr {
		var exprs:Array<Expr> = [];



		//return mk(EBlock([
		//	mk(ECall(mk(EConst(CIdent("trace"))), [
		//		mk(EConst(CString("Hello World", SSingleQuotes)))
		//	]))
		//]));

		if(exprs.length == 1)
			return exprs[0];
		return mk(EBlock(exprs));
	}

	public static function makeUnop(op:Unop, e:Expr, pos:Pos):Expr {
		var p2 = e.pos;
		var p1 = pos;
		//function neg(s:String):String {
		//	if(s.charAt(0) == '-') return s.substr(1);
		//	return "-" + s;
		//}
		return switch(e.expr) {
			case EBinop(bop, e1, e2): mk(EBinop(bop, makeUnop(op, e1, p1), e2), AstUtils.punion(p1, p2));
			case ETernary(e1, e2, e3): mk(ETernary(makeUnop(op, e1, p1), e2, e3), AstUtils.punion(p1, p2));
			case EIs(e, t): mk(EIs(makeUnop(op, e, p1), t), AstUtils.punion(p1, p2));
			// Originally in haxe these are strings, but here they are ints and floats, so we *-1
			case EConst(CInt(i, suffix)): mk(EConst(CInt((i)*-1, suffix)), AstUtils.punion(p1, p2));
			case EConst(CFloat(j, suffix)): mk(EConst(CFloat((j)*-1, suffix)), AstUtils.punion(p1, p2));
			default: mk(EUnop(op, UFPrefix, e), AstUtils.punion(p1, p2));
		}
	}

	@:pure public static function mk(e : ExprDef, ?pos : Pos = null) : Expr {
		if(pos == null)
			pos = AstUtils.nullPos;
		return { expr : e, pos : pos };
	}

	// -- Typedecl --

	public var filename:String = "?";

	public static function parseFile(text:String) : HaxeFile {
		var lexer = new Lexer();
		lexer.load(text);
		var parser = new Parser(lexer);
		parser.filename = "test.hx";
		return parser._parseFile();
	}

	private function semicolon():Pos {
		if(lastToken() == TBrClose) {
			return switch s.peek() {
				case Some(TSemicolon): AstUtils.nullPos; //p;
				default: AstUtils.nullPos; // snd (last_token s)
			}
		} else {
			return switch s.peek() {
				case Some(TSemicolon): AstUtils.nullPos; //p;
				case Some(tk): throw "Expected ';', got " + tk; // syntax_error Missing_semicolon s (next_pos s)
				default: AstUtils.nullPos; // Should allow for a missing ; at the end of the file
			}
		}
		return AstUtils.nullPos;
	}

	public function _parseFile() : HaxeFile {
		var tk = s.peek().get(TEof);
		switch(tk) {
			case TKwd(KPackage):
				s.next(); // Move past the package keyword
				var pack = parsePackageName();

				var psem = semicolon();
				var typeDecls = parseTypeDecls(TCAfterImport, psem.max, pack, []);

				return new HaxeFile(filename, pack, [], typeDecls);
			default:
				var typeDecls = parseTypeDecls(TCBeforePackage, -1, [], []);
				return new HaxeFile(filename, [], [], typeDecls);
		}
	}

	public function parseTypeDecls(mode:TypeDeclMode, max, pack:Array<String>, typeDecls:Array<TypeDecl>):Array<TypeDecl> {
		var decls = [];
		var cff:Option<TypeDecl> = switch s.peek().get(TEof) {
			case TEof: None;
			default: parseTypeDecl(mode).toOption();
		}

		return decls;
	}

	private function parseTypeDecl(mode:TypeDeclMode):TypeDecl {
		return null;
	}

	private static function lowerIdentOrMacro(tk:Token):String {
		return switch(tk) {
			case TConst(CIdent(s)) if(AstUtils.isLowerIdent(s)): s;
			case TKwd(KMacro): "macro";
			case TKwd(KExtern): "extern";
			case TKwd(KFunction): "function";
			default: null;
		}
	}

	private function parsePackageName():Array<String> {
		return switch (s.peek().get(TEof)) {
			case TKwd(KPackage):
				s.next(); // skip package
				var tks = [];
				while(true) {
					var tk = s.next();
					if(tk == TSemicolon) break;
					if(tk == TDot) continue;

					var tr = lowerIdentOrMacro(tk);
					if(tr == null)
						throw "Package name must start with a lowercase character";
					tks.push(tr);
				}
				tks;
			default: [];
		}
	}

	/*private static function psep<T>(sep:Token, tokens:Array<Token>, f:Token->T):Array<T> {
		var pos = 0;
		var getToken = () -> tokens[pos++];
		var tks = [];

		while(true) {
			var tk = getToken();
			if(tk == sep) {
				//if(tks.length == 0)
				//	throw "Expected token, got " + getToken();
				break;
			}
			tks.push(f(tk));
		}

		return tks;
	}*/
}

class HaxeFile {
	public var path:String;
	public var pack:Array<String>;
	public var imports:Array<String>;
	public var decls:Array<TypeDecl>;

	public function new(path:String, ?pack:Array<String>, ?imports:Array<String>, ?decls:Array<TypeDecl>) {
		this.path = path;
		this.pack = pack;
		this.imports = imports;
		this.decls = decls;
	}
}
