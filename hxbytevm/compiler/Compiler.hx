package hxbytevm.compiler;

import hxbytevm.utils.ReverseIterator.ReverseArrayIterator;
import hxbytevm.utils.ReverseIterator.ReverseArrayKeyValueIterator;
import hxbytevm.utils.ExprUtils;
import hxbytevm.utils.HelperUtils;
import hxbytevm.vm.OpCode;
import hxbytevm.utils.RuntimeUtils;
import hxbytevm.core.Ast;
import hxbytevm.vm.Program;

class Pointer {
	public var ip:Int;
	public var rp:Int;

	public function new(ip:Int, rp:Int) {
		this.ip = ip;
		this.rp = rp;
	}


	public inline function set(ip:Int, rp:Int) {
		this.ip = ip;
		this.rp = rp;
	}

	public inline function offset(ip:Int, rp:Int) {
		this.ip += ip;
		this.rp += rp;
	}

	public function toString():String {
		return '<POINTER IP: $ip, RP: $rp>';
	}
}

class Compiler {
	public var program(default, null):Program;

	public var instructions:Array<OpCode>;
	public var read_only_stack:Array<StackValue>;

	public var ip:Int;
	public var rp:Int;

	public var depth:Int = 0;

	public function new() {}

	public function reset() {
		program = Program.createEmpty(); depth = 0;
		pointers = [];

		instructions = program.instructions;
		read_only_stack = program.read_only_stack;
	}

	public function getConstant(c:Dynamic) {
		if(program.constant_stack.contains(c)) return program.constant_stack.indexOf(c);
		program.constant_stack.push(c);
		return program.constant_stack.length-1;
	}

	public function pushConstant(c:Dynamic) {
		read_only_stack.insert(rp++, getConstant(c));
		instructions.insert(ip++, PUSHC);
	}

	public function getVar(v:Dynamic) {
		if(program.varnames_stack.contains(v)) return program.varnames_stack.indexOf(v);
		program.varnames_stack.push(v);
		return program.varnames_stack.length-1;
	}

	public function pushVar(vname:String) {
		read_only_stack.insert(rp++, getVar(vname));
		instructions.insert(ip++, PUSHV);
	}

	public function saveVar(vname:String) {
		read_only_stack.insert(rp++, getVar(vname));
		instructions.insert(ip++, SAVE);
	}

	public var pointers:Array<Pointer> = [];
	public function pointer():Pointer {
		var pointer = new Pointer(instructions.length, get_rom_len());
		pointers.push(pointer);
		return pointer;
	}

	public function pointer_update(pointer:Pointer) {
		pointer.ip = instructions.length;
		pointer.rp = get_rom_len();
	}

	public inline function get_rom_len():Int {
		var len:Int = read_only_stack.length;
		for (rom in read_only_stack)
			if (rom is Pointer) len++;
		return len;
	}

	public function compile_pointers() {
		var i:Int = 0;
		while (i < read_only_stack.length) {
			var rom = read_only_stack[i];
			if (rom is Pointer) {
				var ip:Int = rom.ip;
				var rp:Int = rom.rp;

				read_only_stack[i] = ip;
				read_only_stack.insert(i+1, rp);
				i++;
			}
			i++;
		}
	}

	public function compile(expr:Expr):Void {
		reset();

		compile_functions(expr);
		switch (expr.expr) {
			case EBlock(exprs): for (e in exprs) _compile(e);
			default: _compile(expr);
		}
		compile_pointers();
		instructions.insert(ip++, RET);
	}

	private var compileFunctions:Bool = true;
	private function compile_functions(expr:Expr) {
		compileFunctions = true;
		ExprUtils.recursive(expr, (e:Expr) -> {
			if (e == null || e.expr == null) return;
			switch(e.expr) {
				case EFunction(func_kind, func): _compile(e);
				default:
			}
		});
		compileFunctions = false;
	}

	private function _compile(expr:Expr) {
		if (expr == null || expr.expr == null) return;

		switch (expr.expr) {
			case EConst(c):
				switch (c) {
					case CInt(v, suffix): pushConstant(v);
					case CFloat(v, suffix): pushConstant(v);
					case CString(v, _): pushConstant(v);
					case CIdent("null"): instructions.insert(ip++, PUSH_NULL);
					case CIdent("true"): instructions.insert(ip++, PUSH_TRUE);
					case CIdent("false"): instructions.insert(ip++, PUSH_FALSE);
					case CIdent(v): pushVar(v);
					case CRegexp(r, o): {
						pushConstant(EReg);
						instructions.insert(ip++, PUSH);

						pushConstant(r);
						pushConstant(o);
						read_only_stack.insert(rp++, 2);
						instructions.insert(ip++, ARRAY_STACK);
						instructions.insert(ip++, NEW);
					}
				}
			case EBlock(exprs):
				instructions.insert(ip++, DEPTH_INC);
				depth++;
				for (e in exprs) {
					_compile(e);
				}
				depth--;
				instructions.insert(ip++, DEPTH_DNC);
			case ETry(e, catches):
				trace("Try statement not implemented");
				_compile(e);
				/*
				var old = declaredVars.length;
				instructions.insert(ip++, DEPTH_INC);
				_compile(e);
				instructions.insert(ip++, DEPTH_DNC);
				for (c in catches) {
					var caseLabel = pointer(getUniqueId());
					read_only_stack.insert(rp++, caseLabel);
					instructions.insert(ip++, JUMP_N_COND);
					_compile(c.expr);
					read_only_stack.insert(rp++, caseLabel);
					instructions.insert(ip++, JUMP);
				}
				declaredVars = declaredVars.slice(0, old);*/
			case EMeta(m, e):
				// TODO: handle bypassAccessor
				_compile(e);
			case ECast(e, type):
				_compile(e);
				// TODO: cast
				//pushConstant(type);
				//instructions.insert(ip++, CAST);
			case ECheckType(e, type):
				_compile(e);
				// TODO: check type
			case EUntyped(e):
				_compile(e); //TODO: untyped somehow
			case EIs(e, type):
				_compile(e);
				switch(type) {
					case CTPath(tp):
						var cls = Type.resolveClass(HelperUtils.getPackFromTypePath(tp.path));
						if (cls == null)
							throw "Unknown class";
						read_only_stack.insert(rp++, cls);
						instructions.insert(ip++, IS);
					default:
						trace("Unknown type " + type);
						trace("Skipping is for " + e);
				}
				// TODO: is
				//instructions.insert(ip++, IS);
			case ENew(path, expr):
				var pack = HelperUtils.getPackFromTypePath(path.path);
				// if(declaredVars.contains(pack)) {
				// 	// Push from vars
				// } else {
					var cls = Type.resolveClass(pack);
					if (cls == null)
						throw "Unknown class";
					read_only_stack.insert(rp++, cls);
					instructions.insert(ip++, PUSH);
				// }
				//pushConstant(path);
				for (e in expr) {
					_compile(e);
				}
				read_only_stack.insert(rp++, expr.length);
				instructions.insert(ip++, ARRAY_STACK);
				instructions.insert(ip++, NEW);
			case ESwitch(e, cases, edef):
				throw "Switch statement not implemented";
				/*var old = declaredVars.length;
				instructions.insert(ip++, DEPTH_INC);
				_compile(e);
				instructions.insert(ip++, DEPTH_DNC);
				for (c in cases) {
					var caseLabel = pointer(getUniqueId());
					read_only_stack.insert(rp++, caseLabel);
					instructions.insert(ip++, JUMP_N_COND);
					_compile(c.expr);
					read_only_stack.insert(rp++, caseLabel);
					instructions.insert(ip++, JUMP);
				}
				if (edef != null) {
					read_only_stack.insert(rp++, pointer(getUniqueId()));
					_compile(edef);
					read_only_stack.insert(rp++, caseLabel);
					instructions.insert(ip++, JUMP);
				}
				declaredVars = declaredVars.slice(0, old);*/
			case ESwitchComplex(e, cases, edef):
				throw "Complex Switch statement not implemented";
			case EParenthesis(expr):
				_compile(expr);
			case EVars(vars):
				for (v in vars) {
					// todo handle isFinal, isStatic, isPublic
					_compile(v.expr);
					saveVar(v.name.string);
				}
			case EIf(econd, eif, eelse) | ETernary(econd, eif, eelse):
				var end_p = pointer();
				var else_p = pointer();
				_compile(econd);
				read_only_stack.insert(rp++, eelse != null ? else_p : end_p);
				instructions.insert(ip++, JUMP_N_COND);
				_compile(eif);
				if(eelse != null) {
					read_only_stack.insert(rp++, end_p);
					instructions.insert(ip++, JUMP);

					pointer_update(else_p);
					trace(else_p);
					_compile(eelse);
				}
				pointer_update(end_p);
			case EWhile(econd, e, flag):
				switch (flag) {
					case WFNormalWhile:
						var start_p = pointer();
						var end_p = pointer();
						pointer_update(start_p);
						_compile(econd);
						// TODO: helper function to make this cleaner
						read_only_stack.insert(rp++, end_p);
						instructions.insert(ip++, JUMP_N_COND); // to label END
						_compile(e);
						read_only_stack.insert(rp++, start_p);
						instructions.insert(ip++, JUMP); // to label START

						pointer_update(end_p);
						trace(end_p, get_compile_pointer());
					case WFDoWhile:
						var start = pointer();
						_compile(e);
						_compile(econd);
						read_only_stack.insert(rp++, start);
						instructions.insert(ip++, JUMP_COND);
				}
			case EFor(iter, expr):
				var keyvar:String = null;
				var valuevar:String = null;
				var hasKey:Bool = false;

				// TODO: special optimization for int loops
				switch (iter.expr) {
					case EBinop(BOpIn, e1, e2):
						switch (e1.expr) {
							case EBinop(BOpArrow, _.expr => EConst(CIdent(key)), _.expr => EConst(CIdent(value))):
								keyvar = key;
								valuevar = value;
								hasKey = true;
							case EConst(CIdent(s)):
								valuevar = s;
							default:
						}

						if(valuevar == null || (hasKey && keyvar == null)) throw "Expected identifier";
					default:
						throw "Invalid for loop iterator";
				}

				var it:Dynamic->Iterator<Dynamic> = (hasKey ? RuntimeUtils.keyValueIterator : RuntimeUtils.iterator);

				instructions.insert(ip++, DEPTH_INC);

				read_only_stack.insert(rp++, it);
				instructions.insert(ip++, PUSH);

				_compile(mk(EField(iter, "hasNext", EFNormal)));
				_compile(mk(EField(iter, "next", EFNormal)));

				// continueBreakStack.push(instructions.length); // marks the start of the loop
				// continueBreakStackLabel.push(pointer());
				read_only_stack.insert(rp++, -1); // hasNext
				instructions.insert(ip++, STK_OFF);
				instructions.insert(ip++, PUSH_ARRAY);
				instructions.insert(ip++, CALL);
				instructions.insert(ip++, JUMP_N_COND);
				// inner body

				read_only_stack.insert(rp++, -0); // next
				instructions.insert(ip++, STK_OFF);
				instructions.insert(ip++, CALL);

				if(hasKey) {
					// keyvar = next.key;
						instructions.insert(ip++, DUP);
						read_only_stack.insert(rp++, "key");
						instructions.insert(ip++, FIELD_GET);

						read_only_stack.insert(rp++, keyvar);
						instructions.insert(ip++, SAVE);

					// valuevar = next.value;
						read_only_stack.insert(rp++, "value");
						instructions.insert(ip++, FIELD_GET);

						read_only_stack.insert(rp++, valuevar);
						instructions.insert(ip++, SAVE);
				} else {
					// valuevar = next;
						read_only_stack.insert(rp++, valuevar);
						instructions.insert(ip++, SAVE);
				}

				_compile(expr);
				_compile(mk(EContinue));

				// continueBreakStackLabel[continueBreakStackLabel.length - 1].pos = instructions.length;

				instructions.insert(ip++, POP); // Pop the next function
				instructions.insert(ip++, POP); // Pop the hasNext function

				instructions.insert(ip++, DEPTH_DNC);

				// continueBreakStack.pop();
				// continueBreakStackLabel.pop();
			case EBreak:
				// read_only_stack.insert(rp++, continueBreakStackLabel[continueBreakStackLabel.length - 1]);
				instructions.insert(ip++, JUMP);
			case EContinue:
				// read_only_stack.insert(rp++, continueBreakStack[continueBreakStack.length - 1]);
				instructions.insert(ip++, JUMP_COND);
			case EThrow(e):
				_compile(e);
				// instructions.insert(ip++, THROW);
			case EReturn(e):
				if(e != null)
					_compile(e);
				else
					instructions.insert(ip++, PUSH_NULL);
				if (depth > 0) instructions.insert(ip++, DEPTH_DNC);
				instructions.insert(ip++, RET);

			case EFunction(name, func):
				if (!compileFunctions) { // update depth
					switch (name) {
						case FNamed(placed_name, isInline):
							var program_func:ProgramFunc = null;
							var func_id:Int = -1;

							if (program.func_names.contains(placed_name.string))
								program_func = program.program_funcs[func_id = program.func_names.indexOf(placed_name.string)];

							if (func_id != -1) program_func.depth = depth;

						// TODO: Make like IDs for these and connect then to the expr
						case FAnonymous:
						case FArrow:
					}
					return;
				}

				var program_func:ProgramFunc = {
					instructions: [],
					read_only_stack: [],

					depth: depth,
					args: []
				};

				for (i => arg in func.args) {
					if (arg == null || arg.value == null) {
						program_func.args[i] = UnDefined;
						continue;
					}

					var defaultValue:Variable = UnDefined;
					switch (arg.value.expr) {
						case EConst(c):
							switch (c) {
								case CInt(v, suffix): defaultValue = Defined(v);
								case CFloat(v, suffix): defaultValue = Defined(v);
								case CString(v, _): defaultValue = Defined(v);
								case CIdent("null"): defaultValue = Defined(null);
								case CIdent("true"): defaultValue = Defined(true);
								case CIdent("false"): defaultValue = Defined(false);
								default:
							}
						default:
					}
					program_func.args[i] = defaultValue;
				}

				instructions = program_func.instructions;
				read_only_stack = program_func.read_only_stack;

				switch (func.expr.expr) {
					case EBlock(exprs):
						instructions.insert(ip++, DEPTH_INC);
						depth++;

						for (arg in new ReverseArrayIterator(func.args))
							saveVar(arg.name.string);

						// recurssion
						switch (name) {
							case FNamed(placed_name, isInline):
								program.program_funcs.push(program_func);
								program.func_names.push(placed_name.string);

							// TODO: Make like IDs for these and connect then to the expr
							case FAnonymous:
							case FArrow:
						}

						compile_functions(func.expr);
						for (e in exprs) _compile(e);

						depth--;
						if (!contains_ret(instructions))
							instructions.insert(ip++, DEPTH_DNC);

						compile_pointers();
					case _:
						throw "Functions must be in blocks";
				}

				instructions = program.instructions;
				read_only_stack = program.read_only_stack;

			case EField(e, field, safe):
				var isSafe = safe == EFSafe;
					var end_p = pointer();
					var null_p = pointer();
					_compile(e);
					if(isSafe) {
						instructions.insert(ip++, DUP);
						instructions.insert(ip++, PUSH_NULL);
						instructions.insert(ip++, EQ);
						read_only_stack.insert(rp++, null_p);
						instructions.insert(ip++, JUMP_COND);
					}
					pushConstant(field);
					instructions.insert(ip++, FIELD_GET);
					if(isSafe) {
						read_only_stack.insert(rp++, end_p);
						instructions.insert(ip++, JUMP_COND);
						pointer_update(null_p);
						instructions.insert(ip++, PUSH_NULL);
					}
					pointer_update(end_p);
			case EArray(e1, e2):
				_compile(e1); // arr
				_compile(e2); // index
				instructions.insert(ip++, ARRAY_GET);
			case EArrayDecl(values):
				// TODO: map support
				for (v in values) {
					_compile(v);
				}
				read_only_stack.insert(rp++, values.length);
				instructions.insert(ip++, ARRAY_STACK);
			case EBinop(BOpBoolAnd, e1, e2):
				/*
				e1;
				var check = stack.last();
				if(check == true) {
					e2;
					check = stack.last();
				}
				stack.push(check);
				*/
				var end_p = pointer();
				_compile(e1); // 1
				read_only_stack.insert(rp++, end_p);
				instructions.insert(ip++, JUMP_N_COND); // 0 // to at the of this
				_compile(e2); // 1
				pointer_update(end_p);
			case EBinop(BOpBoolOr, e1, e2):
				/*
				e1;
				var check = stack.last();
				if(check == false) {
					e2;
					check = stack.last();
				}
				stack.push(check);
				*/

				var end_p = pointer();
				_compile(e1); // 1
				read_only_stack.insert(rp++, end_p);
				instructions.insert(ip++, JUMP_COND); // 0 // to at the of this
				_compile(e2); // 1
				pointer_update(end_p);
			case EBinop(BOpNullCoal, e1, e2):
				/*
				e1;
				var check = stack.last();
				if(check == true) {
					e2;
					check = stack.last();
				}
				stack.push(check);
				*/
				var end_p = pointer();
				_compile(e1); // 1
				instructions.insert(ip++, PUSH_NULL);
				instructions.insert(ip++, EQ);
				read_only_stack.insert(rp++, end_p);
				instructions.insert(ip++, JUMP_N_COND); // 0 // to at the of this
				_compile(e2); // 1
				pointer_update(end_p);
			case EBinop(BOpAssign, e1, e2):
				var varname:String = HelperUtils.getIdentFromExpr(e1);
				_compile(e2);
				saveVar(varname);
			case EBinop(BOpAssignOp(op), e1, e2):
				throw "BinopAssignOp not implemented";
				/*_compile(e1);
				_compile(e2);
				switch (op) {
					case BOpAdd: instructions.insert(ip++, ADD);
					case BOpSub: instructions.insert(ip++, SUB);
					case BOpMult: instructions.insert(ip++, MULT);
					case BOpDiv: instructions.insert(ip++, DIV);
					case BOpEq: instructions.insert(ip++, EQ);
					case BOpNotEq: instructions.insert(ip++, NEQ);
					case BOpGt: instructions.insert(ip++, GT);
					case BOpGte: instructions.insert(ip++, GTE);
					case BOpLt: instructions.insert(ip++, LT);
					case BOpLte: instructions.insert(ip++, LTE);
					case BOpAnd: instructions.insert(ip++, AND);
					case BOpOr: instructions.insert(ip++, OR);
					case BOpXor: instructions.insert(ip++, XOR);
					case BOpShl: instructions.insert(ip++, SHL);
					case BOpShr: instructions.insert(ip++, SHR);
					case BOpUshr: instructions.insert(ip++, USHR);
					case BOpMod: instructions.insert(ip++, MOD);
					//default: throw "Unknown binop " + op;
				}*/
			case EBinop(op, e1, e2):
				_compile(e1);
				_compile(e2);
				switch (op) {
					case BOpAdd: instructions.insert(ip++, ADD);
					case BOpSub: instructions.insert(ip++, SUB);
					case BOpMult: instructions.insert(ip++, MULT);
					case BOpDiv: instructions.insert(ip++, DIV);
					case BOpEq: instructions.insert(ip++, EQ);
					case BOpNotEq: instructions.insert(ip++, NEQ);
					case BOpGt: instructions.insert(ip++, GT);
					case BOpGte: instructions.insert(ip++, GTE);
					case BOpLt: instructions.insert(ip++, LT);
					case BOpLte: instructions.insert(ip++, LTE);
					case BOpAnd: instructions.insert(ip++, AND);
					case BOpOr: instructions.insert(ip++, OR);
					case BOpXor: instructions.insert(ip++, XOR);
					case BOpShl: instructions.insert(ip++, SHL);
					case BOpShr: instructions.insert(ip++, SHR);
					case BOpUShr: instructions.insert(ip++, USHR);
					case BOpMod: instructions.insert(ip++, MOD);
					default: throw "Unknown binop " + op;
				}
			case EUnop(op, postFix, e):
				var isPostFix = postFix == UFPostfix;
				_compile(e);
				switch (op) {
					case UIncrement | UDecrement:
						var delta:OpCode = op == UIncrement ? INC : DNC;
						if(isPostFix) {
							instructions.insert(ip++, DUP);
							instructions.insert(ip++, delta);
							instructions.insert(ip++, SAVE); // TODO:
							// last value is the value before the unop
						} else {
							instructions.insert(ip++, delta);
							instructions.insert(ip++, DUP);
							instructions.insert(ip++, SAVE); // TODO:
							// last value is the value after the unop
						}
					case UNot: instructions.insert(ip++, NOT);
					case UNeg: instructions.insert(ip++, NEG);
					case UNegBits: instructions.insert(ip++, NGBITS);
					case USpread: throw "Spread not implemented";
				}
			case ECall(e, args):
				var program_func:ProgramFunc = null;
				var func_id:Int = -1;
				switch (e.expr) {
					case EConst(CIdent(name)):
						if (program.func_names.contains(name))
							program_func = program.program_funcs[func_id = program.func_names.indexOf(name)];
					default: throw "Call missing name";
				}

				if (program_func != null) {
					for (i => arg in program_func.args) {
						if(i > args.length-1)
							switch(arg) {
								case Defined(v): pushConstant(v);
								default: pushConstant(null);
							};
						else _compile(args[i]);
					}

					instructions.insert(ip++, LOCAL_CALL);
					read_only_stack.insert(rp++, func_id);
					if (!contains_ret(program_func.instructions))
						instructions.insert(ip++, POP);
				} else {
					_compile(e);
					for (a in args)
						_compile(a);
					read_only_stack.insert(rp++, args.length);
					instructions.insert(ip++, ARRAY_STACK);
					instructions.insert(ip++, CALL);

					// TODO: See if the return value is Void and if it is pop the val in HVM.hx
					instructions.insert(ip++, POP);
				}
			case EObjectDecl(fields):
				instructions.insert(ip++, PUSH_OBJECT);
				for (f in fields) {
					_compile(f.expr);
					pushConstant(f.field);
					instructions.insert(ip++, FIELD_SET);
				}
		}
	}

	public inline function set_compile_pointer(ip:Int, rp:Int) {
		this.ip = ip; this.rp = rp;
	}

	public function get_compile_pointer():Pointer {
		return new Pointer(ip, rp);
	}

	public function mk( e : ExprDef, ?pos : Pos = null ) : Expr {
		return { expr : e, pos : pos };
	}

	public function contains_ret(instructions:Array<OpCode>):Bool {
		for (instruction in instructions)
			if (instruction == RET) return true;
		return false;
	}
}
