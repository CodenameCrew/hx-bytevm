package hxbytevm.vm;

typedef ByteInt = #if cpp cpp.Int8 #else Int #end;

enum abstract ByteCode(ByteInt) {
	/**
	 * FOLLOWED BY 1 BYTE -
	 * Pushes the following bytes encoded as a Int8 to the top of the stack.
	 */
	var PUSH_INT8:ByteCode = 0x00;

	/**
	 * FOLLOWED BY 2 BYTES -
	 * Pushes the following bytes encoded as a Int16 to the top of the stack.
	 */
	var PUSH_INT16:ByteCode;

	/**
	 * FOLLOWED BY 4 BYTES -
	 * Pushes the following bytes encoded as a Int32 to the top of the stack.
	 */
	var PUSH_INT32:ByteCode;

	/**
	 * FOLLOWED BY 8 BYTES -
	 * Pushes the following bytes encoded as a Int64 to the top of the stack.
	 */
	var PUSH_INT64:ByteCode;

	/**
	 * FOLLOWED BY 4 BYTES -
	 * Pushes the following bytes encoded as a Float to the top of the stack.
	 */
	var PUSH_FLOAT:ByteCode;

	/**
	 * FOLLOWED BY 1 + LEN BYTES -
	 * LEN: Defined by the first byte as a Int8
	 * Pushes the following bytes encoded as a String to the top of the stack.
	 */
	var PUSH_STRING8:ByteCode;

	/**
	 * FOLLOWED BY 2 + LEN BYTES -
	 * LEN: Defined by the first byte as a Int16
	 * Pushes the following bytes encoded as a String to the top of the stack.
	 */
	var PUSH_STRING16:ByteCode;

	/**
	 * FOLLOWED BY 4 + LEN BYTES -
	 * LEN: Defined by the first byte as a Int32
	 * Pushes the following bytes encoded as a String to the top of the stack.
	 */
	var PUSH_STRING32:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a null to the top of the stack
	 */
	var PUSH_NULL:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a true to the top of the stack
	 */
	var PUSH_TRUE:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a false to the top of the stack
	 */
	var PUSH_FALSE:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a 0 to the top of the stack
	 */
	var PUSH_ZERO:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a 1 to the top of the stack
	 */
	var PUSH_POSITIVE_ONE:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a -1 to the top of the stack
	 */
	var PUSH_NEGATIVE_ONE:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a Math.NaN to the top of the stack
	 */
	var PUSH_NAN:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a Math.POSITIVE_INFINITY to the top of the stack
	 */
	var PUSH_POSITIVE_INFINITY:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a Math.NEGATIVE_INFINITY to the top of the stack
	 */
	var PUSH_NEGATIVE_INFINITY:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Pushes a Math.PI to the top of the stack
	 */
	var PUSH_PI:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * ALL BINOPS -
	 * uses the last 2 variables in the stack to do a binop,
	 * popping both of them and pushing the result to the stack
	 */
	var BINOP_ADD:ByteCode; // v1+v2
	var BINOP_SUB:ByteCode; // v1-v2
	var BINOP_MULT:ByteCode; // v1*v2
	var BINOP_DIV:ByteCode; // v1/v2
	var BINOP_MOD:ByteCode; // v1%v2
	var BINOP_AND:ByteCode; // v1&v2
	var BINOP_OR:ByteCode; // v1|v2
	var BINOP_XOR:ByteCode; // v1^v2
	var BINOP_SHL:ByteCode; // v1<<v2
	var BINOP_SHR:ByteCode; // v1>>v2
	var BINOP_USHR:ByteCode; // v1>>>v2
	var BINOP_EQ:ByteCode; // v1==v2
	var BINOP_NEQ:ByteCode; // v1!=v2
	var BINOP_GTE:ByteCode; // v1>=v2
	var BINOP_LTE:ByteCode; // v1<=v2
	var BINOP_GT:ByteCode; // v1>v2
	var BINOP_LT:ByteCode; // v1<v2
	var BINOP_BOR:ByteCode; // v1||v2
	var BINOP_BAND:ByteCode; // v1&&v2
	var BINOP_IS:ByteCode; // v1 is v2
}
