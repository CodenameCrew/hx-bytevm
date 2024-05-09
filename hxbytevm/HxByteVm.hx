package hxbytevm;

import hxbytevm.core.Ast;

typedef Test = {
	var name : String;
	var code : String;
}

@meta(hxbytevm.utils.MacroUtils.makeConstructor)
class HxByteVm {
	private var _basePath : String;
	private var _debug : Bool;
	private var _loaded : Bool;
	private var _ast : Expr;

	public function new() {}

	#if sys
	public function loadFile( path : String ) {
		loadString( sys.io.File.getContent( path ) );
	}
	#else
	public function loadFile( path : String ) {
		throw "Not implemented on this platform";
	}
	#end

	public function loadString( code : String ) {
		var typeDecls = hxbytevm.syntax.Parser.parseFile( code );
		//var tokens = hxbytevm.syntax.Lexer.parse( code );
		//new hxbytevm.syntax.Parser(tokens).pa();
		_loaded = true;
	}

	public function run() {
		if( !_loaded ) {
			throw "Not loaded";
		}
		throw "Compiler not implemented";
		return null;
	}

	public function interpret() {
		if( !_loaded ) {
			throw "Not loaded";
		}
		var interp = new hxbytevm.interp.Interp();
		return interp.run( _ast );
	}

	public function setBasePath( path : String ) {
		return null;
	}

	public function setDebug( debug : Bool ) {
		return null;
	}
}
