package stepper;

import stepper.A;

using Util;

// HI CODENAME ENGINE FANS!!!! :DD
class Logs {
	public static var nativeTrace:(Dynamic, ?haxe.PosInfos) -> Void = null;
	public static function init() {
		if(nativeTrace != null) return;
		nativeTrace = haxe.Log.trace;

		haxe.Log.trace = function(v:Dynamic, ?infos:Null<haxe.PosInfos>) {
			//nativeTrace(v, infos);
			/*nativeTrace("good old fashioned debuging 2");
			var data:Array<String> = [
				//'[${Logs.time().fg(MAGENTA).reset()}] ',
				'[${Logs.time()}] ',
				Std.string(v)
			];
			if(infos != null) {
				for(i in infos.customParams) {
					data.push(", ");
					data.push(Std.string(i));
				}
			}
			//data.push(Ansi.resetTag());
			var text = data.join("");
			nativeTrace(text);*/

			Sys.print('[${A.FG.MAGENTA}${Logs.time()}${A.RESET}] ${v}');
			if(infos != null && infos.customParams != null) {
				for(i in infos.customParams) {
					Sys.print(", " + i);
				}
			}
			Sys.println(""); // hmmmmmmmmmmm
		};
	}

	public static inline function time():String {
		var time = Date.now();
		var stringbuf = new StringBuf();
		stringbuf.add(Std.string(time.getHours()).addZeros(2));
		stringbuf.add(":");
		stringbuf.add(Std.string(time.getMinutes()).addZeros(2));
		stringbuf.add(":");
		stringbuf.add(Std.string(time.getSeconds()).addZeros(2));
		return stringbuf.toString();
	}
}

