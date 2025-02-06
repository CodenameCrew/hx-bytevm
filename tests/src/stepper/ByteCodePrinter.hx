package tests.src.stepper;

import haxe.macro.Expr.Var;
import hxbytevm.vm.ByteCode;
import haxe.io.BytesInput;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;

class ByteCodePrinter {
	private var reader:BytesInput;
	public var bytes:Bytes;

	public function new(bytes:Bytes) {
		this.bytes = bytes;
		reader = new BytesInput(bytes);
	}

	public function print(?position:Int = 0, ?lines:Int = 20) {
		reader.position = position;

		var start = reader.position;

		var opCode:ByteCode = reader.readByte();

		var opBytes:BytesBuffer = new BytesBuffer();
		opBytes.addByte(opCode);

		switch (opCode) {
			case ByteCode.PUSH_INT8: reader.readByte();
			case ByteCode.PUSH_INT16: reader.readInt16();
			case ByteCode.PUSH_INT32: reader.readInt32();
			case ByteCode.PUSH_FLOAT: reader.readDouble();
			case ByteCode.PUSH_STRING8: reader.readString(reader.readInt8());
			case ByteCode.PUSH_STRING16: reader.readString(reader.readInt16());
			case ByteCode.PUSH_STRING32: reader.readString(reader.readInt32());
			case ByteCode.PUSH_MEMORY8: reader.readInt8();
			case ByteCode.PUSH_MEMORY16: reader.readInt16();
			// ?
			case ByteCode.PUSH_MEMORY24: reader.readInt24(); // IO DID IT
			case ByteCode.SAVE_MEMORY8: reader.readInt8();
			case ByteCode.SAVE_MEMORY16: reader.readInt16();
			case ByteCode.SAVE_MEMORY24: reader.readInt24();
			case ByteCode.GOTO8: reader.readInt8();
			case ByteCode.GOTO16: reader.readInt16();
			case ByteCode.GOTO32: reader.readInt32();
			default: throw "Unknown opcode: " + opCode;
		}

		var end = reader.position;
		var len = end - start;
		var opBytes = Bytes.alloc(len);
		reader.readBytes(opBytes, start, end);

		// nuh uh
		trace('${opBytes.toHex()}'); // neo i gyat to go ;(
	}
}
