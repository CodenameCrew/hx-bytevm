package hxbytevm.core.syntax.parsers;

import hxbytevm.utils.CompareUtils;
import haxe.ds.Option;
import hxbytevm.core.Ast;
import hxbytevm.core.Token;
import hxbytevm.utils.Stream;
import hxbytevm.utils.Stream.CacheStream;

using hxbytevm.utils.HelperUtils;

class ComplexTypeParser {
	private var s:CacheStream<Token>;

	private function new(s:CacheStream<Token>) {
		this.s = s;
	}

	public inline static function giveType(s:CacheStream<Token>):ComplexType {
		return new ComplexTypeParser(s).parse_complex_type();
	}

	inline function parse_complex_type():ComplexType {
		return parse_complex_type_maybe_named(false);
	}

	function parse_complex_type_maybe_named(allow_named:Bool):ComplexType {
		s.matchSpecial(TPOpen, (tl = psep_trailing(s, TComma, (_)->parse_complex_type_maybe_named(true))), TPClose, {
			var p1 = AstUtils.nullPos;
			return switch(tl) {
				case [] | [CTNamed(_, _)]:
					// it was () or (a:T) - clearly a new function type syntax, proceed with parsing return type
					parse_function_type_next(tl, p1);

				case [t]:
					// it was some single unnamed type in parenthesis - use old function type syntax
					parse_complex_type_next(CTParent(t), p1);

				case _:
					// it was multiple arguments - clearly a new function type syntax, proceed with parsing return type
					parse_function_type_next(tl, p1);

			}
		});

		var t = parse_complex_type_inner(allow_named);
		return parse_complex_type_next(t);
	}

	function parse_function_type_next(tl:Array<ComplexType>, p1:Pos):ComplexType {
		s.matchSpecial(TArrow, (tret = parse_complex_type_inner(false)), {
			// | [< tret = parse_complex_type_inner false >] -> CTFunction (tl,tret), punion p1 (snd tret)
			return CTFunction(tl, tret);
		});
		throw "Expected '->'";
	}

	function parse_complex_type_next(t:ComplexType, p1:Pos = null):ComplexType {
		inline function make_fun(tl:ComplexType, pos:Pos):ComplexType {
			return switch tl {
				case CTFunction(args, ret): CTFunction(args.concat([t]), ret);
				default: CTFunction([t], tl); // Second argument is probably wrong
			}
		}

		inline function make_intersection(t2:ComplexType, p2:Pos):ComplexType {
			return switch t2 {
				case CTIntersection(tl): CTIntersection(tl.concat([t2])); // punion (pos t) p2
				default: CTIntersection([t, t2]);
			}
		}

		return switch s.peek() {
			case Some(TArrow):
				s.junk();

				var ct = parse_complex_type();
				var p2 = AstUtils.nullPos;//ct.pos;
				make_fun(ct, p2);
			case Some(TBinop(BOpAnd)):
				s.junk();
				var ct = parse_complex_type();
				var p2 = AstUtils.nullPos;//ct.pos;
				make_intersection(ct, p2);
			default:
				t;
		}
	}

	function parse_complex_type_inner(allow_named:Bool):ComplexType {
		var p1 = AstUtils.nullPos;

		s.matchSpecial(TPOpen, (t = parse_complex_type()), TPClose, {
			return CTParent(t); // punion p1 p2
		});

		switch s.peek() {
			case Some(TBrOpen):
				s.junk();
				s.matchSpecial((t = parse_type_anonymous()), {
					return CTAnonymous(t); // punion p1 p2
				});
				s.matchSpecial((t = parse_structural_extension()), {
					var tl = [parse_structural_extension(), t];

					s.matchSpecial((l = parse_type_anonymous()), {
						return CTExtend(tl, l); // punion p1 p2
					});
					s.matchSpecial((l = parse_class_fields(true, p1)), {
						return CTExtend(tl, l); // punion p1 p2
					});
				});
				s.matchSpecial((l = parse_class_fields(true, p1)), {
					return CTAnonymous(l); // punion p1 p2
				});
				throw "Error";
			default:
		}

		s.matchSpecial(TQuestion, (t = parse_complex_type_inner(allow_named)), {
			return CTOptional(t); // punion p1 p2
		});

		s.matchSpecial(TSpread, (t = parse_complex_type_inner(allow_named)), {
			var hint = switch t {
				case CTNamed(_, hint): hint;
				default: t;
			}

			var p = AstUtils.nullPos;//punion(p1, t.pos);
			return CTPath(make_ptp(mk_type_path([TPType(hint)], ["haxe"], "Rest"), p)); // punion p1 p2
		});

		s.matchSpecial((n = dollar_ident()), {
			if(allow_named) {
				s.matchSpecial(TDblDot, (t = parse_complex_type()), {
					//var p1 = n.pos;
					//var p2 = t.pos;
					return CTNamed(n, t); // punion p1 p2
				});
			} else {
				s.matchSpecial((t = parse_complex_type()), {
					//var p1 = n.pos;
					//var p2 = t.pos;
					return CTNamed(n, t); // punion p1 p2
				});
			}

			switch s.peek() {
				case Some(tk):
					s.junk();
					var ptp = parse_type_path2(null, [], n.string, n.pos);
					return CTPath(ptp); // punion p1 p2
				default:
			}

			s.restore();
		});

		s.matchSpecial((ptp = parse_type_path()), {
			return CTPath(ptp); // punion p1 p2
		});

		return null;
	}

	function mk_type_path(params:Array<TypeParam>, pack:Array<String>, name:String, ?sub:String):TypePath {
		if(name == "")
			throw "Empty module name is not allowed";
		return {
			pack: pack,
			name: name,
			params: params,
			sub: sub
		}
	}

	inline function parse_type_path():PlacedTypePath {
		return parse_type_path1(null, []);
	}

	function make_ptp(path:TypePath, ?p_path:Pos, ?p_full:Pos):PlacedTypePath {
		if(p_full == null)
			p_full = AstUtils.nullPos;
		if(p_path == null)
			p_path = p_full;
		return {
			path: path,
			pos_full: p_full,
			pos_path: p_path
		}
	}

	function parse_class_fields(allow_named:Bool, p1:Pos):Array<ClassField> {
		/*let acc = plist (parse_class_field tdecl) s in
		let p2 = (match s with parser
			| [< '(BrClose,p2) >] -> p2
			| [< >] -> error (Expected ["}"]) (next_pos s)
		) in
		acc,p2*/
		throw "Not implemented";
	}

	function parse_structural_extension():PlacedTypePath {
		/*
	| [< '(Binop OpGt,p1); s >] ->
		match s with parser
		| [< t = parse_type_path >] ->
			begin match s with parser
				| [< '(Comma,_) >] -> t
				| [< >] -> syntax_error (Expected [","]) s t
			end;
		| [< >] ->
			if would_skip_display_position p1 false s then begin
				begin match s with parser
					| [< '(Comma,_) >] -> ()
					| [< >] -> ()
				end;
				let p = display_position#with_pos p1 in
				make_ptp magic_type_path p
			end else
				raise Stream.Failure
				*/
		throw "Not implemented";
	}

	function parse_type_anonymous():Array<ClassField> {
		/*
and parse_type_anonymous s =
	let p0 = popt question_mark s in
	match s with parser
	| [< name, p1 = dollar_ident; t = parse_type_hint; s >] ->
		let opt,p1 = match p0 with
			| Some p -> true,punion p p1
			| None -> false,p1
		in
		let p2 = pos (last_token s) in
		let next acc =
			{
				cff_name = name,p1;
				cff_meta = if opt then [Meta.Optional,[],null_pos] else [];
				cff_access = [];
				cff_doc = None;
				cff_kind = FVar (Some t,None);
				cff_pos = punion p1 p2;
			} :: acc
		in
		begin match s with parser
		| [< '(BrClose,p2) >] -> next [],p2
		| [< '(Comma,p2) >] ->
			(match s with parser
			| [< '(BrClose,p2) >] -> next [],p2
			| [< l,p2 = parse_type_anonymous >] -> next l,punion p1 p2
			| [< >] -> serror());
		| [< >] ->
			syntax_error (Expected [",";"}"]) s (next [],p2)
		end
	| [< >] ->
		if p0 = None then raise Stream.Failure else serror()
			*/
		throw "Not implemented";
	}

	function parse_type_path1(p0:Pos, pack:Array<String>):PlacedTypePath { // AstUtils.nullPos, pack
		s.matchSpecial((name = dollar_ident(pack.length != 0)), {
			return parse_type_path2(p0, pack, name.string, name.pos);
		});
		return null;
	}

	function parse_type_path2(p0:Pos, pack:Array<String>, name:String, p1:Pos):PlacedTypePath { // AstUtils.nullPos, pack, n, n.pos
		throw "Not implemented";
	}

	function dollar_ident(allow_macro:Bool = false):PlacedName {
		switch s.peek() {
			case Some(v):
				s.junk();
				var name = switch v {
					case TConst(CIdent(i)): i;
					case TDollar(i): "$" + i;
					case TKwd(KMacro) if(allow_macro): "macro";
					case TKwd(KExtern) if(allow_macro): "extern";
					case TKwd(KFunction) if(allow_macro): "function";
					default: throw "Unknown identifier " + s.last();
				}
				return {
					string: name,
					pos: AstUtils.nullPos
				}
			default:
				throw "Unknown identifier " + s.last();
		}
	}

	static function psep_trailing<T, V>(s:CacheStream<T>, sep:T, f:CacheStream<T>->V):Array<V> {
		if(s.empty()) {
			return [];
		}
		s.store();

		var v = f(s);
		switch s.peek() {
			case Some(sep2) if(CompareUtils.deepEqual(sep2, sep)):
				s.junk();
				var l = psep_trailing(s, sep, f);
				s.discard();
				l.push(v);
				return l;
			default:
				s.restore();
				return [v];
		}
	}

	/*let rec psep_trailing sep f = parser
	| [< v = f; '(sep2,_) when sep2 = sep; l = psep_trailing sep f >] -> v :: l
	| [< v = f >] -> [v]
	| [< >] -> []*/
}
