package;

import hxbytevm.core.Ast;
import hxbytevm.compiler.Compiler;
import hxbytevm.vm.Program;
import hxbytevm.vm.HVM;

class CompilerTest {
	public static function main() {
		Sys.println(Util.getTitle("COMPILER TESTING"));
		Sys.println("\n");

		//run(InterpTest.HELLO_WORLD_EXPR, "CALL_TEST");
		//run(InterpTest.WHILE_LOOP_EXPR, "WHILE_LOOP_TEST");
		run(InterpTest.FIBBONACCI_FUNCTION_RECURSIVE, "FIBBONACCI_FUNCTION_RECURSIVE");
	}


	public static function run( e : Expr, name:String) {
		Sys.println(Util.getTitle(name));
		Sys.println("\n");
		var compiler:Compiler = new Compiler();
		compiler.compile(e);

		var vm:HVM = new HVM();
		Sys.println(compiler.program.print());
		vm.run(compiler.program);
	}
}
