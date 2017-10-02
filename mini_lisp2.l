%{
    #include<iostream>
    using namespace std;
    #include "mini_lisp2.tab.h"

	int yycolumn = 1;
	#define YY_USER_ACTION \
		yylloc.first_line = yylloc.last_line = yylineno;\
		yylloc.first_column = yycolumn;\
		yylloc.last_column = yycolumn + yyleng - 1;\
		yycolumn += yyleng;
%}
%option yylineno
seperator   [ \t\n\r]+
letter      [a-z]
digit       [0-9]
%%
"print-num"                 {return(PRINTNUM);}
"print-bool"                {return(PRINTBOOL);}
"if"                        {return(IF);}
"mod"                       {return(MOD);}
"and"                       {return(AND);}
"or"                        {return(OR);}
"not"                       {return(NOT);}
"("[ \t]*"define"           {return(LDEFINE);}
"fun"                       {return(FUN);}
0|[1-9][0-9]*|-[1-9][0-9]*  {yylval.val = atoi(yytext); return(NUMBER);}
[a-z]([a-z0-9]|"-")*           {yylval.txt = strdup(yytext); return(ID);}
"#t"|"#f"                   {yylval.txt = strdup(yytext); return(BOOLVAL);}
{seperator}                 {;}
.                           {return(yytext[0]);}
%%
