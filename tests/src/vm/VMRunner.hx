package vm;

import haxe.io.Bytes;
import hxbytevm.vm.HVM;

class VMRunner {
	public var vm:HVM;

	public function new() {
		vm = new HVM();
	}

	public function clear() {
		vm.reset();
	}

	public function execute(bytes:Bytes) {
		if (vm.state != null) clear();

		vm.load(bytes);
		vm.execute();
	}

	public function executeWithVars(bytes:Bytes) {}
}
