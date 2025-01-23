package hxbytevm.vm;

typedef ByteInt = #if cpp cpp.Int8 #else Int #end;

enum abstract ByteCode(ByteInt) from ByteInt from Int to ByteInt to Int {
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
	 * Pushes a false to the top of the stack
	 */
	var PUSH_OBJECT:ByteCode;

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
	 * Pushes a Math.POSITIVE_INFINITY to the top of the stack
	 */
	var PUSH_POSITIVE_INFINITY:ByteCode;

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
	var BINOP_ADD:ByteCode; // v1 + v2
	var BINOP_SUB:ByteCode; // v1 - v2
	var BINOP_MULT:ByteCode; // v1 * v2
	var BINOP_DIV:ByteCode; // v1 / v2
	var BINOP_MOD:ByteCode; // v1 % v2
	var BINOP_AND:ByteCode; // v1 & v2
	var BINOP_OR:ByteCode; // v1 | v2
	var BINOP_XOR:ByteCode; // v1 ^ v2
	var BINOP_SHL:ByteCode; // v1 << v2
	var BINOP_SHR:ByteCode; // v1 >> v2
	var BINOP_USHR:ByteCode; // v1 >>> v2
	var BINOP_EQ:ByteCode; // v1 == v2
	var BINOP_NEQ:ByteCode; // v1 != v2
	var BINOP_GTE:ByteCode; // v1 >= v2
	var BINOP_LTE:ByteCode; // v1 <= v2
	var BINOP_GT:ByteCode; // v1 > v2
	var BINOP_LT:ByteCode; // v1 < v2
	var BINOP_BOR:ByteCode; // v1 || v2
	var BINOP_BAND:ByteCode; // v1 && v2
	var BINOP_IS:ByteCode; // v1  is  v2

	/**
	 * FOLLOWED BY 0 BYTES -
	 * ALL UNOPS -
	 * uses the last 2 variables in the stack to do a binop,
	 * popping both of them and pushing the result to the stack
	 */
	var UNOP_NEG:ByteCode; // -v1
	var UNOP_NOT:ByteCode; // !v1
	var UNOP_BNOT:ByteCode; // ~v1
	var UNOP_INC:ByteCode; // ++v1
	var UNOP_DEC:ByteCode; // --v1
	// no post versions because that will be done in the compiler

	/**
	 * FOLLOWED BY 1 BYTE -
	 * INDX: following bytes encoded as a Int8.
	 * Pushes memory[INDX] to the top of the stack.
	 */
	var PUSH_MEMORY8:ByteCode;

	/**
	 * FOLLOWED BY 2 BYTE -
	 * INDX: following bytes encoded as a Int16.
	 * Pushes memory[INDX] to the top of the stack.
	 */
	var PUSH_MEMORY16:ByteCode;

	/**
	 * FOLLOWED BY 3 BYTE -
	 * INDX: following bytes encoded as a Int24.
	 * Pushes memory[INDX] to the top of the stack.
	 */
	var PUSH_MEMORY24:ByteCode;

	/**
	 * FOLLOWED BY 1 BYTE -
	 * INDX: following bytes encoded as a Int8.
	 * Saves the top of the stack to memory[INDX], popping it in the process.
	 */
	var SAVE_MEMORY8:ByteCode;

	 /**
	  * FOLLOWED BY 2 BYTE -
	  * INDX: following bytes encoded as a Int16.
	  * Saves the top of the stack to memory[INDX], popping it in the process.
	  */
	var SAVE_MEMORY16:ByteCode;

	 /**
	  * FOLLOWED BY 3 BYTE -
	  * INDX: following bytes encoded as a Int24.
	  * Saves the top of the stack to memory[INDX], popping it in the process.
	  */
	var SAVE_MEMORY24:ByteCode;

	/**
	 * FOLLOWED BY 1 BYTE -
	 * INDX: following bytes encoded as a Int8.
	 * Moves the byte pointer to INDX.
	 */
	var GOTO8:ByteCode;

	/**
	 * FOLLOWED BY 2 BYTE -
	 * INDX: following bytes encoded as a Int16.
	 * Moves the byte pointer to INDX.
	 */
	var GOTO16:ByteCode;

	/**
	 * FOLLOWED BY 4 BYTE -
	 * INDX: following bytes encoded as a Int32.
	 * Moves the byte pointer to INDX.
	 */
	var GOTO32:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Calls stack[stacktop-1] (a function),
	 * with a array of args from stack[stacktop],
	 * return is pushed to stacktop.
	 */
	var CALL:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Calls stack[stacktop-1] (a function),
	 * return is pushed to stacktop.
	 */
	var CALL_NOARG:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Gets property from object with field.
	 * Stack [..., object, field]
	 */
	var FIELD_GET:ByteCode;

	/**
	 * FOLLOWED BY 0 BYTES -
	 * Sets field of object to value.
	 * Stack [..., value, object, field]
	 */
	var FIELD_SET:ByteCode;

	/**
	 * Initializes a new class instance from a class type.
	 * Stack [class, args]
	 */
	var NEW:ByteCode;

	/**
	 * Gets a value from the array at the index.
	 * Stack [array, index]
	 */
	var ARRAY_GET:ByteCode;

	/**
	 * Sets a value in the array at the index.
	 * Stack [value, array, index]
	 */
	var ARRAY_SET:ByteCode;

	/**
	 * Returns a value from the stack.
	 * Also goes back to the previous location based on the call stack.
	**/
	var RETURN:ByteCode;
}
