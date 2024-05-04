package hxbytevm.utils;

class StringUtils {
	public static function unescape(s: String): String {
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

	public static function getTitle(title:String, ?dashsLen:Int = 46) {
		var l = StringTools.lpad("", "-", Std.int((dashsLen - title.length - 2)/2));
		return l + ' $title ' + l;
	}
}
