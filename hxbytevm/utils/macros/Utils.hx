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

		Sys.println(define + '\n' + importXml);

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

		Sys.println('${libPath}/${file}');

        Context.getLocalClass().get().meta.add(":include", [
            {
                expr: EConst(CString('${libPath}/${file}')),
                pos: pos
            }
        ], pos);

        return Context.getBuildFields();
    }
}
