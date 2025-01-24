package vm.tests;

import haxe.io.BytesOutput;
import vm.tests.VMTestCase;
import hxbytevm.vm.ByteCode;

class VMPushIntTest extends VMTestCase {
	public override function run() {
		var pushint8:BytesOutput = new BytesOutput();
		pushint8.writeByte(ByteCode.PUSH_INT8);
		pushint8.writeInt8(-100);
		assertStackEq("Push Int 8", pushint8.getBytes(), [-100]);

		var pushint16:BytesOutput = new BytesOutput();
		pushint16.writeByte(ByteCode.PUSH_INT16);
		pushint16.writeInt16(-10000);
		assertStackEq("Push Int 16", pushint16.getBytes(), [-10000]);

		var pushint32:BytesOutput = new BytesOutput();
		pushint32.writeByte(ByteCode.PUSH_INT32);
		pushint32.writeInt32(2147483647-1);
		assertStackEq("Push Int 32", pushint32.getBytes(), [2147483647-1]);

		super.run();
	}
}
