package hxbytevm.core.syntax;

import hxbytevm.core.syntax.parsers.ComplexTypeParser;
import hxbytevm.core.Token;
import hxbytevm.core.Ast;

import hxbytevm.utils.macros.Utils.assert;
import hxbytevm.utils.Errors;
import hxbytevm.utils.enums.Result;
import hxbytevm.utils.Stream;

import haxe.ds.Option;

using hxbytevm.utils.HelperUtils;

enum abstract TypeDeclMode(Int) {
	var TCBeforePackage;
	var TCAfterImport;
	var TCAfterType;
}

enum abstract DeclFlag(Int) {
	var DPrivate;
	var DExtern;
	var DFinal;
	var DMacro;
	var DDynamic;
	var DInline;
	var DPublic;
	var DStatic;
	var DOverload;
}

class Parser {
	public var s:CacheStream<Token>;

	public function new(s : Stream<Token>) {
		this.s = new CacheStream(s);
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
		if(s.last() == TBrClose) {
			return switch s.peek() {
				case Some(TSemicolon): AstUtils.nullPos; //p;
				default: AstUtils.nullPos; // snd (last_token s)
			}
		} else {
			var tk = s.peek();
			s.junk();
			return switch tk {
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
				s.junk(); // skip package
				var pack = parsePackageName();

				trace(pack);

				var psem = semicolon();
				var typeDecls = parseTypeDecls(TCAfterImport, psem.max, pack, []);

				return new HaxeFile(filename, pack, [], typeDecls);
			default:
				var typeDecls = parseTypeDecls(TCBeforePackage, -1, [], []);
				return new HaxeFile(filename, [], [], typeDecls);
		}
	}

	public function parseTypeDecls(mode:TypeDeclMode, max:Int, pack:Array<String>, typeDecls:Array<TypeDecl>):Array<TypeDecl> {
		var decls = [];
		var cff:ResultOption<TypeDecl, Errors> = switch s.peek().get(TEof) {
			case TEof: None;
			default:
				try {
					Ok(parseTypeDecl(mode));
				} catch(e:Errors) {
					Err(e);
				}
		}

		switch(cff) {
			case Ok(cf):
				//var mode = switch(cf) {
				//	case EImport(_) | EUsing(_): TCAfterImport;
				//	default: TCAfterType;
				//}

				//var max = p.max;

				decls.push(cf);
				return parseTypeDecls(mode, max, pack, decls);
			case Err(e):
				var pos = AstUtils.nullPos;
				var err = switch e {
					case Msg(""):
						var nextTk = s.next();
						//pos = nextTk.pos;
						Errors.UnexpectedToken(nextTk);

					case Msg(msg):
						Errors.StreamError(msg);
					default: throw "Unknown error: " + e;
				}

				trace(Errors.SyntaxError(err, pos)); // todo: throw?

				//ignore(resume false false s);
				//parse_type_decls mode (last_pos s).pmax pack acc s
				var max = AstUtils.nullPos; //s.last().pos.max;
				parseTypeDecls(mode, max.max, pack, decls);
			case None:
				return decls;
		}

		return null;
	}

	public function expect(ctk:Token) {
		var tk = s.peek().get(TEof);
		if(!Type.enumEq(tk, ctk)) {
			throw "Expected " + ctk + ", got " + s.last();
		}
		s.junk();
	}

	private function parse_decl_flags():Array<DeclFlag> {
		var accs = [];
		while(true) {
			accs.push(switch(s.peek().get(TEof)) {
				case TKwd(KPrivate): s.junk(); DPrivate;
				case TKwd(KExtern): s.junk(); DExtern;
				case TKwd(KFinal): s.junk(); DFinal;
				case TKwd(KMacro): s.junk(); DMacro;
				case TKwd(KDynamic): s.junk(); DDynamic;
				case TKwd(KInline): s.junk(); DInline;
				case TKwd(KPublic): s.junk(); DPublic;
				case TKwd(KStatic): s.junk(); DStatic;
				case TKwd(KOverload): s.junk(); DOverload;
				default: break;
			});
		}
		return accs;
	}

	private function parse_meta_entry():MetadataEntry {
		var tk = s.peek().get(TEof);
		switch(tk) {
			// TODO: add support for @:meta
			case TConst(CIdent(st)):
				s.junk();
				var args = switch(s.peek().get(TEof)) {
					case TPOpen:
						s.junk();
						var args = [];
						while(true) {
							var tk = s.peek().get(TEof);
							if(tk == TEof)
								throw "Expected expression, got " + tk;
							if(tk == TPClose)
								break;
							s.junk();
							args.push(parseExpr());
						}
						args;
					default: [];
				}

				expect(TPClose);

				var pos = AstUtils.nullPos; // punion(p1,p)

				if(args.length == 0)
					return { name: st, pos: pos };
				return { name: st, params: args, pos: pos};
			default:
				return null;
		}
	}

	private function parse_meta():Metadata {
		var meta:Metadata = [];
		while(true) {
			var tk = s.peek().get(TEof);
			if(tk == TEof) break;
			switch(tk) {
				case TAt:
					s.junk();
					var entry = parse_meta_entry();
					if(entry == null)
						throw "Expected metadata entry, got " + s.last();
					meta.push(entry);
				default:
					break;
			}
		}

		return meta;
	}

	function parsePlacedName(allowKeywords:Bool = false):PlacedName {
		var tk = s.peek().get(TEof);
		switch(tk) {
			case TConst(CIdent(st)):
				s.junk();
				return { string: st, pos: AstUtils.nullPos };
			case TKwd(KMacro) if(allowKeywords):
				s.junk();
				return { string: "macro", pos: AstUtils.nullPos };
			case TKwd(KExtern) if(allowKeywords):
				s.junk();
				return { string: "extern", pos: AstUtils.nullPos };
			case TKwd(KFunction) if(allowKeywords):
				s.junk();
				return { string: "function", pos: AstUtils.nullPos };
			default:
				throw "Expected identifier, got " + tk;
		}
	}

	//private function parseTypeParams():Array<TypeParam> {
	//	var tks = [];
	//	while(true) {
	//		var tk = s.peek().get(TEof);
	//		if(tk == TEof)
	//			throw "Expected type parameter, got " + tk;
	//		if(tk == TComma) continue;
	//		s.junk();
	//		tks.push(parseTypeParam());
	//	}
	//	return tks;
	//}

	private inline function parseComplexType():ComplexType {
		return ComplexTypeParser.giveType(s);
	}

	private function parseTypedef(mode:TypeDeclMode, meta:Metadata = null, ?access:Array<AccessFlags>, ?doc:Documenation = null):TypeDecl {
		assert(s.last() == TKwd(KTypedef));

		s.junk();
		var name = parsePlacedName();
		var params = [];//parseTypeParams();
		trace("TODO: implement type params");
		var type = parseComplexType();
		return ETypedef({
			d_name: name,
			d_doc: doc,
			d_params: params,
			d_meta: meta,
			d_flags: [], //access,
			d_data: type
		});
		//throw "Expected typedef, got " + s.last();
	}

	private static function unsupported_decl_flag<T>(flag:DeclFlag, pos:Pos, type:String):Option<T> {
		trace("Unsupported "+type+" declaration flag: " + flag);
		return None;
	}

	private function decl_flag_to_class_flag(flag:DeclFlag, pos:Pos):Option<ClassFlag> {
		return switch(flag) {
			case DPrivate: Some(HPrivate);
			case DExtern: Some(HExtern);
			case DFinal: Some(HFinal);
			default: unsupported_decl_flag(flag, pos, "class");
		}
	}

	private function decl_flag_to_enum_flag(flag:DeclFlag, pos:Pos):Option<EnumFlag> {
		return switch(flag) {
			case DPrivate: Some(EPrivate);
			case DExtern: Some(EExtern);
			default: unsupported_decl_flag(flag, pos, "enum");
		}
	}

	private function decl_flag_to_typedef_flag(flag:DeclFlag, pos:Pos):Option<TypedefFlag> {
		return switch(flag) {
			case DPrivate: Some(TDPrivate);
			case DExtern: Some(TDExtern);
			default: unsupported_decl_flag(flag, pos, "typedef");
		}
	}

	private function decl_flag_to_abstract_flag(flag:DeclFlag, pos:Pos):Option<AbstractFlag> {
		return switch(flag) {
			case DPrivate: Some(AbPrivate);
			case DExtern: Some(AbExtern);
			default: unsupported_decl_flag(flag, pos, "abstract");
		}
	}

	public static function decl_flag_to_module_field_flag(flag:DeclFlag, pos:Pos):Option<AccessFlags> {
		return switch(flag) {
			case DPrivate: Some(APrivate);
			case DMacro: Some(AMacro);
			case DDynamic: Some(ADynamic);
			case DInline: Some(AInline);
			case DOverload: Some(AOverload);
			case DExtern: Some(AExtern);
			default: unsupported_decl_flag(flag, pos, "module field");
		}
	}

	private function parseTypeDecl(mode:TypeDeclMode):TypeDecl {
		switch(s.peek().get(TEof)) {
			case TKwd(KImport):
				return parseImport();
			case TKwd(KUsing):
				throw "Not implemented";
			default:
				//var doc = get_doc();
				var meta = parse_meta();
				var declFlags = parse_decl_flags();

				trace("Parsed meta: " + meta);
				trace("Parsed decl flags: " + declFlags);

				switch(s.last()) {
					//case TKwd(KClass) | TKwd(KInterface):
					//	return parseClass(mode);
					//case TKwd(KEnum):
					//	return parseEnum(mode);
					case TKwd(KTypedef):
						return parseTypedef(mode);
					//case TKwd(KAbstract):
					//	return parseAbstract(mode);
					default:
						throw "Expected type declaration, got " + s.last();
				}
		}
		throw "Not implemented";
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
		var tks = [];
		while(true) {
			var tk = s.peek().get(TEof);
			if(tk == TEof)
				throw "Expected package name, got " + tk;
			if(tk == TSemicolon) break;
			s.junk();
			if(tk == TDot) continue;

			var tr = lowerIdentOrMacro(tk);
			if(tr == null)
				throw "Package name must start with a lowercase character on " + tk;
			tks.push(tr);
		}
		return tks;
	}

	private function parseImport():TypeDecl {
		assert(s.last() == TKwd(KImport));

		s.junk();
		var path:Array<PlacedName> = [];
		var mode:ImportMode = INormal;

		function loop() {
			var tk = null;
			switch(tk = s.peek().get(TEof)) {
				case TDot:
					s.junk();
					switch(tk = s.peek().get(TEof)) {
						case TConst(CIdent(st)):
							s.junk();
							path.push({ string: st, pos: AstUtils.nullPos });
							loop();
						case TKwd(KMacro) | TKwd(KExtern) | TKwd(KFunction):
							s.junk();
							path.push({ string: lowerIdentOrMacro(tk), pos: AstUtils.nullPos });
							loop();
						case TBinop(BOpMult):
							mode = IAll;
						default:
							throw "Expected identifier after '.', got " + tk;
					}
				case TConst(CIdent("as")) | TKwd(KIn):
					s.junk();
					switch(tk = s.peek().get(TEof)) {
						case TConst(CIdent(s)):
							mode = IAsName({
								string: s,
								pos: AstUtils.nullPos
							});
						default:
							throw "Expected identifier after 'as', got " + s.last();
					}
				default:
			}
		}

		var tk = s.peek().get(TEof);
		switch(tk) {
			case TConst(CIdent(st)):
				s.junk();
				path.push({ string: st, pos: AstUtils.nullPos });
				loop();
			default:
				throw "Expected identifier after 'import', got " + tk;
		}

		semicolon();

		trace("Parsed import: " + path.map(v->v.string) + " " + mode);

		return EImport(@:fixed {
			path: path,
			mode: mode
		});
	}
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
