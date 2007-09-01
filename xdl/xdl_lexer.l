/* XDL lexer */

/* Definitions */
%{
#include <stdio.h>
#include "xdl_parser.h"

extern void yyerror(char *);

#define copy_and_return(token_type)		\
	{					\
		yylval->name = strdup(yytext);	\
		return(token_type);		\
	}
%}

/* options */
%option noyywrap
/* Reentrancy is a huge performance hit.
   Is this expected ? */
/* %option reentrant */
%option bison-bridge
%option header-file="xdl_lexer.h"
/* %option reentrant */

/* States */
%x S_STRING
%x S_CONFIG
%x S_CSTRING
%x S_CIDENTIFIER

%%

design { return DESIGN; }
inst   { return INSTANCE; }
cfg    { BEGIN(S_CONFIG); return(CONFIG); }
placed { return PLACED; }
unplaced { return UNPLACED; }

net    { return NET; }
outpin { return OUTPIN; }
inpin  { return INPIN; }
pip    { return PIP; }
"=="|"=>"|"=-"|"->"     { return CONNECTION; }

[a-zA-Z0-9_\-]* copy_and_return(IDENTIFIER); /* Should do otherwise */
v[0-9]+.[0-9]+  { return VERSION; }

<S_CONFIG>{
[ \t\n]+     /* eat up whitespace */
\"           { BEGIN(S_CSTRING); return (TOK_QUOTE); }
}

<S_CSTRING>{
[^\\\n\t ":]* { yymore(); BEGIN(S_CIDENTIFIER); }
\\[\": ]      { yymore(); BEGIN(S_CIDENTIFIER); } /* Handle escaped characters */
[ \t\n]+      { return(TOK_WS); } /* whitespace is significant is this context.
                                     It helps resolve shift-reduce conflicts */
:             { return(TOK_CFG_SEP); }
\"            { BEGIN(INITIAL); return (TOK_QUOTE); }
}

<S_CIDENTIFIER>{
[^\\\n\t ":]* yymore(); /* standard characters */
\\[\": ] yymore();      /* escaped characters */
[ \t\n]+              { BEGIN(S_CSTRING); unput(' '); return(IDENTIFIER); } /* whitespace, end */
:                     { BEGIN(S_CSTRING); unput(':'); return(IDENTIFIER); } /* unescaped colon */
\"                    { BEGIN(S_CSTRING); unput('"'); return(IDENTIFIER); }
.                     printf( "Unrecognized character: %s\n", yytext );
}

\" BEGIN(S_STRING);
<S_STRING>{
[^\\\n"]* yymore();
\n yymore(); /* Handle multi-line string */
\\\n yymore(); /* Handle multi-line string with escaped NL */
\"  {
         yytext[yyleng-1] = '0';
         BEGIN(INITIAL);
         return(STRING);
    }
\\[\": ] yymore(); /* Handle string-within-string and other escaped characters */
}

","            { return ','; }
";"            { return ';'; }

#[^\n]*\n      /* eat up one-line and end-of-line comments */
[ \t\n]+       /* eat up whitespace */

.           printf( "Unrecognized character: %s\n", yytext );

%%