#ifndef FASTUTILS_EXTERN_H
#define FASTUTILS_EXTERN_H 1

#include <hxcpp.h>
#include <vector>

//String _combineString(const std::vector<String>& inArray);

//template <typename... T>
//String combineString(T... args);

String combineStringFast(String a);
String combineStringFast(String a, String b);
String combineStringFast(String a, String b, String c);
String combineStringFast(String a, String b, String c, String d);
String combineStringFast(String a, String b, String c, String d, String e);
String combineStringFast(String a, String b, String c, String d, String e, String f);

String combineString(String a);
String combineString(String a, String b);
String combineString(String a, String b, String c);
String combineString(String a, String b, String c, String d);
String combineString(String a, String b, String c, String d, String e);
String combineString(String a, String b, String c, String d, String e, String f);

String repeatString(String str, int times);

#endif
