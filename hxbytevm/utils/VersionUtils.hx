package hxbytevm.utils;

import hxbytevm.utils.enums.Result;

enum SVType {
	SVNum(n:Int);
	SVString(s:String);
}

class Version {
	public var release:Array<SVType>;
	public var pre:Array<SVType>;

	public function new(release:Array<SVType>, ?pre:Array<SVType>) {
		this.release = release;
		this.pre = pre;
	}

	public function toString():String {
		function str(s:SVType):String {
			return switch(s) {
				case SVNum(n): Std.string(n);
				case SVString(s): s;
			}
		}
		var s = release.join(".");
		if (pre != null) {
			s += "-" + pre.map(str).join(".");
		}
		return s;
	}
}

/**
 * Utility class for parsing and comparing semantic versions.
**/
class VersionUtils {
	private static function error(s:String):String {
		return "Invalid version string \"" + s + "\". Should follow SemVer.";
	}

	public static function tryParseVersion(s:String):Result<Version, Dynamic> {
		try {
			var parsed = VersionUtils.parse(s);
			return Ok(parsed);
		} catch (e:Dynamic) {
			return Err(e);
		}
	}

	private static function parseDotted(s:String):Array<SVType> {
		return [for(d in s.split(".")) {
			var a = Std.parseInt(d);
			if (a == null) {
				SVString(d);
			} else {
				SVNum(a);
			}
		}];
	}

	private static function parseRelease(s:String):Array<SVType> {
		var parts = parseDotted(s);

		return switch(parts) {
			case [SVNum(major), SVNum(minor), SVNum(patch)]: [SVNum(major), SVNum(minor), SVNum(patch)];
			case [SVNum(major), SVNum(minor)]: [SVNum(major), SVNum(minor), SVNum(0)];
			case [SVNum(major)]: [SVNum(major), SVNum(0), SVNum(0)];
			default: throw error(s);
		}
	}

	public static function parse(s:String):Version {
		var index = s.indexOf("-");
		if (index == -1) { // 1.2.3
			return new Version(parseRelease(s), null);
		}

		if(index + 1 == s.length) { // 1.2.3-
			throw error(s);
		}

		// 1.2.3-alpha.1+23
		var release = parseRelease(s.substr(0, index));

		var pre = {
			var pre_str = s.substr(index + 1, s.length - (index + 1));
			// remove build meta
			if(s.indexOf("+") != -1) {
				pre_str = pre_str.substr(0, pre_str.indexOf("+"));
			}
			parseDotted(pre_str);
		}

		return new Version(release, pre);
	}

	public static function compareStr(a:String, b:String):Int {
		return (a == b) ? 0 : ((a < b) ? -1 : 1);
	}

	public static function compareInt(a:Int, b:Int):Int {
		return (a == b) ? 0 : ((a < b) ? -1 : 1);
	}

	public static function compare(a:Version, b:Version):Int {
		function compareV(v1:SVType, v2:SVType):Int {
			return switch([v1, v2]) {
				case [SVNum(n1), SVNum(n2)]: compareInt(n1, n2);
				case [SVString(s1), SVString(s2)]: compareStr(s1, s2);
				case [SVNum(_), SVString(_)]: 1;
				case [SVString(_), SVNum(_)]: -1;
			}
		}

		function compareLists(a:Array<SVType>, b:Array<SVType>):Int {
			if(a.length == 0 && b.length == 0) return 0;
			if(a.length == 0) return -1;
			if(b.length == 0) return 1;

			var c = compareV(a[0], b[0]);
			if (c != 0)
				return c;

			return compareLists(a.slice(1), b.slice(1));
		}

		var diff = compareLists(a.release, b.release);
		if (diff != 0)
			return diff;

		return switch([a.pre, b.pre]) {
			case [null, null]: 0;
			case [null, _]: -1;
			case [_, null]: 1;
			case [a, b]: compareLists(a, b);
		}
	}
}
