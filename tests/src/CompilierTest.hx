package;

import hxbytevm.core.Ast;
import hxbytevm.compilier.Compilier;
import hxbytevm.vm.Program;
import hxbytevm.vm.HVM;

class CompilierTest {
	public static function main() {
		Sys.println(Util.getTitle("COMPILIER TESTING"));
		Sys.println("\n");

		run(InterpTest.HELLO_WORLD_EXPR, "CALL_TEST");
		run(InterpTest.WHILE_LOOP_EXPR, "WHILE_LOOP_TEST");
		run(InterpTest.FIBBONACCI_FUNCTION_RECURSIVE, "FIBBONACCI_FUNCTION_RECURSIVE");
	}


	public static function run( e : Expr, name:String) {
		Sys.println(Util.getTitle(name));
		Sys.println("\n");
		var compilier:Compilier = new Compilier();
		compilier.compile(e);

		var vm:HVM = new HVM();
		Sys.println(compilier.program.print());
		vm.run(compilier.program);
	}
}
