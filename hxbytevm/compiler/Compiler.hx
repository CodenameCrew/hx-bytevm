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

	public function toString():String {
		return '<POINTER IP: $ip, RP: $rp>';
	}
}

class Compiler {
	public var program(default, null):Program;

	public var instructions:Array<OpCode>;
	public var read_only_stack:Array<StackValue>;

	public function new() {}

	public function reset() {
		program = Program.createEmpty(); depth = 0;
		pointers = []; pointer_counter = 0;
		declaredVars = [];

		instructions = program.instructions;
		read_only_stack = program.read_only_stack;

		compileFunctions = true;
	}

	public function getConstant(c:Dynamic) {
		if(program.constant_stack.contains(c)) return program.constant_stack.indexOf(c);
		program.constant_stack.push(c);
		return program.constant_stack.length-1;
	}

	public function pushConstant(c:Dynamic) {
		var idx = getConstant(c);
		read_only_stack.push(idx);
		instructions.push(PUSHC);
	}

	public var depth:Int = 0;

	public function getVar(name:String):Dynamic {
		for (varnames in program.varnames_stack) {
			var idx:Int = varnames.indexOf(name);
			if (idx != -1) return idx;
		}
		return -1;
	}

	public function getVarInDepth(name:String, ?depth:Int):Dynamic {
		for (i in 0...depth+1)
			if (program.varnames_stack[i] == null)
				program.varnames_stack[i] = [];

		var idx = program.varnames_stack[depth].indexOf(name);
		if(idx == -1) {
			program.varnames_stack[depth].push(name);
			return program.varnames_stack[depth].length-1;
		}
		return idx;
	}

	public function pushVar(vname:String) {
		var index:Int = -1;
		var depth:Int = this.depth;
		for (d => varnames in program.varnames_stack) {
			var idx:Int = varnames.indexOf(vname);
			if (idx != -1) {index = idx; depth = d; break;}
		}

		if(index == -1) index = getVarInDepth(vname, depth);

		read_only_stack.push(depth);
		read_only_stack.push(index);

		instructions.push(PUSHV_D);
	}

	public function getVarDepth(vname:String):Int {
		var depth:Int = this.depth;
		for (d => varnames in program.varnames_stack) {
			var idx:Int = varnames.indexOf(vname);
			if (idx != -1) {depth = d; break;}
		}
		return depth;
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

	var pointer_counter(default, null):Int = 0;
	public inline function getUniqueId():Int {
		return pointer_counter++;
	}

	public function compile(expr:Expr):Void {
		reset();
		_compileFunctions(expr);

		switch (expr.expr) {
			case EBlock(exprs): for (e in exprs) _compile(e);
			default: _compile(expr);
		}
		instructions.push(RET);

		compile_pointers();
	}

	private var compileFunctions:Bool = true;
	private function _compileFunctions(expr:Expr) {
		ExprUtils.recursive(expr, (e:Expr) -> {
			if (e == null || e.expr == null) return;
			switch(e.expr) {
				case EFunction(func_kind, func): _compile(e);
				default:
			}
		});
		compileFunctions = false;
	}

	private var declaredVars:Array<String> = [];

	private function _compile(expr:Expr) {
		if (expr == null || expr.expr == null) return;

		switch (expr.expr) {
			case EConst(c):
				switch (c) {
					case CInt(v, suffix): pushConstant(v);
					case CFloat(v, suffix): pushConstant(v);
					case CString(v, _): pushConstant(v);
					case CIdent("null"): instructions.push(PUSH_NULL);
					case CIdent("true"): instructions.push(PUSH_TRUE);
					case CIdent("false"): instructions.push(PUSH_FALSE);
					case CIdent(v): pushVar(v);
					case CRegexp(r, o): {
						pushConstant(EReg);
						instructions.push(PUSH);

						pushConstant(r);
						pushConstant(o);
						read_only_stack.push(2);
						instructions.push(ARRAY_STACK);
						instructions.push(NEW);
					}
				}
			case EBlock(exprs):
				var old = declaredVars.length;
				instructions.push(DEPTH_INC);
				depth++;
				for (e in exprs) {
					_compile(e);
				}
				depth--;
				instructions.push(DEPTH_DNC);
				declaredVars = declaredVars.slice(0, old);
			case ETry(e, catches):
				trace("Try statement not implemented");
				_compile(e);
				/*
				var old = declaredVars.length;
				instructions.push(DEPTH_INC);
				_compile(e);
				instructions.push(DEPTH_DNC);
				for (c in catches) {
					var caseLabel = pointer(getUniqueId());
					read_only_stack.push(caseLabel);
					instructions.push(JUMP_N_COND);
					_compile(c.expr);
					read_only_stack.push(caseLabel);
					instructions.push(JUMP);
				}
				declaredVars = declaredVars.slice(0, old);*/
			case EMeta(m, e):
				// TODO: handle bypassAccessor
				_compile(e);
			case ECast(e, type):
				_compile(e);
				// TODO: cast
				//pushConstant(type);
				//instructions.push(CAST);
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
						read_only_stack.push(cls);
						instructions.push(IS);
					default:
						trace("Unknown type " + type);
						trace("Skipping is for " + e);
				}
				// TODO: is
				//instructions.push(IS);
			case ENew(path, expr):
				var pack = HelperUtils.getPackFromTypePath(path.path);
				if(declaredVars.contains(pack)) {
					// Push from vars
				} else {
					var cls = Type.resolveClass(pack);
					if (cls == null)
						throw "Unknown class";
					read_only_stack.push(cls);
					instructions.push(PUSH);
				}
				//pushConstant(path);
				for (e in expr) {
					_compile(e);
				}
				read_only_stack.push(expr.length);
				instructions.push(ARRAY_STACK);
				instructions.push(NEW);
			case ESwitch(e, cases, edef):
				throw "Switch statement not implemented";
				/*var old = declaredVars.length;
				instructions.push(DEPTH_INC);
				_compile(e);
				instructions.push(DEPTH_DNC);
				for (c in cases) {
					var caseLabel = pointer(getUniqueId());
					read_only_stack.push(caseLabel);
					instructions.push(JUMP_N_COND);
					_compile(c.expr);
					read_only_stack.push(caseLabel);
					instructions.push(JUMP);
				}
				if (edef != null) {
					read_only_stack.push(pointer(getUniqueId()));
					_compile(edef);
					read_only_stack.push(caseLabel);
					instructions.push(JUMP);
				}
				declaredVars = declaredVars.slice(0, old);*/
			case ESwitchComplex(e, cases, edef):
				throw "Complex Switch statement not implemented";
			case EParenthesis(expr):
				_compile(expr);
			case EVars(vars):
				for (v in vars) {
					// todo handle isFinal, isStatic, isPublic
					declaredVars.push(v.name.string);
					_compile(v.expr);
					if(depth == 0) {
						read_only_stack.push(getVarInDepth(v.name.string, depth));
						instructions.push(SAVE);
					}
				}
			case EIf(econd, eif, eelse) | ETernary(econd, eif, eelse):
				var end_p = pointer();
				var a1_p = pointer();
				_compile(econd);
				read_only_stack.push(a1_p);
				instructions.push(JUMP_N_COND); // jump to label a1 if econd is false
				_compile(eif);
				if(eelse != null) {
					read_only_stack.push(end_p);
					instructions.push(JUMP); // jump to pointer END
				}
				// pointer A1
				pointer_update(a1_p);
				if (eelse != null) {
					_compile(eelse);
				}
				pointer_update(end_p);
				// pointer END
			case EWhile(econd, e, flag):
				switch (flag) {
					case WFNormalWhile:
						// label START
						var start_p = pointer();
						var end_p = pointer();
						pointer_update(start_p); // test
						_compile(econd);
						// TODO: helper function to make this cleaner
						read_only_stack.push(end_p);
						instructions.push(JUMP_N_COND); // to label END
						_compile(e);
						read_only_stack.push(start_p);
						instructions.push(JUMP); // to label START

						pointer_update(end_p);
					case WFDoWhile:
						var start = pointer();
						_compile(e);
						_compile(econd);
						read_only_stack.push(start);
						instructions.push(JUMP_COND);
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

				instructions.push(DEPTH_INC);

				read_only_stack.push(it);
				instructions.push(PUSH);

				_compile(mk(EField(iter, "hasNext", EFNormal)));
				_compile(mk(EField(iter, "next", EFNormal)));

				// continueBreakStack.push(instructions.length); // marks the start of the loop
				// continueBreakStackLabel.push(pointer());
				read_only_stack.push(-1); // hasNext
				instructions.push(STK_OFF);
				instructions.push(PUSH_ARRAY);
				instructions.push(CALL);
				instructions.push(JUMP_N_COND);
				// inner body

				read_only_stack.push(-0); // next
				instructions.push(STK_OFF);
				instructions.push(CALL);

				if(hasKey) {
					// keyvar = next.key;
						instructions.push(DUP);
						read_only_stack.push("key");
						instructions.push(FIELD_GET);

						read_only_stack.push(keyvar);
						instructions.push(SAVE);

					// valuevar = next.value;
						read_only_stack.push("value");
						instructions.push(FIELD_GET);

						read_only_stack.push(valuevar);
						instructions.push(SAVE);
				} else {
					// valuevar = next;
						read_only_stack.push(valuevar);
						instructions.push(SAVE);
				}

				_compile(expr);
				_compile(mk(EContinue));

				// continueBreakStackLabel[continueBreakStackLabel.length - 1].pos = instructions.length;

				instructions.push(POP); // Pop the next function
				instructions.push(POP); // Pop the hasNext function

				instructions.push(DEPTH_DNC);

				// continueBreakStack.pop();
				// continueBreakStackLabel.pop();
			case EBreak:
				// read_only_stack.push(continueBreakStackLabel[continueBreakStackLabel.length - 1]);
				instructions.push(JUMP);
			case EContinue:
				// read_only_stack.push(continueBreakStack[continueBreakStack.length - 1]);
				instructions.push(JUMP_COND);
			case EThrow(e):
				_compile(e);
				// instructions.push(THROW);
			case EReturn(e):
				if(e != null)
					_compile(e);
				else
					instructions.push(PUSH_NULL);
				instructions.push(RET);
			case EFunction(name, func) if (compileFunctions):
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
						var old = declaredVars.length;
						instructions.push(DEPTH_INC);
						depth++;

						for (arg in new ReverseArrayIterator(func.args)) {
							read_only_stack.push(getVarInDepth(arg.name.string, depth));
							instructions.push(SAVE);
						}

						for (e in exprs)
							_compile(e);

						depth--;
						if (!contains_ret(instructions)) instructions.push(DEPTH_DNC);
						declaredVars = declaredVars.slice(0, old);

						// Add depth decreases before function returns
						var i:Int = 0;
						while (i < instructions.length) {
							var instruction = instructions[i];
							if (instruction == RET) {
								instructions[i] = DEPTH_DNC;
								instructions.insert(i+1, RET);
								i++;
							}
							i++;
						}
					case _:
						throw "Functions must be in blocks";
				}

				instructions = program.instructions;
				read_only_stack = program.read_only_stack;

				switch (name) {
					case FNamed(placed_name, isInline):
						program.program_funcs.push(program_func);
						program.func_names.push(placed_name.string);
					// TODO: Make like IDs for these and connect then to the expr
					case FAnonymous:
					case FArrow:
				}
			case EField(e, field, safe):
				var isSafe = safe == EFSafe;
					var end_p = pointer();
					var null_p = pointer();
					_compile(e);
					if(isSafe) {
						instructions.push(DUP);
						instructions.push(PUSH_NULL);
						instructions.push(EQ);
						read_only_stack.push(null_p);
						instructions.push(JUMP_COND);
					}
					pushConstant(field);
					instructions.push(FIELD_GET);
					if(isSafe) {
						read_only_stack.push(end_p);
						instructions.push(JUMP_COND);
						pointer_update(null_p);
						instructions.push(PUSH_NULL);
					}
					pointer_update(end_p);
			case EArray(e1, e2):
				_compile(e1); // arr
				_compile(e2); // index
				instructions.push(ARRAY_GET);
			case EArrayDecl(values):
				// TODO: map support
				for (v in values) {
					_compile(v);
				}
				read_only_stack.push(values.length);
				instructions.push(ARRAY_STACK);
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
				read_only_stack.push(end_p);
				instructions.push(JUMP_N_COND); // 0 // to at the of this
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
				read_only_stack.push(end_p);
				instructions.push(JUMP_COND); // 0 // to at the of this
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
				instructions.push(PUSH_NULL);
				instructions.push(EQ);
				read_only_stack.push(end_p);
				instructions.push(JUMP_N_COND); // 0 // to at the of this
				_compile(e2); // 1
				pointer_update(end_p);
			case EBinop(BOpAssign, e1, e2):
				var varname:String = HelperUtils.getIdentFromExpr(e1);
				_compile(e2);

				read_only_stack.push(getVarDepth(varname));
				read_only_stack.push(getVarInDepth(varname, read_only_stack[read_only_stack.length-1]));

				instructions.push(SAVE_D);

			case EBinop(BOpAssignOp(op), e1, e2):
				throw "BinopAssignOp not implemented";
				/*_compile(e1);
				_compile(e2);
				switch (op) {
					case BOpAdd: instructions.push(ADD);
					case BOpSub: instructions.push(SUB);
					case BOpMult: instructions.push(MULT);
					case BOpDiv: instructions.push(DIV);
					case BOpEq: instructions.push(EQ);
					case BOpNotEq: instructions.push(NEQ);
					case BOpGt: instructions.push(GT);
					case BOpGte: instructions.push(GTE);
					case BOpLt: instructions.push(LT);
					case BOpLte: instructions.push(LTE);
					case BOpAnd: instructions.push(AND);
					case BOpOr: instructions.push(OR);
					case BOpXor: instructions.push(XOR);
					case BOpShl: instructions.push(SHL);
					case BOpShr: instructions.push(SHR);
					case BOpUshr: instructions.push(USHR);
					case BOpMod: instructions.push(MOD);
					//default: throw "Unknown binop " + op;
				}*/
			case EBinop(op, e1, e2):
				_compile(e1);
				_compile(e2);
				switch (op) {
					case BOpAdd: instructions.push(ADD);
					case BOpSub: instructions.push(SUB);
					case BOpMult: instructions.push(MULT);
					case BOpDiv: instructions.push(DIV);
					case BOpEq: instructions.push(EQ);
					case BOpNotEq: instructions.push(NEQ);
					case BOpGt: instructions.push(GT);
					case BOpGte: instructions.push(GTE);
					case BOpLt: instructions.push(LT);
					case BOpLte: instructions.push(LTE);
					case BOpAnd: instructions.push(AND);
					case BOpOr: instructions.push(OR);
					case BOpXor: instructions.push(XOR);
					case BOpShl: instructions.push(SHL);
					case BOpShr: instructions.push(SHR);
					case BOpUShr: instructions.push(USHR);
					case BOpMod: instructions.push(MOD);
					default: throw "Unknown binop " + op;
				}
			case EUnop(op, postFix, e):
				var isPostFix = postFix == UFPostfix;
				_compile(e);
				switch (op) {
					case UIncrement | UDecrement:
						var delta:OpCode = op == UIncrement ? INC : DNC;
						if(isPostFix) {
							instructions.push(DUP);
							instructions.push(delta);
							instructions.push(SAVE); // TODO:
							// last value is the value before the unop
						} else {
							instructions.push(delta);
							instructions.push(DUP);
							instructions.push(SAVE); // TODO:
							// last value is the value after the unop
						}
					case UNot: instructions.push(NOT);
					case UNeg: instructions.push(NEG);
					case UNegBits: instructions.push(NGBITS);
					case USpread: throw "Spread not implemented";
				}
			case ECall(e, args):
				var program_func:ProgramFunc = null;
				var func_id:Int = -1;
				switch (e.expr) {
					case EConst(CIdent(name)):
						if (program.func_names.contains(name))
							program_func = program.program_funcs[func_id = program.func_names.indexOf(name)];
					default:
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

					instructions.push(LOCAL_CALL);
					read_only_stack.push(func_id);
					if (!contains_ret(program_func.instructions))
						instructions.push(POP);
				} else {
					_compile(e);
					for (a in args)
						_compile(a);
					read_only_stack.push(args.length);
					instructions.push(ARRAY_STACK);
					instructions.push(CALL);

					instructions.push(POP); // TODO: See if the return value is Void and if it is pop the val in HVM.hx
				}
			case EObjectDecl(fields):
				instructions.push(PUSH_OBJECT);
				for (f in fields) {
					_compile(f.expr);
					pushConstant(f.field);
					instructions.push(FIELD_SET);
				}
			default:
		}

		// trace(expr.expr);
		// Sys.println(program.print());
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
