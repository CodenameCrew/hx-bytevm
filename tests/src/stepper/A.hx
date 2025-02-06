package stepper;

// ADAPTED FROM: https://github.com/crowplexus/hscript-iris/blob/master/crowplexus/iris/utils/Ansi.hx
class A {
	public static final FG = new _FG();
	public static final BG = new _BG();

	public static inline final RESET = "\x1B[0m";
	public static inline final INTENSITY_BOLD = "\x1B[1m";
	public static inline final INTENSITY_FAINT = "\x1B[2m";
	public static inline final ITALIC = "\x1B[3m";
	public static inline final UNDERLINE_SINGLE = "\x1B[4m";
	public static inline final BLINK_SLOW = "\x1B[5m";
	public static inline final BLINK_FAST = "\x1B[6m";
	public static inline final NEGATIVE = "\x1B[7m";
	public static inline final HIDDEN = "\x1B[8m";
	public static inline final STRIKETHROUGH = "\x1B[9m";
	public static inline final UNDERLINE_DOUBLE = "\x1B[21m";
	public static inline final INTENSITY_OFF = "\x1B[22m";
	public static inline final ITALIC_OFF = "\x1B[23m";
	public static inline final UNDERLINE_OFF = "\x1B[24m";
	public static inline final BLINK_OFF = "\x1B[25m";
	public static inline final NEGATIVE_OFF = "\x1B[27m";
	public static inline final HIDDEN_OFF = "\x1B[28m";
	public static inline final STRIKETHROUGH_OFF = "\x1B[29m";
	public static inline final CLEAR_SCREEN = "\x1B[2J";
	public static inline final CLEAR_LINE = "\x1B[K";

	private static var colorSupported: Null<Bool> = null;

	private static var colorEscapeRegex = ~/\x1b\[[^m]*m/g;

	public static function stripColor(output: String): String {
		#if sys
		if (colorSupported == null) {
			var term = Sys.getEnv("TERM");

			if (term == "dumb") {
				colorSupported = false;
			} else {
				if (colorSupported != true && term != null) {
					colorSupported = ~/(?i)-256(color)?$/.match(term)
						|| ~/(?i)^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/.match(term);
				}

				if (colorSupported != true) {
					colorSupported = Sys.getEnv("TERM_PROGRAM") == "iTerm.app"
						|| Sys.getEnv("TERM_PROGRAM") == "Apple_Terminal"
						|| Sys.getEnv("COLORTERM") != null
						|| Sys.getEnv("ANSICON") != null
						|| Sys.getEnv("ConEmuANSI") != null
						|| Sys.getEnv("WT_SESSION") != null;
				}
			}
		}

		if (colorSupported) {
			return output;
		}
		#end
		return colorEscapeRegex.replace(output, "");
	}
}

class _FG {
	public final BLACK = "\x1B[30m";
	public final RED = "\x1B[31m";
	public final GREEN = "\x1B[32m";
	public final YELLOW = "\x1B[33m";
	public final BLUE = "\x1B[34m";
	public final MAGENTA = "\x1B[35m";
	public final CYAN = "\x1B[36m";
	public final WHITE = "\x1B[37m";
	public final DEFAULT = "\x1B[39m";
	public final ORANGE = "\x1B[216m";
	public final DARK_ORANGE = "\x1B[215m";
	public final ORANGE_BRIGHT = "\x1B[208m";

	public function new() {}
}

class _BG {
	public final BLACK = "\x1B[40m";
	public final RED = "\x1B[41m";
	public final GREEN = "\x1B[42m";
	public final YELLOW = "\x1B[43m";
	public final BLUE = "\x1B[44m";
	public final MAGENTA = "\x1B[45m";
	public final CYAN = "\x1B[46m";
	public final WHITE = "\x1B[47m";
	public final DEFAULT = "\x1B[49m";
	public final ORANGE = "\x1B[216m";
	public final DARK_ORANGE = "\x1B[215m";
	public final ORANGE_BRIGHT = "\x1B[208m";

	public function new() {}
}
