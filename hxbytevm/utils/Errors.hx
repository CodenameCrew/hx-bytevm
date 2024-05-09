package hxbytevm.utils;

enum Errors {
	Exit;

	PPInvalidArgument(s:String);

	Custom(s:String);
}
