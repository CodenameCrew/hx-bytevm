package vm.tests;

import haxe.io.Bytes;

class VMTestCase extends VMRunner {
	public var passed:Bool = true;

	public var testsCount:Int = 0;
	public var testsPassed:Int = 0;

	public function new() {
		super();
	}

	public function assertStackEq(name:String, test:Bytes, expected:Array<Dynamic>) {
		testsCount++;
		this.execute(test);

		if (!Util.deepEqual(vm.stack.getShortVersion(), expected))
			Sys.println('> ${Std.string(this)} TEST FAILED: $name (${test.toHex()})');
		else {
			testsPassed++;
			Sys.println('> ${Std.string(this)} TEST PASSED: $name (${test.toHex()})');
			Sys.println('> $name STACK: ${vm.stack}');
		}

	}

	public function run() {
		passed = testsPassed >= testsCount;
	}
}
