package hxbytevm.utils.enums;

enum Result<T, E> {
	Ok(value:T);
	Err(error:E);
}

enum ResultOption<T, E> {
	Ok(value:T);
	Err(error:E);
	None;
}
