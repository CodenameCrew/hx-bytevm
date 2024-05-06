#ifndef FASTUTILS_EXTERN_CPP
#define FASTUTILS_EXTERN_CPP 1

#include <hxcpp.h>
#include <vector>

String _combineStringFast(const std::vector<String>& inArray) {
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

String _combineString(const std::vector<String>& inArray) {
	int len = 0;
	#ifdef HX_SMART_STRINGS
	bool isWChar = false;
	#endif
	for (const auto& strI : inArray) {
		if (strI.raw_ptr())
		{
			len += strI.length;
			#ifdef HX_SMART_STRINGS
			if (!isWChar && strI.isUTF16Encoded())
				isWChar = true;
			#endif
		}
		else
			len += 4; // null
	}

	#ifdef HX_SMART_STRINGS
	int pos = 0;
	if (isWChar)
	{
		char16_t *buf = String::allocChar16Ptr(len);

		for (const auto& strI : inArray) {
			if (!strI.raw_ptr())
			{
				memcpy(buf+pos,u"null",8);
				pos+=4;
			}
			else if(strI.length==0)
			{
				// ignore
			}
			else if (strI.isUTF16Encoded())
			{
				memcpy(buf+pos,strI.raw_wptr(),strI.length*sizeof(char16_t));
				pos += strI.length;
			}
			else
			{
				const char *ptr = strI.raw_ptr();
				for(int c=0;c<strI.length;c++)
					buf[pos++] = ptr[c];
			}
		}
		buf[len] = '\0';

		String result(buf,len);
		return result;
	}
	#endif
	{
		char *buf = hx::NewString(len);

		for (const auto& strI : inArray) {
			if (!strI.raw_ptr())
			{
				memcpy(buf+pos,"null",4);
				pos+=4;
			}
			else
			{
				memcpy(buf+pos,strI.raw_ptr(),strI.length*sizeof(char));
				pos += strI.length;
			}
		}
		//buf[len] = '\0';

		return String(buf,len);
	}
}

// Variadic template function for combining strings
//template <typename... T>
//String combineString(T... args) {
//	std::vector<String> inArray = {args...};
//	return _combineString(inArray);
//}

String combineStringFast(String a) {return a;}
String combineStringFast(String a, String b) {return _combineStringFast({a, b});}
String combineStringFast(String a, String b, String c) {return _combineStringFast({a, b, c});}
String combineStringFast(String a, String b, String c, String d) {return _combineStringFast({a, b, c, d});}
String combineStringFast(String a, String b, String c, String d, String e) {return _combineStringFast({a, b, c, d, e});}
String combineStringFast(String a, String b, String c, String d, String e, String f) {return _combineStringFast({a, b, c, d, e, f});}

String combineString(String a) {return a;}
String combineString(String a, String b) {return _combineString({a, b});}
String combineString(String a, String b, String c) {return _combineString({a, b, c});}
String combineString(String a, String b, String c, String d) {return _combineString({a, b, c, d});}
String combineString(String a, String b, String c, String d, String e) {return _combineString({a, b, c, d, e});}
String combineString(String a, String b, String c, String d, String e, String f) {return _combineString({a, b, c, d, e, f});}

String repeatString(String str, int times) {
	if (times <= 0)
		return String("", 0);

	int strLength = str.raw_ptr() ? str.length : 4;
	int totalLength = strLength * times;

	char* buf = hx::NewString(totalLength);

	const char* strPtr = str.raw_ptr();
	if (!strPtr)
		strPtr = "null";

	for (int i = 0; i < times; ++i)
		memcpy(buf + i * strLength, strPtr, strLength);

	//buf[totalLength] = '\0'; // Might not be needed, handled in hx::NewString
	return String(buf, totalLength);
}

#endif
