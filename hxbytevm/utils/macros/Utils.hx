package hxbytevm.utils.macros;

import haxe.macro.Printer;
import haxe.io.Path;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.PositionTools;

class Utils {
	#if macro
	static function getNormalizedSourcePath(): String {
		var pos = Context.currentPos();
		var posInfo = pos.getInfos();
		var sourcePath = Path.directory(posInfo.file);

		if (!Path.isAbsolute(sourcePath)) {
			sourcePath = Path.join([Sys.getCwd(), sourcePath]);
		}

		return Path.normalize(sourcePath);
	}

	static function getLibraryPath(sourcePath: String, relativeRoot: String): String {
		return Path.normalize(Path.join([sourcePath, relativeRoot]));
	}
	#end

	macro public static function includeXml(lib: String, file: String, relativeRoot: String = ''): Array<Field> {
		var pos = Context.currentPos();
		var sourcePath = getNormalizedSourcePath();
		var libPath = getLibraryPath(sourcePath, relativeRoot);

		var libVar = '${lib.toUpperCase()}_PATH';
		var define = '<set name="${libVar}" value="${libPath}/"/>';
		var importPath = '$${${libVar}}${file}';
		var importXml = '<include name="${importPath}" />';

		//Sys.println(define + '\n' + importXml);

		Context.getLocalClass().get().meta.add(":buildXml", [
			{
				expr: EConst(CString(define + '\n' + importXml)),
				pos: pos
			}
		], pos);

		return Context.getBuildFields();
	}

	macro public static function includeHeader(lib: String, file: String, relativeRoot: String = ''): Array<Field> {
		var pos = Context.currentPos();
		var sourcePath = getNormalizedSourcePath();
		var libPath = getLibraryPath(sourcePath, relativeRoot);

		//Sys.println('${libPath}/${file}');

		Context.getLocalClass().get().meta.add(":include", [
			{
				expr: EConst(CString('${libPath}/${file}')),
				pos: pos
			}
		], pos);

		return Context.getBuildFields();
	}

	macro public static function assert(cond: Expr, msg: String = ""): Expr {
		#if HXBYTEVM_DEBUG
		if(msg == "") {
			var printer = new Printer();
			msg = printer.printExpr(cond);
		}
		var cf = Context.typeExpr(cond);
		var isEnum = false;
		var ge1 = null;
		var ge2 = null;
		switch(cf.expr) { // TODO: make this only check types when the expr is a EBinop
			case TBinop(op, e1, e2):
				switch(e1.t) {
					case TEnum(t, params): isEnum = true;
					default:
				}
				switch(e2.t) {
					case TEnum(t, params): isEnum = true;
					default:
				}
				if(isEnum) {
					switch(cond.expr) {
						case EBinop(op, e1, e2):
							ge1 = e1;
							ge2 = e2;
						default:
					}
				}
			default:
				throw "assert: only binary operators are supported";
		}
		if(isEnum) {
			return macro {
				var __a = ${ge1};
				var __b = ${ge2};
				if(!Type.enumEq(__a, __b)) {
					throw $v{msg} + " (" + __a + " != " + __b + ")";
				}
			}
		} else {
			return macro {
				if(!(${cond})) {
					throw $v{msg};
				}
			}
		}
		#else
		return macro {};
		#end
	}
}
