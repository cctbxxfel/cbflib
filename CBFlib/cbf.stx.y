%{

#ifdef __cplusplus

extern "C" {

#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __GNUC__
#ifdef USEMALLOCH
#include <malloc.h>
#endif
#endif

#include "cbf.h"
#include "cbf_tree.h"

#define yyparse       cbf_parse
#define yylex         cbf_lex_wrapper
#define yyerror       cbf_syntax_error
#define YYLEX_PARAM   context
#define YYPARSE_PARAM context

int cbf_lex (void *, void *);

int cbf_lex_wrapper (void *val, void *context)
{
  int token;

  do

    token = cbf_lex (val, ((void **) context) [0]);

  while (token == COMMENT);

  return token;
}

int cbf_syntax_error (const char *message)
{
  return 0;
}

%}

%union
{
  int          errorcode;
  const char  *text;
  cbf_node    *node;
}

%token <text> DATA
%token        LOOP
%token <text> ITEM
%token <text> CATEGORY
%token <text> COLUMN
%token <text> STRING
%token <text> WORD
%token <text> BINARY
%token <text> UNKNOWN
%token <text> COMMENT
%token <errorcode> ERROR

%type  <node> cbf
%type  <node> cbfstart
%type  <node> datablockstart
%type  <node> datablock
%type  <node> category
%type  <node> column
%type  <node> assignment
%type  <node> loopstart
%type  <node> loopcategory
%type  <node> loopcolumn
%type  <node> loopassignment
%type  <text> datablockname
%type  <text> categoryname
%type  <text> columnname
%type  <text> itemname
%type  <text> value

%pure_parser
%no_lines
%expect 0

%%

cbf:              datablock                     {
                                                  cbf_failnez (cbf_find_parent (&($$), $1, CBF_ROOT))
                                                }
                ;

cbfstart:                                       {
                                                  $$ = ((void **) context) [1];
                                                }
                ;

datablockstart:   cbfstart                      {
                                                  cbf_failnez (cbf_make_child (&($$), $1, CBF_DATABLOCK, NULL))
                                                }
                | cbf datablockname             {
                                                  cbf_failnez (cbf_make_child (&($$), $1, CBF_DATABLOCK, $2))
                                                }
                ;

datablock:        datablockstart                {
                                                  $$ = $1;
                                                }
                | assignment                    {
                                                  cbf_failnez (cbf_find_parent (&($$), $1, CBF_DATABLOCK))
                                                }
                | loopassignment                {
                                                  cbf_failnez (cbf_find_parent (&($$), $1, CBF_DATABLOCK))
                                                }
                ;

category:         datablock categoryname        {
                                                  cbf_failnez (cbf_make_child (&($$), $1, CBF_CATEGORY, $2))
                                                }
                ;

column:           category columnname           {
                                                  cbf_failnez (cbf_make_child (&($$), $1, CBF_COLUMN, $2))
                                                }
                | datablock itemname            {
                                                  cbf_failnez (cbf_make_new_child (&($$), $1, CBF_CATEGORY, NULL))
                                                  
                                                  cbf_failnez (cbf_make_child (&($$), $$, CBF_COLUMN, $2))
                                                }
                ;

assignment:       column value                  {
                                                  $$ = $1;

                                                  cbf_failnez (cbf_set_columnrow ($$, 0, $2))
                                                }
                ;

loopstart:        datablock loop                {
                                                  cbf_failnez (cbf_make_node (&($$), CBF_LINK, NULL, NULL))

                                                  cbf_failnez (cbf_set_link ($$, $1))
                                                }
                ;

loopcategory:     loopstart categoryname        {
                                                  cbf_failnez (cbf_make_child (&($$), $1, CBF_CATEGORY, $2))

                                                  cbf_failnez (cbf_set_link ($1, $$))

                                                  $$ = $1;
                                                }
                | loopcolumn categoryname       {
                                                  cbf_failnez (cbf_find_parent (&($$), $1, CBF_DATABLOCK))

                                                  cbf_failnez (cbf_make_child (&($$), $$, CBF_CATEGORY, $2))

                                                  cbf_failnez (cbf_set_link ($1, $$))

                                                  $$ = $1;
                                                }
                ;

loopcolumn:       loopstart itemname            {
                                                  cbf_failnez (cbf_make_new_child (&($$), $1, CBF_CATEGORY, NULL))
                                                  
                                                  cbf_failnez (cbf_make_child (&($$), $$, CBF_COLUMN, $2))

                                                  cbf_failnez (cbf_set_link ($1, $$))

                                                  cbf_failnez (cbf_add_link ($1, $$))

                                                  $$ = $1;
                                                }
                | loopcolumn itemname           {
                                                  cbf_failnez (cbf_find_parent (&($$), $1, CBF_DATABLOCK))

                                                  cbf_failnez (cbf_make_child (&($$), $$, CBF_CATEGORY, NULL))
                                                  
                                                  cbf_failnez (cbf_make_child (&($$), $$, CBF_COLUMN, $2))

                                                  cbf_failnez (cbf_set_link ($1, $$))

                                                  cbf_failnez (cbf_add_link ($1, $$))

                                                  $$ = $1;
                                                }
                | loopcategory columnname       {
                                                  cbf_failnez (cbf_make_child (&($$), $1, CBF_COLUMN, $2))

                                                  cbf_failnez (cbf_set_link ($1, $$))

                                                  cbf_failnez (cbf_add_link ($1, $$))

                                                  $$ = $1;
                                                }
                ;

loopassignment:   loopcolumn value              {
                                                  $$ = $1;

                                                  cbf_failnez (cbf_shift_link ($$))

                                                  cbf_failnez (cbf_add_columnrow ($$, $2))
                                                }
                | loopassignment value          {
                                                  $$ = $1;

                                                  cbf_failnez (cbf_shift_link ($$))

                                                  cbf_failnez (cbf_add_columnrow ($$, $2))
                                                }
                ;
                
loop:             LOOP
                ;

datablockname:    DATA                          {
                                                  $$ = $1;
                                                }
                ;

categoryname:     CATEGORY                      {
                                                  $$ = $1;
                                                }
                ;

columnname:       COLUMN                        {
                                                  $$ = $1;
                                                }
                ;
                
itemname:         ITEM                          {
                                                  $$ = $1;
                                                }
                ;

value:            STRING                        {
                                                  $$ = $1;
                                                }
                | WORD                          {
                                                  $$ = $1;
                                                }
                | BINARY                        {
                                                  $$ = $1;
                                                }
                ;

%%

#ifdef __cplusplus

}

#endif
