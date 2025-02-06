package hxbytevm.utils.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;

class DebugAbstractMacro {
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();

		fields.push({
			name: "toString",
			pos: Context.currentPos(),
			access: [APublic],
			kind: FFun({
				args: [],
				ret: macro :String,
				expr: macro return ${{
					pos: Context.currentPos(),
					expr: ESwitch(macro cast this, [
						for (i in 0...fields.length) {
							var field = fields[i];
							{
								values: [macro $i{field.name}],
								expr: macro return $v{field.name}
							}
						}
					], macro "Unknown")
				}}
			})
		});

		var printer = new haxe.macro.Printer();
		printer.printField(fields[fields.length - 1]);

		return fields;
	}
}
