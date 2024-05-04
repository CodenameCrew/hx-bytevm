package hxbytevm.compilier;

import hxbytevm.utils.HelperUtils;
import hxbytevm.vm.OpCode;
import hxbytevm.utils.RuntimeUtils;
import hxbytevm.core.Ast;
import hxbytevm.vm.Program;

class Label {
	public var name:String;
	public var pos:Int;

	public function new(name:String, ?pos:Int = -1) {
		this.name = name;
		this.pos = pos;
	}
}

class Compilier {
	public var program(default, null):Program;

	public function new() {
		program = Program.createEmpty();
	}

	public function getConstant(c:Dynamic) {
		if(program.constant_stack.contains(c)) return program.constant_stack.indexOf(c);
		program.constant_stack.push(c);
		return program.constant_stack.length-1;
	}

	public function pushConstant(c:Dynamic) {
		var idx = getConstant(c);
		program.read_only_stack.push(idx);
		program.instructions.push(PUSHC);
	}

	public var depth:Int = 0;

	public function getVar(name:String):Dynamic {
		if (program.varnames_stack[depth] == null)
			program.varnames_stack[depth] = [];

		var idx = program.varnames_stack[depth].indexOf(name);
		if(idx == -1) {
			program.varnames_stack[depth].push(name);
			return program.varnames_stack.length-1;
		}
		return idx;
	}

	private var labels:Array<Map<String, Label>> = [];
	private var label_pos:Array<Int> = [];

	private function pushLabelBlock() {
		label_pos.push(program.read_only_stack.length);
		labels.push(new Map());
	}

	private function popLabelBlock() {
		fixLabels(label_pos.pop());
	}

	public function setLabel(name:String, index:Int = -1) {
		var label = new Label(name, index);
		labels[labels.length - 1].set(name, label);
		return label;
	}

	var label_counter(default, null):Int = 0;
	public function getUniqueId():String {
		return "__LBL_" + label_counter++;
	}

	public function fixLabels(after:Int = 0) {
		for(i in after...program.read_only_stack.length) {
			var v = program.read_only_stack[i];
			if(Std.isOfType(v, Label)) {
				var l:Label = cast v;
				var idx = labels[labels.length - 1].get(l.name);
				if(idx == null) {
					throw "Label " + l.name + " not found";
				}
				program.read_only_stack[i] = idx;
			}
		}
	}

	// TODO: we need a utils class
	public function getIdentFromExpr(e: Expr): String {
		switch (e.expr) {
			case EConst(c):
				return switch (c) {
					case CIdent(s): s;
					default: null;
				}
			default:
		}
		return null;
	}

	public function compile(expr:Expr):Void {
		switch (expr.expr) {
			case EBlock(exprs):
				for (e in exprs) { // to prevent depth increase
					_compile(e);
				}
			default:
				_compile(expr);
		}
		program.instructions.push(RET);
	}

	private var continueBreakStack:Array<Int> = [];
	private var continueBreakStackLabel:Array<Label> = [];

	private var declaredVars:Array<String> = [];

	private function _compile(expr:Expr) {
		switch (expr.expr) {
			case EConst(c):
				switch (c) {
					case CInt(v, suffix): pushConstant(v);
					case CFloat(v, suffix): pushConstant(v);
					case CString(v, _): pushConstant(v);
					case CIdent(v): throw "Identifier not implemented";
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
				for (e in exprs) {
					_compile(e);
				}
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
					var caseLabel = setLabel(getUniqueId());
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
					var caseLabel = setLabel(getUniqueId());
					program.read_only_stack.push(caseLabel);
					program.instructions.push(JUMP_N_COND);
					_compile(c.expr);
					program.read_only_stack.push(caseLabel);
					program.instructions.push(JUMP);
				}
				if (edef != null) {
					program.read_only_stack.push(setLabel(getUniqueId()));
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
					if(depth == 0) {
						program.read_only_stack.push(getVar(v.name.string));
						program.instructions.push(SAVE);
					}
				}
			case EIf(econd, eif, eelse) | ETernary(econd, eif, eelse):
				pushLabelBlock();
					var endLabel = setLabel(getUniqueId());
					var a1Label = setLabel(getUniqueId());
					_compile(econd);
					program.read_only_stack.push(a1Label);
					program.instructions.push(JUMP_N_COND); // jump to label a1 if econd is false
					_compile(eif);
					if(eelse != null) {
						program.read_only_stack.push(endLabel);
						program.instructions.push(JUMP); // jump to label END
					}
					// label A1
					a1Label.pos = program.instructions.length;
					if (eelse != null) {
						_compile(eelse);
					}
					endLabel.pos = program.instructions.length;
				popLabelBlock();
				// label END
			case EWhile(econd, e, flag):
				switch (flag) {
					case WFNormalWhile:
						var r = program.instructions.length;
						// label START
						_compile(econd);
						program.instructions.push(JUMP_N_COND); // to label END
						_compile(e);
						program.read_only_stack.push(r);
						program.instructions.push(JUMP); // to label START
						// label END
					case WFDoWhile:
						var r = program.instructions.length;
						_compile(e);
						_compile(econd);
						program.read_only_stack.push(r);
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

				program.instructions.push(DEPTH_INC);

				program.read_only_stack.push(it);
				program.instructions.push(PUSH);

				_compile(mk(EField(iter, "hasNext", EFNormal)));
				_compile(mk(EField(iter, "next", EFNormal)));

				pushLabelBlock();
				continueBreakStack.push(program.instructions.length); // marks the start of the loop
				continueBreakStackLabel.push(setLabel(getUniqueId()));
				program.read_only_stack.push(-1); // hasNext
				program.instructions.push(STK_OFF);
				program.instructions.push(PUSH_ARRAY);
				program.instructions.push(CALL);
				program.instructions.push(JUMP_N_COND);
				// inner body

				program.read_only_stack.push(-0); // next
				program.instructions.push(STK_OFF);
				program.instructions.push(CALL);

				if(hasKey) {
					// keyvar = next.key;
						program.instructions.push(DUP);
						program.read_only_stack.push("key");
						program.instructions.push(FIELD_GET);

						program.read_only_stack.push(keyvar);
						program.instructions.push(SAVE);

					// valuevar = next.value;
						program.read_only_stack.push("value");
						program.instructions.push(FIELD_GET);

						program.read_only_stack.push(valuevar);
						program.instructions.push(SAVE);
				} else {
					// valuevar = next;
						program.read_only_stack.push(valuevar);
						program.instructions.push(SAVE);
				}

				_compile(expr);
				_compile(mk(EContinue));

				continueBreakStackLabel[continueBreakStackLabel.length - 1].pos = program.instructions.length;

				program.instructions.push(POP); // Pop the next function
				program.instructions.push(POP); // Pop the hasNext function

				program.instructions.push(DEPTH_DNC);

				continueBreakStack.pop();
				continueBreakStackLabel.pop();
				popLabelBlock();
			case EBreak:
				program.read_only_stack.push(continueBreakStackLabel[continueBreakStackLabel.length - 1]);
				program.instructions.push(JUMP);
			case EContinue:
				program.read_only_stack.push(continueBreakStack[continueBreakStack.length - 1]);
				program.instructions.push(JUMP_COND);
			case EThrow(e):
				_compile(e);
				program.instructions.push(THROW);
			case EReturn(e):
				if(e != null)
					_compile(e);
				else
					program.instructions.push(PUSH_NULL);
				program.instructions.push(RET);
			case EFunction(name, f):
				var func = f.expr;
				switch (func.expr) {
					case EBlock(exprs):
						for (e in exprs) {
							_compile(e);
						}
					case _:
						throw "Functions must be in blocks";
				}
			case EField(e, field, safe):
				var isSafe = safe == EFSafe;
				pushLabelBlock();
					var endLabel = setLabel(getUniqueId());
					var nullLabel = setLabel(getUniqueId());
					_compile(e);
					if(isSafe) {
						program.instructions.push(DUP);
						program.instructions.push(PUSH_NULL);
						program.instructions.push(EQ);
						program.read_only_stack.push(nullLabel);
						program.instructions.push(JUMP_COND);
					}
					pushConstant(field);
					program.instructions.push(FIELD_GET);
					if(isSafe) {
						program.read_only_stack.push(endLabel);
						program.instructions.push(JUMP_COND);
						nullLabel.pos = program.instructions.length;
						program.instructions.push(PUSH_NULL);
					}
					endLabel.pos = program.instructions.length;
				popLabelBlock();
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
				pushLabelBlock();
					var endLabel = setLabel(getUniqueId());
					_compile(e1); // 1
					program.read_only_stack.push(endLabel);
					program.instructions.push(JUMP_N_COND); // 0 // to at the of this
					_compile(e2); // 1
					endLabel.pos = program.instructions.length;
				popLabelBlock();
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

				pushLabelBlock();
					var endLabel = setLabel(getUniqueId());
					_compile(e1); // 1
					program.read_only_stack.push(endLabel);
					program.instructions.push(JUMP_COND); // 0 // to at the of this
					_compile(e2); // 1
					endLabel.pos = program.instructions.length;
				popLabelBlock();
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
				pushLabelBlock();
					var endLabel = setLabel(getUniqueId());
					_compile(e1); // 1
					program.instructions.push(PUSH_NULL);
					program.instructions.push(EQ);
					program.read_only_stack.push(endLabel);
					program.instructions.push(JUMP_N_COND); // 0 // to at the of this
					_compile(e2); // 1
					endLabel.pos = program.instructions.length;
				popLabelBlock();
			case EBinop(BOpAssign, e1, e2):
				throw "BinopAssignOp not implemented";
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
				_compile(e);
				for (a in args) {
					_compile(a);
				}
				program.read_only_stack.push(args.length);
				program.instructions.push(ARRAY_STACK);
				program.instructions.push(CALL);
			case EObjectDecl(fields):
				program.instructions.push(PUSH_OBJECT);
				for (f in fields) {
					_compile(f.expr);
					pushConstant(f.field);
					program.instructions.push(FIELD_SET);
				}
		}
	}

	public function mk( e : ExprDef, ?pos : Pos = null ) : Expr {
		return { expr : e, pos : pos };
	}
}
