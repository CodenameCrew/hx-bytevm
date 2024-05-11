package;

import hxbytevm.core.Ast;
import hxbytevm.compiler.Compiler;
import hxbytevm.vm.Program;
import hxbytevm.vm.HVM;

class CompilerTest {
	public static function main() {
		Sys.println(Util.getTitle("COMPILER TESTING"));

		// run(InterpTest.HELLO_WORLD_EXPR, "CALL_TEST");
		// run(InterpTest.WHILE_LOOP_EXPR, "WHILE_LOOP_TEST");
		// run(InterpTest.FIBBONACCI_FUNCTION_RECURSIVE, "FIBBONACCI_FUNCTION_RECURSIVE");
		// run(InterpTest.TEST_FUNCTION, "TEST FUNCTION");

		run(InterpTest.FUNCTION_RECURSIVE, "FUNCTION RECURSIVE");
		// run(InterpTest.IF_STATEMENT, "IF STATEMENT");
	}


	public static function run( e : Expr, name:String) {
		Sys.println(Util.getTitle(name + " AST"));
		Sys.println(hxbytevm.printer.Printer.printExpr(e));
		Sys.println("\n");
		var compiler:Compiler = new Compiler();
		compiler.compile(e);

		var vm:HVM = new HVM();
		// vm.debug = true;
		Sys.println(compiler.program.print());

		// Sys.println(compiler.program.varnames_stack);
		// Sys.println(compiler.program.read_only_stack);
		// Sys.println(compiler.program.constant_stack);

		vm.run(compiler.program);
	}
}
