package hxbytevm.utils;

class StringUtils {
	@:pure public static function unescape(s: String): String {
		/*
		let c = s.[i] in
		let fail msg = raise (Invalid_escape_sequence(c,i,msg)) in
		if esc then begin
			let inext = ref (i + 1) in
			(match c with
			| '"' | '\'' | '\\' -> Buffer.add_char b c
			| '0'..'3' ->
				let u = (try (int_of_string ("0o" ^ String.sub s i 3)) with _ -> fail None) in
				if u > 127 then
					fail (Some ("Values greater than \\177 are not allowed. Use \\u00" ^ (Printf.sprintf "%02x" u) ^ " instead."));
				Buffer.add_char b (char_of_int u);
				inext := !inext + 2;
			| 'x' ->
				let fail_no_hex () = fail (Some "Must be followed by a hexadecimal sequence.") in
				let hex = try String.sub s (i+1) 2 with _ -> fail_no_hex () in
				let u = (try (int_of_string ("0x" ^ hex)) with _ -> fail_no_hex ()) in
				if u > 127 then
					fail (Some ("Values greater than \\x7f are not allowed. Use \\u00" ^ hex ^ " instead."));
				Buffer.add_char b (char_of_int u);
				inext := !inext + 2;
			| 'u' ->
				let fail_no_hex () = fail (Some "Must be followed by a hexadecimal sequence enclosed in curly brackets.") in
				let (u, a) =
					try
						(int_of_string ("0x" ^ String.sub s (i+1) 4), 4)
					with _ -> try
						assert (s.[i+1] = '{');
						let l = String.index_from s (i+3) '}' - (i+2) in
						let u = int_of_string ("0x" ^ String.sub s (i+2) l) in
						if u > 0x10FFFF then
							fail (Some "Maximum allowed value for unicode escape sequence is \\u{10FFFF}");
						(u, l+2)
					with
						| Invalid_escape_sequence (c,i,msg) as e -> raise e
						| _ -> fail_no_hex ()
				in
				if u >= 0xD800 && u < 0xE000 then
					fail (Some "UTF-16 surrogates are not allowed in strings.");
				UTF8.add_uchar b (UCharExt.uchar_of_int u);
				inext := !inext + a;
			| _ ->
				fail None);
			loop false !inext;
		end else
			match c with
			| '\\' -> loop true (i + 1)
			| c ->
				Buffer.add_char b c;
				loop false (i + 1)
				*/
		return s;
	}

	@:pure public static function getTitle(title:String, ?dashsLen:Int = 46) {
		var l = FastUtils.repeatString("-", Std.int((dashsLen - title.length - 2)/2));
		return l + ' $title ' + l;
	}

	@:pure static function isJson(s:String) {
		var len = s.length;
		var i = 0;
		while (i < len) {
			var c = StringTools.fastCodeAt(s, i++);
			if(c >= 'a'.code && c <= 'z'.code) continue;
			if(c >= 'A'.code && c <= 'Z'.code) continue;
			if(c >= '0'.code && c <= '9'.code) continue;
			if(c == '_'.code) continue;
			return false;
		}
		return true;
	}

	@:pure static inline function isPrintable(c:Int) {
		return c >= 32 && c <= 126;
	}

	@:pure static inline function hex(c:Int, ?len:Int = 2) {
		return StringTools.hex(c, len).toLowerCase();
	}

	@:pure public static function getEscapedString(s:String) {
		var buf = new StringBuf();
		#if target.unicode
		var s = new UnicodeString(s);
		#end
		for( i in 0...s.length ) {
			#if target.unicode
			var c:Null<Int> = s.charCodeAt(i);
			#else
			var c:Null<Int> = StringTools.unsafeCodeAt(s, i);
			#end
			switch( c ) {
				case '"'.code: buf.add('\\"');
				case '\\'.code: buf.add('\\\\');
				case '\n'.code: buf.add('\\n');
				case '\r'.code: buf.add('\\r');
				case '\t'.code: buf.add('\\t');
				default:
					if(c == null) continue;
					if(isPrintable(c))
						buf.addChar(c);
					else {
						if(c > 0xFF) {
							buf.add("\\u{");
							buf.add(hex(c, null));
							buf.add("}");
						} else {
							buf.add("\\x");
							buf.add(hex((c & 0xFF)));
						}
					}
			}
		}
		return buf.toString();
	}
}
