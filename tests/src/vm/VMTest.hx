package vm;

import hxbytevm.vm.ByteCode;
import haxe.io.BytesBuffer;
import hxbytevm.vm.HVM;

import vm.tests.*;

class VMTest {
	public static var hvm:HVM;

	public static function main() {
		Sys.println(Util.getTitle("HVM TESTING"));

		new VMPushIntTest().run();
	}
}
