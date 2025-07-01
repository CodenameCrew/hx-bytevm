package hxbytevm.core.optimization;
// Dead-Code Elimination
class DCE {
	static final unallowedMetas:Array<String> = [":keep", ":keepSub", ":keepInit"];

	public function new() {}

	public function run(mode:DCEMode = Full, program) {}
}

enum DCEMode {
	/**
	 * Only classes in the Haxe Standard Library are affected by DCE. This is the default setting on all targets.
	 */
	Std;

	/**
	 * All classes are affected by DCE.
	 */
	Full;

	/**
	 * No DCE is performed.
	 */
	None;
}
