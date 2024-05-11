package;

import hxbytevm.utils.macros.DefinesMacro;
import hxbytevm.vm.HVM;

class Main {
	public static function main() {
		trace(DefinesMacro.getDefines());
		// VMTest.main();
		// LexerTest.main();
		// InterpTest.main();
		CompilerTest.main();
	}
}
