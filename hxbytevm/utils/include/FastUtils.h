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
String combineStringFast(String a, String b, String c, String d, String e, String f, String g);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m, String n);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m, String n, String o);
String combineStringFast(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m, String n, String o, String p);

String combineString(String a);
String combineString(String a, String b);
String combineString(String a, String b, String c);
String combineString(String a, String b, String c, String d);
String combineString(String a, String b, String c, String d, String e);
String combineString(String a, String b, String c, String d, String e, String f);
String combineString(String a, String b, String c, String d, String e, String f, String g);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m, String n);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m, String n, String o);
String combineString(String a, String b, String c, String d, String e, String f, String g, String h, String i, String j, String k, String l, String m, String n, String o, String p);

String repeatString(String str, int times);

int parse_int_throw(String inString);

#endif
