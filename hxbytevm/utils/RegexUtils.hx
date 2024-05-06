package hxbytevm.utils;

class RegexUtils {
	// TODO: make this happen at compile time
	@:pure public inline static function makeRegexRule(rules:Array<Rule>, flags:String=""):EReg {
		//trace(rules);
		var str = _makeRegexRule(rules, true);
		//trace("~/" + str + "/" + flags);
		return new EReg(str, flags);
	}

	@:pure public static function _makeRegexRule(rules:Array<Rule>, isStart = false):String {
		//trace(rules);
		var str = "";
		function makeGroup(string:String, suffix:String) {
			if(string.length == 0)
				return "";
			if(suffix == "")
				return string;
			if(string.length == 1 || (string.lastIndexOf("[") == 0 && string.indexOf("]") == string.length - 1))
				return string + suffix;
			return FastUtils.combineString4("(?:", string, ")", suffix);
			//"(?:" + string + ")" + suffix;
		}
		for (rule in rules) {
			str += switch (rule) {
				case Str(pattern): pattern;
				case Basic(pattern): _makeRegexRule(pattern);
				case Capture(pattern): "(" + _makeRegexRule(pattern) + ")";
				case Opt(pattern): makeGroup(_makeRegexRule(pattern), "?");
				case Star(pattern): makeGroup(_makeRegexRule(pattern), "*");
				case Plus(pattern): makeGroup(_makeRegexRule(pattern), "+");
				case Either([rr]): _makeRegexRule([rr]);
				case Either(rr): (isStart ? "": "(?:") + [for(r in rr) _makeRegexRule([r])].join("|") + (isStart ? "": ")");
			}
		}
		return str;
	}
}

enum Rule {
	Str(pattern:String);
	Basic(pattern:Array<Rule>);
	Capture(pattern:Array<Rule>);
	Opt(pattern:Array<Rule>);
	Star(pattern:Array<Rule>);
	Plus(pattern:Array<Rule>);
	Either(rules:Array<Rule>);
}
