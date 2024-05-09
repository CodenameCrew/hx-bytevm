package hxbytevm.utils;

import hxbytevm.core.Token;
import hxbytevm.core.Ast.Pos;

enum Errors {
	Exit;

	Msg(s:String);

	InvalidArgument(s:String);
	PPInvalidArgument(s:String);

	SyntaxError(s:Errors, ?pos:Pos);
	UnexpectedToken(tk:Token);
	StreamError(s:String);

	Custom(s:String);
}
