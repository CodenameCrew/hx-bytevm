package hxbytevm.utils;

enum Errors {
	Exit;

	InvalidArgument(s:String);
	PPInvalidArgument(s:String);

	Custom(s:String);
}
