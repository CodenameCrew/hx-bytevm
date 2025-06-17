#include <hxcpp.h>
#include <hx/CFFI.h>
#include <vector>
#include <limits.h>
#include <ctype.h>

String combineStringFast(const std::vector<String>& inArray) {
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

String combineString(const std::vector<String>& inArray) {
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

		return String(buf,len);
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

bool willOverflowSigned(long value) {
    return value < INT_MIN || value > INT_MAX;
}

bool willOverflowUnsigned(unsigned long value) {
    return value > UINT_MAX;
}

int parse_int_throw(String inString)
{
	if (!inString.raw_ptr())
		return hx::Throw(HX_CSTRING("Cant parse null")) - 1;

	const char *str = inString.utf8_str(NULL);
	while (isspace(*str)) ++str;

	int sign = 1, base = 10;
	bool checkSigned = true;

	if(*str == '-' || *str == '+') {
		sign = *str == '-' ? -1 : 1;
		str++;
	}

	if(*str == '0') {
		checkSigned = false;
		switch (str[1]) {
			case 'x': case 'X': base = 16; break;
			case 'o': case 'O': base = 8; break;
			case 'b': case 'B': base = 2; break;
			case 'u': case 'U': break;
			default: checkSigned = true; break;
		}

		if(!checkSigned) str += 2; // skip the '0' and the base
	}

	char *end = 0;
	long result = strtol(str, &end, base);

	if(end == str)
		return hx::Throw(HX_CSTRING("Didnt parse the entire string")) - 1;

	if(willOverflowUnsigned(result))
		return hx::Throw(HX_CSTRING("Overflow")) - 1;

	if(sign < 0)
		result = -result;
	return result;
}
