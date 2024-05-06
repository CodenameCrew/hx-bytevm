#ifndef FASTUTILS_EXTERN_CPP
#define FASTUTILS_EXTERN_CPP 1

#include <hxcpp.h>
#include <vector>

String _combineString(const std::vector<String>& inArray) {
	int len = 0;
	for (const auto& str : inArray) {
		//len += str.raw_ptr() ? str.length : 4;
		len += str.length;
	}

	char* buf = hx::NewString(len);
	int pos = 0;

	for (const auto& str : inArray) {
		//if (!str.raw_ptr()) {
		//    memcpy(buf + pos, "null", 4);
		//    pos += 4;
		//} else {
		memcpy(buf + pos, str.raw_ptr(), str.length);
		pos += str.length;
		//}
	}

	//buf[len] = '\0';
	return String(buf, len);
}

// Variadic template function for combining strings
//template <typename... T>
//String combineString(T... args) {
//	std::vector<String> inArray = {args...};
//	return _combineString(inArray);
//}

String combineString(String a) {
	return a;
}
String combineString(String a, String b) {
	return _combineString({a, b});
}
String combineString(String a, String b, String c) {
	return _combineString({a, b, c});
}
String combineString(String a, String b, String c, String d) {
	return _combineString({a, b, c, d});
}
String combineString(String a, String b, String c, String d, String e) {
	return _combineString({a, b, c, d, e});
}
String combineString(String a, String b, String c, String d, String e, String f) {
	return _combineString({a, b, c, d, e, f});
}


String repeatString(String str, int times) {
	if (times <= 0)
		return String("", 0);

	int strLength = str.raw_ptr() ? str.length : 4;
	int totalLength = strLength * times;

	char* buf = hx::NewString(totalLength);
	int pos = 0;

	const char* strPtr = str.raw_ptr();
	if (!strPtr)
		strPtr = "null";

	for (int i = 0; i < times; ++i)
		memcpy(buf + pos * strLength, strPtr, strLength);

	//buf[totalLength] = '\0'; // Might not be needed, handled in hx::NewString
	return String(buf, totalLength);
}

#endif
