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

enum Const {
	CInt(value:Int);
	CFloat(value:Float);
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
	WNoQuotes;
	QDoubleQuotes;
}

typedef TypePath = {
	var tpackage : Array <String> ;
	var tname : String ;
	var tparams : Array <TypeParamOrConst> ;
	var tsub : String ;
}

typedef Pos = Int; // TODO : find this in ast

typedef PlacedTypePath = {
	var path : TypePath ;
	var pos_full : Pos ;
	var pos_path : Pos ;
}

enum TypeParamOrConst {
	TPType( typehint : TypeHint );
	TPExpr( expr : Expr );
}

enum ComplexType {
	CTPath( placed_type_path : PlacedTypePath );
	CTFunction( type_hint_list : Array<TypeHint> , type_hint : TypeHint );
	CTAnonymous( class_field : Array<ClassField> );
	CTParent( type_hint : TypeHint );
	CTExtend( placed_type_path : Array<PlacedTypePath> , class_field : Array<ClassField> );
	CTOptional( type_hint : TypeHint );
	CTNamed( placed_name : PlacedName , type_hint : TypeHint );
	CTIntersection( type_hint_list : Array<TypeHint> );
}

typedef TypeHint = {
	var complex_type : ComplexType ;
	var pos : Pos ;
}

typedef FuncArg = {
	var name : PlacedName;
	var opt : Bool;
	var meta: Metadata ;
	var ?type_hint : TypeHint ;
	var ?expr : Expr;
}

typedef Func = {
	var f_params : Array<TypeParam>;
	var f_args : Array<FuncArg> ;
	var ?f_type : TypeHint;
	var ?f_expr : Expr;
}

typedef PlacedName = {
	var string : String ;
	var pos : Pos ;
}

enum FunctionKind {
	FKAnonymous;
	FKNamed( placed_name : PlacedName , _inline : Bool );
	FKArrow;
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
	public var type: TypeHint;
	public var expr: Expr;
	public var pos: Pos;
}

@:structInit
class SimpleCase {
	public var expr: Expr;
	public var values: Array<Expr>;
	public var pos: Pos;
}

@:structInit
class Case {
	public var expr: Expr;
	public var guard: Expr;
	public var pos: Pos;
}

@:structInit
class ObjectField {
	public var name: String;
	public var expr: Expr;
	public var pos: Pos;
	public var quote: QuoteStatus;
}

enum ExprDef {
	EConst( const : Const );
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
	EFor( ident : Expr, iterator : Expr );
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
	ECast( expr : Expr, type_hint : TypeHint );
	EIs( expr : Expr, type_hint : TypeHint );
	// EDisplay( expr : Expr, kind : DisplayKind ); // not used since we dont have language server
	ETernary( cond : Expr, true_expr : Expr, false_expr : Expr );
	ECheckType( expr : Expr, type_hint : TypeHint );
	EMeta( entry: MetadataEntry, expr: Expr );
}

@:structInit
class Expr {
	public var expr: ExprDef;
	public var pos: Pos;
}

typedef TypeParam = {
	var tp_name : PlacedName ;
	var tp_params : Array<TypeParam> ;
	var ?tp_constraints : TypeHint ;
	var ?tp_default : TypeHint ;
	var tp_meta : Metadata ;
}

typedef MetadataEntry = {
	// TODO: Meta.strict_meta ??
	var expr : Array<Expr> ;
	var pos : Pos ;
}

typedef Metadata = {
	var entries : Array<MetadataEntry> ;
}

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

typedef PlannedAccess = {
	var access : Access ;
	var pos : Pos ;
}

enum ClassFieldKind {
	CFKVar( option : TypeHint , ?expr : Expr );
	CFKFun( func : Func );
	CFKProp( placed_name1 : PlacedName , placed_name2 : PlacedName, type_hint : TypeHint , ?expr : Expr );
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
	var cff_access : Array<PlannedAccess> ;
	var cff_kind : ClassFieldKind ;
}

typedef Evar = {
	var ev_name : PlacedName ;
	var ev_final : Bool ;
	var ev_static : Bool ;
	var ev_public : Bool ;
	var ?ev_type : TypeHint ;
	var ?ev_expr : Expr ;
	var ev_meta : Metadata ;
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
	AbFrom( type_hint : TypeHint );
	AbTo( type_hint : TypeHint );
	AbOver( type_hint : TypeHint ); // no clue what this is
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
	var type_hint : TypeHint ;
}

typedef EnumConstructor = {
	var ec_name : PlacedName ;
	var ec_doc : Documenation ;
	var ec_meta : Metadata ;
	var ec_args : Array<EnumArg> ;
	var ec_pos : Pos;
	var ec_params : Array<TypeParam> ;
	var ec_type : TypeHint ;
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

typedef Import = {
	var package_name : Array<PlacedName> ;
	var import_mode : ImportMode ;
}

enum Typedef {
	EClass( def : Definition<ClassFlag, Array<ClassField>> );
	EEnum( def : Definition<EnumFlag , Array<EnumConstructor>> );
	ETypedef( def : Definition<TypedefFlag , TypeHint> );
	EAbstract( def : Definition<AbstractFlag, Array<ClassField>> );
	EStatic( def : Definition<PlannedAccess, ClassFieldKind> );
	EImport( _import : Import );
	EUsing( pack : Array<PlacedName> );
}