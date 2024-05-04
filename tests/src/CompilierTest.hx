package;

import hxbytevm.compilier.Compilier;
import hxbytevm.vm.Program;
import hxbytevm.vm.HVM;

class CompilierTest {
	public static function main() {
		Sys.println(Util.getTitle("COMPILIER TESTING"));

		var compilier:Compilier = new Compilier();
		var vm:HVM = new HVM();

		Sys.println(Util.getTitle("CALL TEST"));

		compilier.compile(InterpTest.HELLO_WORLD_EXPR);
		Sys.println(compilier.program.print());

		vm.run(compilier.program);

		Sys.println(Util.getTitle("WHILE LOOP TEST"));

		compilier.compile(InterpTest.WHILE_LOOP_EXPR);
		Sys.println(compilier.program.print());

		vm.run(compilier.program);
	}
}
