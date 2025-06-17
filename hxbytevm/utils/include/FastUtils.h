#ifndef FASTUTILS_EXTERN_H
#define FASTUTILS_EXTERN_H 1

#include <hxcpp.h>
#include <vector>

//String _combineString(const std::vector<String>& inArray);

//template <typename... T>
//String combineString(T... args);

String combineStringFast(const std::vector<String>& inArray);

String combineString(const std::vector<String>& inArray);

String repeatString(String str, int times);

int parse_int_throw(String inString);

#endif
