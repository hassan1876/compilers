/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;


/*
 *  Add Your own definitions here
 */
int commentsCounter;

int handleError(char* errorMSG){
  cool_yylval.error_msg = (char*)malloc(50); strcpy(cool_yylval.error_msg, errorMSG);
  return(ERROR);             
}

char* toLower(char* s) {
  for(char *p=s; *p; p++) *p=tolower(*p);
  return s;
}

%}

/*
 * Define names for regular expressions here.
 */

DARROW                  =>
ASSIGN                  <-
NEW_LINE                [\n]
SPACE                   " "
DIGIT                   [0-9]
TYPE_IDENTIFIER         [A-Z][a-zA-Z0-9_]*|"SELF TYPE"
OBJECT_IDENTIFIER       [a-z][a-zA-Z0-9_]*
BOOLEAN                 t(?i:rue)|f(?i:alse)
OTHER                   .
CLASS                   "class"
ELSE                    "else"
IF                      "if"
FI                      "fi"
IN                      "in"
THEN                    "then"                       
WHILE                   "while" 
LOOP                    "loop"
POOL                    "pool"
INHERITS                "inherits"
CASE                    "case"
ESAC                    "esac"
NEW                     "new"
OF                      "of"
NOT                     "not"
LET                     "let"

PLUS                     [+]
DIVIDE                   [/]
MINUS                    [-]
ASTRICT                  [*]
EQUAL                    [=]
LESS_THAN                [<]
DOT                      [\.]
TELDA                    [~]
COMMA                    [,]
SEMI_COLON               [;]
COLON                    [:]
BRACKET_OPEN             [(]
BRACKET_CLOSE            [)]
AT                       [@]
BRACES_OPEN              [{]
BRACES_CLOSE             [}]
ESCAPED_CHARACTERS       [\t\b\f]


%x COMMENT
%x LINE_COMMENT

%x STRING

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */


<COMMENT><<EOF>>        { // printf("eof in comment"); 
                          BEGIN(INITIAL);
                          return handleError("EOF in comment"); }
                          
<COMMENT>.              { }

<COMMENT>{NEW_LINE}     { curr_lineno++;}

"(*"                    { // printf("start of comment\n");
                          commentsCounter=1;
                          BEGIN(COMMENT); }

<COMMENT>"(*"           {commentsCounter++;}

<COMMENT>"*)"           { // printf("end of comment\n");
                          commentsCounter--;
                          if(commentsCounter==0){
                            BEGIN(INITIAL); 
                          }
                        }

"*)"                    { return handleError("Unmatched *)"); }

"--"                    { 
                          BEGIN(LINE_COMMENT); }

<LINE_COMMENT>"\n"      { curr_lineno++; BEGIN(INITIAL); }

<LINE_COMMENT>.         { }

{DARROW}		            { return (DARROW); }

{ASSIGN}		            { return (ASSIGN); }

{NEW_LINE}              { curr_lineno++; }

{SPACE}                 { }  

{COLON}                 { return ':'; }  

{SEMI_COLON}            { return ';'; }  

{BOOLEAN}		            { strcmp(toLower(yytext), "true") ? cool_yylval.boolean = 0 : cool_yylval.boolean = 1;
                          return (BOOL_CONST); }

"\""                    { // printf("start of string\n");
                          string_buf_ptr = (char*)malloc(MAX_STR_CONST);
                          BEGIN(STRING); }


<STRING>"\\"{NEW_LINE}  { // printf("unscaped new line string\n");
                          curr_lineno++;
                           }

<STRING>"\""            { //printf("end of string\n");
                          BEGIN(INITIAL);
                          if(strlen(string_buf_ptr)>MAX_STR_CONST){
                            return handleError("String constant too long");
                          }
                          cool_yylval.symbol = stringtable.add_string(string_buf_ptr);
                          return (STR_CONST) ;  
                        }

<STRING>[\n]            { // printf("new line in string\n");
                          curr_lineno++;
                          BEGIN(INITIAL);
                          return handleError("Unterminated string constant");
                          }

<STRING>"\\n"           {
                          strcat(string_buf_ptr, "\n");
                        }

<STRING>"\\0"           {
                          strcat(string_buf_ptr, "0");
                        }

<STRING><<EOF>>         { // printf("eof in string"); 
                          BEGIN(INITIAL);
                          return handleError("EOF in string"); }      

<STRING>.               {/*if(strcmp(yytext,"\0")){
                          BEGIN(INITIAL);
                          return handleError("String contains null character");
                          }*/
                          strcat(string_buf_ptr, yytext); }

{DIGIT}+		            { cool_yylval.symbol = inttable.add_string(yytext);
                          return (INT_CONST); }

{CLASS}                 { return (CLASS); }

{ELSE}                  { return (ELSE); }

{IF}                    { return (IF); }
    
{FI}                    { return (FI); }
    
{IN}                    { return (IN); }
    
{THEN}                  { return (THEN); }

{WHILE}                 { return (WHILE); }

{LOOP}                  { return (LOOP); }

{POOL}                  { return (POOL); }

{INHERITS}              { return (INHERITS); }

{CASE}                  { return (CASE); }

{ESAC}                  { return (ESAC); }

{NEW}                   { return (NEW); }

{OF}                    { return (OF); }

{NOT}                   { return (NOT); }

{LET}                   { return (LET); }

{PLUS}                  { return ('+'); }

{DIVIDE}                { return ('/'); }

{MINUS}                 { return ('-'); }

{ASTRICT}               { return ('*'); }

{EQUAL}                 { return ('='); }

{LESS_THAN}             { return ('<'); }

{DOT}                   { return ('.'); }

{TELDA}                 { return ('~'); }

{COMMA}                 { return (','); }

{SEMI_COLON}            { return (';'); }

{COLON}                 { return (':'); }

{BRACKET_OPEN}          { return ('('); }

{BRACKET_CLOSE}         { return (')'); }

{AT}                    { return ('@'); }

{BRACES_OPEN}           { return ('{'); }

{BRACES_CLOSE}          { return ('}'); }

{TYPE_IDENTIFIER}       { cool_yylval.symbol = stringtable.add_string(yytext);
                          return (TYPEID); }

{OBJECT_IDENTIFIER}     { cool_yylval.symbol = stringtable.add_string(yytext);
                          return (OBJECTID); }

{ESCAPED_CHARACTERS}    { }

{OTHER}                 {
                          return(handleError(yytext));
                        }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
