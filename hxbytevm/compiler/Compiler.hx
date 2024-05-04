package hxbytevm.compiler;

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

	public function new() {}

	public function reset() {
		program = Program.createEmpty(); depth = 0;
		pointers = []; pointer_counter = 0;
		declaredVars = [];
	}

	public function getConstant(c:Dynamic) {
		if(program.constant_stack.contains(c)) return program.constant_stack.indexOf(c);
		program.constant_stack.push(c);
		return program.constant_stack.length-1;
	}

	public function pushConstant(c:Dynamic) {
		var idx = getConstant(c);
		program.read_only_stack.push(idx);
		trace("Pushed constant " + c + " to stack at index " + idx);
		program.instructions.push(PUSHC);
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
		if (program.varnames_stack[depth] == null)
			program.varnames_stack[depth] = [];

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
		for (d in 0...program.varnames_stack.length) {
			if(program.varnames_stack[d] == null) program.varnames_stack[d] = [];
			var idx:Int = program.varnames_stack[d].indexOf(vname);
			if (idx != -1) {index = idx; depth = d; break;}
		}

		if(index == -1) index = getVarInDepth(vname, depth);

		program.read_only_stack.push(depth);
		program.read_only_stack.push(index);

		program.instructions.push(PUSHV_D);
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
		var pointer = new Pointer(program.instructions.length, get_rom_len());
		pointers.push(pointer);
		return pointer;
	}

	public function pointer_update(pointer:Pointer) {
		pointer.ip = program.instructions.length;
		pointer.rp = get_rom_len();
	}

	public inline function get_rom_len():Int {
		var len:Int = program.read_only_stack.length;
		for (rom in program.read_only_stack)
			if (rom is Pointer) len++;
		return len;
	}

	public function compile_pointers() {
		var i:Int = 0;
		while (i < program.read_only_stack.length) {
			var rom = program.read_only_stack[i];
			if (rom is Pointer) {
				var ip:Int = rom.ip;
				var rp:Int = rom.rp;

				program.read_only_stack[i] = ip;
				program.read_only_stack.insert(i+1, rp);
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

		switch (expr.expr) {
			case EBlock(exprs): for (e in exprs) _compile(e);
			default: _compile(expr);
		}
		program.instructions.push(RET);

		compile_pointers();
	}

	private var declaredVars:Array<String> = [];

	private function _compile(expr:Expr) {
		trace("Compiling " + expr.expr);
		switch (expr.expr) {
			case EConst(c):
				switch (c) {
					case CInt(v, suffix): pushConstant(v);
					case CFloat(v, suffix): pushConstant(v);
					case CString(v, _): pushConstant(v);
					case CIdent("null"): program.instructions.push(PUSH_NULL);
					case CIdent("true"): program.instructions.push(PUSH_TRUE);
					case CIdent("false"): program.instructions.push(PUSH_FALSE);
					case CIdent(v): pushVar(v);
					case CRegexp(r, o): {
						pushConstant(EReg);
						program.instructions.push(PUSH);

						pushConstant(r);
						pushConstant(o);
						program.read_only_stack.push(2);
						program.instructions.push(ARRAY_STACK);
						program.instructions.push(NEW);
					}
				}
			case EBlock(exprs):
				var old = declaredVars.length;
				program.instructions.push(DEPTH_INC);
				depth++;
				for (e in exprs) {
					_compile(e);
				}
				depth--;
				program.instructions.push(DEPTH_DNC);
				declaredVars = declaredVars.slice(0, old);
			case ETry(e, catches):
				trace("Try statement not implemented");
				_compile(e);
				/*
				var old = declaredVars.length;
				program.instructions.push(DEPTH_INC);
				_compile(e);
				program.instructions.push(DEPTH_DNC);
				for (c in catches) {
					var caseLabel = pointer(getUniqueId());
					program.read_only_stack.push(caseLabel);
					program.instructions.push(JUMP_N_COND);
					_compile(c.expr);
					program.read_only_stack.push(caseLabel);
					program.instructions.push(JUMP);
				}
				declaredVars = declaredVars.slice(0, old);*/
			case EMeta(m, e):
				// TODO: handle bypassAccessor
				_compile(e);
			case ECast(e, type):
				_compile(e);
				// TODO: cast
				//pushConstant(type);
				//program.instructions.push(CAST);
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
						program.read_only_stack.push(cls);
						program.instructions.push(IS);
					default:
						trace("Unknown type " + type);
						trace("Skipping is for " + e);
				}
				// TODO: is
				//program.instructions.push(IS);
			case ENew(path, expr):
				var pack = HelperUtils.getPackFromTypePath(path.path);
				if(declaredVars.contains(pack)) {
					// Push from vars
				} else {
					var cls = Type.resolveClass(pack);
					if (cls == null)
						throw "Unknown class";
					program.read_only_stack.push(cls);
					program.instructions.push(PUSH);
				}
				//pushConstant(path);
				for (e in expr) {
					_compile(e);
				}
				program.read_only_stack.push(expr.length);
				program.instructions.push(ARRAY_STACK);
				program.instructions.push(NEW);
			case ESwitch(e, cases, edef):
				throw "Switch statement not implemented";
				/*var old = declaredVars.length;
				program.instructions.push(DEPTH_INC);
				_compile(e);
				program.instructions.push(DEPTH_DNC);
				for (c in cases) {
					var caseLabel = pointer(getUniqueId());
					program.read_only_stack.push(caseLabel);
					program.instructions.push(JUMP_N_COND);
					_compile(c.expr);
					program.read_only_stack.push(caseLabel);
					program.instructions.push(JUMP);
				}
				if (edef != null) {
					program.read_only_stack.push(pointer(getUniqueId()));
					_compile(edef);
					program.read_only_stack.push(caseLabel);
					program.instructions.push(JUMP);
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
					//if(depth == 0) { // todo we dont need variables for non 0-depth
						program.read_only_stack.push(getVarInDepth(v.name.string, depth));
						program.instructions.push(SAVE);
					//}
				}
			case EIf(econd, eif, eelse) | ETernary(econd, eif, eelse):
				var end_p = pointer();
				var a1_p = pointer();
				_compile(econd);
				program.read_only_stack.push(a1_p);
				program.instructions.push(JUMP_N_COND); // jump to label a1 if econd is false
				_compile(eif);
				if(eelse != null) {
					program.read_only_stack.push(end_p);
					program.instructions.push(JUMP); // jump to pointer END
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
						program.read_only_stack.push(end_p);
						program.instructions.push(JUMP_N_COND); // to label END
						_compile(e);
						program.read_only_stack.push(start_p);
						program.instructions.push(JUMP); // to label START
						pointer_update(end_p);
					case WFDoWhile:
						var start = pointer();
						_compile(e);
						_compile(econd);
						program.read_only_stack.push(start);
						program.instructions.push(JUMP_COND);
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

				program.instructions.push(DEPTH_INC); depth++;

				program.read_only_stack.push(it);
				program.instructions.push(PUSH);

				_compile(mk(EField(iter, "hasNext", EFNormal)));
				_compile(mk(EField(iter, "next", EFNormal)));

				// continueBreakStack.push(program.instructions.length); // marks the start of the loop
				// continueBreakStackLabel.push(pointer());
				program.read_only_stack.push(-1); // hasNext
				program.instructions.push(STK_OFF);
				program.read_only_stack.push(0);
				program.instructions.push(CALL);
				program.instructions.push(JUMP_N_COND);
				// inner body

				program.read_only_stack.push(-0); // next
				program.instructions.push(STK_OFF);
				program.read_only_stack.push(0);
				program.instructions.push(CALL);

				if(hasKey) {
					// keyvar = next.key;
						program.instructions.push(DUP);
						program.read_only_stack.push("key");
						program.instructions.push(FIELD_GET);

						program.read_only_stack.push(getVarInDepth(keyvar, depth));
						program.instructions.push(SAVE);

					// valuevar = next.value;
						program.read_only_stack.push("value");
						program.instructions.push(FIELD_GET);

						program.read_only_stack.push(getVarInDepth(valuevar, depth));
						program.instructions.push(SAVE);
				} else {
					// valuevar = next;
						program.read_only_stack.push(getVarInDepth(valuevar, depth));
						program.instructions.push(SAVE);
				}

				_compile(expr);
				_compile(mk(EContinue));

				// continueBreakStackLabel[continueBreakStackLabel.length - 1].pos = program.instructions.length;

				program.instructions.push(POP); // Pop the next function
				program.instructions.push(POP); // Pop the hasNext function

				program.instructions.push(DEPTH_DNC); depth--;

				// continueBreakStack.pop();
				// continueBreakStackLabel.pop();
			case EBreak:
				// program.read_only_stack.push(continueBreakStackLabel[continueBreakStackLabel.length - 1]);
				program.instructions.push(JUMP);
			case EContinue:
				// program.read_only_stack.push(continueBreakStack[continueBreakStack.length - 1]);
				program.instructions.push(JUMP_COND);
			case EThrow(e):
				_compile(e);
				// program.instructions.push(THROW);
			case EReturn(e):
				if(e != null)
					_compile(e);
				else
					program.instructions.push(PUSH_NULL);
				program.instructions.push(RET);
			case EFunction(kind, f):
				// Hacky method to make it skip the function, todo make it place it at the end of the program
				var skipFunc_p = pointer();
				program.read_only_stack.push(skipFunc_p);
				program.instructions.push(JUMP);

				var func = f.expr;
				var args = f.args;

				var func_s = pointer();

				program.instructions.push(DEPTH_INC); depth++;

				trace("Compiling function");

				// Stack: [args]

				/*
				for (i in 0...fargs.length) {
					if(fargs[i].opt) {
						if(i > args.length) {
							if(fargs[i].value != null) {
								_compile(fargs[i].value);
							} else {
								push(null);
							}
						} else {
							push(args[i]);
						}
					} else {
						push(args[i]);
					}
				*/


				// TODO: maybe make a op code for this?
				for(i in 0...args.length) {
					var pushArgPointer = pointer();
					var endPointer = pointer();
					var arg = args[i];
					if(arg.opt) {
						program.instructions.push(LENGTH); // Stack: [args, args.length]
						pushConstant(i); // Stack: [args, args.length, i]
						program.instructions.push(LT); // Stack: [args, args.length < i]
						program.read_only_stack.push(pushArgPointer);
						program.instructions.push(JUMP_N_COND); // Stack: [args]
						var value = arg.value;
						if(value != null) { // make it so args[i] == null runs the default value (TODO: test if this happens)
							_compile(value); // Stack: [args, value]
						} else {
							program.instructions.push(PUSH_NULL); // Stack: [args, null]
						}
						program.read_only_stack.push(endPointer);
						program.instructions.push(JUMP);
					}
					pointer_update(pushArgPointer);
					pushConstant(i);
					program.instructions.push(ARRAY_GET); // Stack: [args, args[i]]
					pointer_update(endPointer);

					getVarInDepth(arg.name.string, depth);
					program.instructions.push(POP); // TODO: arguments
					//program.read_only_stack.push(getVarInDepth(arg.name.string, depth));
					program.instructions.push(SAVE_D);
				}

				// yea
				// makes blocks not increase scope
				switch(func.expr) {
					case EBlock(exprs):
						for (e in exprs) {
							_compile(e);
						}
					default:
						_compile(func);
				}

				program.instructions.push(DEPTH_DNC); depth--;
				program.instructions.push(RET);

				pointer_update(skipFunc_p);


				/*PUSH LOCAL_FUNC_POINTER
				PUSH_NULL
				ARRAY_STACK (ROM: 1)
				LOCAL_CALL (SAVES IP AND RP TO THE FUNCSTACK)


				FUNC
					PUSHC ("HELLO WORLD")
					ARRAY_STACK (ROM: 1)
					CALL // so then how would we have normal function returns?
					// a new stack??????
					// yea, lets just do it, then afterwards we can refine it
					// huh it might be faster but ehhhhhh idk
					RET // POPS THE IP AND RP FROM THE FUNCSTACK
					// hmmmmmmm i gues
					// so lemme make the LOCAL_CALL
					// ill do the stuf in hvm to make this work

				*/
				//var func_end_p = pointer();

				switch(kind) {
					case FArrow | FAnonymous:
						program.read_only_stack.push(func_s);
						program.instructions.push(PUSH); // make the function be on the stack
					case FNamed(name, isInline):
						program.read_only_stack.push(func_s);
						program.instructions.push(PUSH);
						program.read_only_stack.push(getVarInDepth(name.string, depth));
						program.instructions.push(SAVE);
						pushVar(name.string);
						program.function_pointers.set(name.string, func_s); // TODO: store min args
				}

				trace("Compiled function");

			case EField(e, field, safe):
				var isSafe = safe == EFSafe;
				var end_p = pointer();
				var null_p = pointer();
				_compile(e);
				if(isSafe) {
					program.instructions.push(DUP);
					program.instructions.push(PUSH_NULL);
					program.instructions.push(EQ);
					program.read_only_stack.push(null_p);
					program.instructions.push(JUMP_COND);
				}
				pushConstant(field);
				program.instructions.push(FIELD_GET);
				if(isSafe) {
					program.read_only_stack.push(end_p);
					program.instructions.push(JUMP_COND);
					pointer_update(null_p);
					program.instructions.push(PUSH_NULL);
				}
				pointer_update(end_p);
			case EArray(e1, e2):
				_compile(e1); // arr
				_compile(e2); // index
				program.instructions.push(ARRAY_GET);
			case EArrayDecl(values):
				// TODO: map support
				for (v in values) {
					_compile(v);
				}
				program.read_only_stack.push(values.length);
				program.instructions.push(ARRAY_STACK);
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
				program.read_only_stack.push(end_p);
				program.instructions.push(JUMP_N_COND); // 0 // to at the of this
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
				program.read_only_stack.push(end_p);
				program.instructions.push(JUMP_COND); // 0 // to at the of this
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
				program.instructions.push(PUSH_NULL);
				program.instructions.push(EQ);
				program.read_only_stack.push(end_p);
				program.instructions.push(JUMP_N_COND); // 0 // to at the of this
				_compile(e2); // 1
				pointer_update(end_p);
			case EBinop(BOpAssign, e1, e2):
				var varname:String = HelperUtils.getIdentFromExpr(e1);
				_compile(e2);

				program.read_only_stack.push(getVarDepth(varname));
				program.read_only_stack.push(getVarInDepth(varname, program.read_only_stack[program.read_only_stack.length-1]));

				program.instructions.push(SAVE_D);

			case EBinop(BOpAssignOp(op), e1, e2):
				throw "BinopAssignOp not implemented";
				/*_compile(e1);
				_compile(e2);
				switch (op) {
					case BOpAdd: program.instructions.push(ADD);
					case BOpSub: program.instructions.push(SUB);
					case BOpMult: program.instructions.push(MULT);
					case BOpDiv: program.instructions.push(DIV);
					case BOpEq: program.instructions.push(EQ);
					case BOpNotEq: program.instructions.push(NEQ);
					case BOpGt: program.instructions.push(GT);
					case BOpGte: program.instructions.push(GTE);
					case BOpLt: program.instructions.push(LT);
					case BOpLte: program.instructions.push(LTE);
					case BOpAnd: program.instructions.push(AND);
					case BOpOr: program.instructions.push(OR);
					case BOpXor: program.instructions.push(XOR);
					case BOpShl: program.instructions.push(SHL);
					case BOpShr: program.instructions.push(SHR);
					case BOpUshr: program.instructions.push(USHR);
					case BOpMod: program.instructions.push(MOD);
					//default: throw "Unknown binop " + op;
				}*/
			case EBinop(op, e1, e2):
				_compile(e1);
				_compile(e2);
				switch (op) {
					case BOpAdd: program.instructions.push(ADD);
					case BOpSub: program.instructions.push(SUB);
					case BOpMult: program.instructions.push(MULT);
					case BOpDiv: program.instructions.push(DIV);
					case BOpEq: program.instructions.push(EQ);
					case BOpNotEq: program.instructions.push(NEQ);
					case BOpGt: program.instructions.push(GT);
					case BOpGte: program.instructions.push(GTE);
					case BOpLt: program.instructions.push(LT);
					case BOpLte: program.instructions.push(LTE);
					case BOpAnd: program.instructions.push(AND);
					case BOpOr: program.instructions.push(OR);
					case BOpXor: program.instructions.push(XOR);
					case BOpShl: program.instructions.push(SHL);
					case BOpShr: program.instructions.push(SHR);
					case BOpUShr: program.instructions.push(USHR);
					case BOpMod: program.instructions.push(MOD);
					default: throw "Unknown binop " + op;
				}
			case EUnop(op, postFix, e):
				var isPostFix = postFix == UFPostfix;
				_compile(e);
				switch (op) {
					case UIncrement | UDecrement:
						var delta:OpCode = op == UIncrement ? INC : DNC;
						if(isPostFix) {
							program.instructions.push(DUP);
							program.instructions.push(delta);
							program.instructions.push(SAVE); // TODO:
							// last value is the value before the unop
						} else {
							program.instructions.push(delta);
							program.instructions.push(DUP);
							program.instructions.push(SAVE); // TODO:
							// last value is the value after the unop
						}
					case UNot: program.instructions.push(NOT);
					case UNeg: program.instructions.push(NEG);
					case UNegBits: program.instructions.push(NGBITS);
					case USpread: throw "Spread not implemented";
				}
			case ECall(e, args):
				var isLocal = false;
				var localPointer = null;
				switch (e.expr) {
					case EConst(CIdent(name)):
						var func_s = program.function_pointers.get(name);
						if (func_s != null) {
							isLocal = true;
							localPointer = func_s;
						}
					default:
				}

				if(isLocal) {
					program.read_only_stack.push(localPointer);
					for (a in args) {
						_compile(a);
					}
					program.read_only_stack.push(args.length);
					program.instructions.push(LOCAL_CALL);
				} else {
					_compile(e);
					for (a in args) {
						_compile(a);
					}
					program.read_only_stack.push(args.length);
					program.instructions.push(CALL);

					// TODO: check if anything uses return and do not pop it if it does
					program.instructions.push(POP); // the return val gets pushed to stack by CALL
				}
			case EObjectDecl(fields):
				program.instructions.push(PUSH_OBJECT);
				for (f in fields) {
					_compile(f.expr);
					pushConstant(f.field);
					program.instructions.push(FIELD_SET);
				}

		}
		trace(expr.expr);
		trace(program.print());
	}

	public function mk( e : ExprDef, ?pos : Pos = null ) : Expr {
		return { expr : e, pos : pos };
	}
}
