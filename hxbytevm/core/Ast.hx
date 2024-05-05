package hxbytevm.core;

// TODO: DOUBLE CHECK ALL THIS

enum Keyword {
	KFunction;
	KClass;
	KVar;
	KIf;
	KElse;
	KWhile;
	KDo;
	KFor;
	KBreak;
	KContinue;
	KReturn;
	KExtends;
	KImplements;
	KImport;
	KSwitch;
	KCase;
	KDefault;
	KStatic;
	KPublic;
	KPrivate;
	KTry;
	KCatch;
	KNew;
	KThis;
	KThrow;
	KExtern;
	KEnum;
	KIn;
	KInterface;
	KUntyped;
	KCast;
	KOverride;
	KTypedef;
	KDynamic;
	KPackage;
	KInline;
	KUsing;
	KNull;
	KTrue;
	KFalse;
	KAbstract;
	KMacro;
	KFinal;
	KOperator;
	KOverload;
}

enum Binop {
	BOpAdd;
	BOpMult;
	BOpDiv;
	BOpSub;
	BOpAssign;
	BOpEq;
	BOpNotEq;
	BOpGt;
	BOpGte;
	BOpLt;
	BOpLte;
	BOpAnd;
	BOpOr;
	BOpXor;
	BOpBoolAnd;
	BOpBoolOr;
	BOpShl;
	BOpShr;
	BOpUShr;
	BOpMod;
	BOpAssignOp(op:Binop);
	BOpInterval;
	BOpArrow;
	BOpIn;
	BOpNullCoal;
}

enum Unop {
	UIncrement;
	UDecrement;
	UNot;
	UNeg;
	UNegBits;
	USpread;
}

enum StringLiteralKind {
	SDoubleQuotes;
	SSingleQuotes;
}

enum Constant {
	CInt(value:Int, ?suffix:String);
	CFloat(value:Float, ?suffix:String);
	CString(value:String, qoutes:StringLiteralKind);
	CIdent(value:String);
	CRegexp(value:String, options:String);
}

enum TConstant {
	CInt(value:String, ?suffix:String);
	CFloat(value:String, ?suffix:String);
	CString(value:String, qoutes:StringLiteralKind);
	CIdent(value:String);
	CRegexp(value:String, options:String);
}

enum UnopFlag {
	UFPrefix;
	UFPostfix;
}

enum WhileFlag {
	WFNormalWhile;
	WFDoWhile;
}

enum QuoteStatus {
	QUnquoted;
	QQuoted;
}

typedef TypePath = {
	var pack : Array <String> ;
	var name : String ;
	var params : Array <TypeParam> ;
	var sub : String ;
}

typedef Pos = {
	var min : Int ;
	var max : Int ;
	var file : String ;
};

typedef PlacedTypePath = {
	var path : TypePath ;
	var pos_full : Pos ;
	var pos_path : Pos ;
}

enum TypeParam {
	TPType( type : ComplexType );
	TPExpr( expr : Expr );
}

enum ComplexType {
	CTPath( placed_type_path : PlacedTypePath );
	CTFunction( type_hint_list : Array<ComplexType> , type_hint : ComplexType );
	CTAnonymous( class_field : Array<ClassField> );
	CTParent( type_hint : ComplexType );
	CTExtend( placed_type_path : Array<PlacedTypePath> , class_field : Array<ClassField> );
	CTOptional( type_hint : ComplexType );
	CTNamed( placed_name : PlacedName , type_hint : ComplexType );
	CTIntersection( type_hint_list : Array<ComplexType> );
}

typedef FuncArg = {
	var name : PlacedName;
	var opt : Bool;
	var meta: Metadata ;
	var ?type : ComplexType ;
	var ?value : Expr;
}

typedef Func = {
	var ?params : Array<TypeParam>;
	var args : Array<FuncArg> ;
	var ?ret : ComplexType;
	var expr : Expr;
}

typedef PlacedName = {
	var string : String ;
	var pos : Pos ;
}

enum FunctionKind {
	FAnonymous;
	FNamed( placed_name : PlacedName , isInline : Bool );
	FArrow;
}

enum DisplayKind {
	DKCall;
	DKDot;
	DKStructure;
	DKMarked;
	DKPattern( bool : Bool );
}

enum EFieldKind {
	EFNormal; // .
	EFSafe; // ?.
}

@:structInit
class Catch {
	public var v: String;
	public var type: Null<ComplexType>;
	public var expr: Expr;
}

@:structInit
class SimpleCase {
	public var expr: Expr;
	public var values: Array<Expr>;
}

@:structInit
class Case {
	public var expr: Expr;
	public var guard: Expr;
	public var values: Array<Expr>;
}

@:structInit
class ObjectField {
	public var field: String;
	public var expr: Expr;
	public var quotes: Null<QuoteStatus>;
}

enum ExprDef {
	EConst( const : Constant );
	EArray ( arr : Expr, index : Expr ); // expr[expr]
	EBinop( binop : Binop, expr1 : Expr, expr2 : Expr );
	EField( expr : Expr, name : String, kind : EFieldKind );
	EParenthesis( expr : Expr );
	EObjectDecl( fields: Array<ObjectField> );
	EArrayDecl( expr : Array<Expr> );
	ECall( expr : Expr, args : Array<Expr> );
	ENew( path : PlacedTypePath, expr : Array<Expr> );
	EUnop( unop : Unop, unop_flag : UnopFlag, expr : Expr );
	EVars( vars : Array<Evar> );
	EFunction( func_kind : FunctionKind, func : Func );
	EBlock( exprs : Array<Expr> );
	EFor( iterator : Expr, expr : Expr );
	EIf( cond : Expr, expr : Expr, ?else_expr : Expr );
	EWhile( cond : Expr, expr : Expr, flag : WhileFlag );
	ESwitch( expr : Expr, cases : Array<SimpleCase>, default_case : SimpleCase );
	ESwitchComplex( expr : Expr, cases : Array<Case>, default_case : Case ); // To help diffirenciate between simple switch and enum switch
	ETry( expr : Expr, catches : Array<Catch> );
	EReturn( expr : Expr );
	EBreak;
	EContinue;
	EUntyped( expr : Expr );
	EThrow( expr : Expr );
	ECast( expr : Expr, type : ComplexType );
	EIs( expr : Expr, type : ComplexType );
	// EDisplay( expr : Expr, kind : DisplayKind ); // not used since we dont have language server
	ETernary( cond : Expr, true_expr : Expr, false_expr : Expr );
	ECheckType( expr : Expr, type : ComplexType );
	EMeta( entry: MetadataEntry, expr: Expr );
}

@:structInit
class Expr {
	public var expr: ExprDef;
	public var pos: Pos;
}

typedef TypeParamDecl = {
	var name : PlacedName ;
	var ?params : Array<TypeParam> ;
	var ?constraints : ComplexType ;
	var ?defaultType : ComplexType ;
	var meta : Metadata ;
}

typedef MetadataEntry = {
	var name:String;
	var ?params:Array<Expr>;
	var pos:Pos;
}

typedef Metadata = Array<MetadataEntry>;

enum Access {
	APublic;
	APrivate;
	AStatic;
	AOverride;
	ADynamic;
	AInline;
	AMacro;
	AFinal;
	AExtern;
	AAbstract;
	AOverload;
	AEnum;
}

enum ClassFieldKind {
	CFKVar( option : ComplexType , ?expr : Expr );
	CFKFun( func : Func );
	CFKProp( placed_name1 : PlacedName , placed_name2 : PlacedName, type : ComplexType , ?expr : Expr );
}

typedef Documenation = {
	var ?doc_own : String ;
	var ?doc_inherited : Array<String> ;
};

typedef ClassField = {
	var cff_name : PlacedName ;
	var cff_doc : Documenation ;
	var cff_pos : Pos ;
	var cff_meta : Metadata ;
	var cff_access : Array<Access> ;
	var cff_kind : ClassFieldKind ;
}

typedef Evar = {
	var name : PlacedName ;
	var isFinal : Bool ;
	var isStatic : Bool ;
	var isPublic : Bool ;
	var ?type : ComplexType ;
	var ?expr : Expr ;
	var meta : Metadata ;
}

enum EnumFlag {
	EPrivate;
	EExtern;
}

enum ClassFlag {
	HInterface;
	HExtern;
	HPrivate;
	HExtends( path : PlacedTypePath );
	HImplements( path : PlacedTypePath );
	HFinal;
	HAbstract;
}

enum AbstractFlag {
	AbPrivate;
	AbFrom( type : ComplexType );
	AbTo( type : ComplexType );
	AbOver( type : ComplexType ); // no clue what this is
	AbExtern;
	AbEnum;
}

enum TypedefFlag {
	TDPrivate;
	TDExtern;
}

typedef EnumArg = {
	var name : String;
	var opt : Bool;
	var type : ComplexType ;
}

typedef EnumConstructor = {
	var ec_name : PlacedName ;
	var ec_doc : Documenation ;
	var ec_meta : Metadata ;
	var ec_args : Array<EnumArg> ;
	var ec_pos : Pos;
	var ec_params : Array<TypeParam> ;
	var ec_type : ComplexType ;
}

typedef Definition<F, D> = {
	var d_name : PlacedName ;
	var d_doc : Documenation ;
	var d_params : Array<TypeParam> ;
	var d_meta : Metadata ;
	var d_flags : Array<F> ;
	var d_data : D ;
}

enum ImportMode {
	INormal;
	IAsName( as_name : PlacedName );
	IAll;
}

typedef ImportExpr = {
	var path : Array<PlacedName> ;
	var mode : ImportMode ;
}

enum Typedef {
	EClass( def : Definition<ClassFlag, Array<ClassField>> );
	EEnum( def : Definition<EnumFlag, Array<EnumConstructor>> );
	ETypedef( def : Definition<TypedefFlag, ComplexType> );
	EAbstract( def : Definition<AbstractFlag, Array<ClassField>> );
	EStatic( def : Definition<Access, ClassFieldKind> );
	EImport( _import : ImportExpr );
	EUsing( pack : Array<PlacedName> );
}
