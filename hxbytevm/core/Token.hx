package hxbytevm.core;

import hxbytevm.core.Ast;

enum Token {
	TEof;
	TConst(const:TConstant);
	TKwd(keyword:Keyword);
	TComment(comment:String);
	TCommentLine(commentline:String);
	TBinop(op:Binop);
	TUnop(unop:Unop);
	TSemicolon;
	TComma;
	TBrOpen;
	TBrClose;
	TBkOpen;
	TBkClose;
	TPOpen;
	TPClose;
	TDot;
	TDblDot; // Should we name this TColon? aka :
	TQuestionDot;
	TArrow;
	TIntInterval(string:String);
	TSharp(string:String); // preprocessor directive
	TQuestion;
	TAt;
	TDollar(string:String);
	TSpread;
}
