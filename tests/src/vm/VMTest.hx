package vm;

import hxbytevm.vm.ByteCode;
import haxe.io.BytesBuffer;
import hxbytevm.vm.HVM;
import vm.tests.*;


class VMTest {
	public static var hvm:HVM;

	public static function main() {
		var a:ByteCode = 0x00;
		trace(Std.string(a));

		new VMPushIntTest().run();
	}
}
