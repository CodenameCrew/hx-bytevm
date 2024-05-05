package hxbytevm.vm;

import hxbytevm.utils.ReverseIterator.ReverseArrayIterator;
import hxbytevm.utils.ReverseIterator.ReverseArrayKeyValueIterator;
import haxe.iterators.ArrayIterator;


class VarAccessKeyValueIterator {
	public var names:Array<String> = [];
	public var values:Array<Dynamic> = [];

	public function new(names:Array<String>, values:Array<Dynamic>) {
		this.names = names;
		this.values = values;
	}

	@:noCompletion public var _current:Int = 0;
	public inline function hasNext():Bool {
		return _current < names.length;
	}

	public inline function next():{key:String, value:Dynamic} {
		_current++;
		return @:fixed {value: values[_current], key: names[_current]};
	}
}

class VarAccess {
	public var defaults:Map<String, Dynamic> = [];
	public var usedefaults:Bool = true;

	public function loadDefaults() {
		usedefaults = false;
		for (key => value in defaults)
			set(key, value);
		defaults.clear();
	}

	public var parent:HVM;
	public function new(parent:HVM)
		this.parent = parent;

	public inline function set(key:String, value:Dynamic) {
		if (usedefaults) {defaults.set(key, value); return;}
		for (i => varnames in new ReverseArrayKeyValueIterator(parent._varnames)) {
			var index:Int = varnames.indexOf(key);
			if (index != -1) parent._variables[i][index] = value;
		}

	}

	public inline function get(key:String):Dynamic {
		for (i => varnames in new ReverseArrayKeyValueIterator(parent._varnames))
			if (varnames.contains(key))
				return parent._variables[i][varnames.indexOf(key)];
		return null;
	}

	public inline function exists(key:String):Bool {
		for (varnames in new ReverseArrayIterator(parent._varnames))
			if (varnames.contains(key))
				return true;
		return false;
	}

	public inline function remove(key:String) {
		for (i => varnames in new ReverseArrayKeyValueIterator(parent._varnames))
			parent._variables[i][varnames.indexOf(key)] = null;
	}

	public inline function clear():Void {
		parent._varnames.resize(0);
		parent._variables.resize(0);
	}

	public inline function copy():Map<String, Dynamic> {
		var map:Map<String, Dynamic> = [
			for (v => variables in new ReverseArrayKeyValueIterator(parent._variables))
				for (i in 0...parent._variables[v].length)
					parent._varnames[v][i] => variables[i]
		];
		return map;
	}

	// TODO: make it iterate in a flat method
	// TODO: Port iterators
	/*
	public inline function iterator():ArrayIterator<Dynamic>
		return parent._variables.iterator();

	public inline function keys():ArrayIterator<String>
		return parent._varnames.iterator();

	public function keyValueIterator() : VarAccessKeyValueIterator {
		return new VarAccessKeyValueIterator(parent._varnames, parent._variables);
	}
	*/
}
