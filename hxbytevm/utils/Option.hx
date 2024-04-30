package hxbytevm.utils;

// Inspired by rust's Option type

enum Option<T> {
	Some(value:T);
	None;
}