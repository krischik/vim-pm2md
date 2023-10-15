
""
"  Extract text from PMWiki raw data file
"
function! PMWiki_Extract_Text ()
    % global! /^text=/ delete
    1 substitute /^text=//
    1 substitute /%0a/\r/ge
endfunction "PMWiki_Extract_Text

""
"  Add hugo front matter
"
function! PMWiki_Add_Front_Matter ()
    let l:Title_Line=line(1)
    let l:Title_Text=Title_Line->substitute("^(:title ", "", "")->substitute(":)$", "", "")

    1 insert
---
title	    : "(:title:)"
description : "(:title:)"
summary     : "(:title:)."
showSummary : true
date	    : (:date:)
draft	    : true
type	    : "page"
categories  : []
tags	    : []
---
.
    2,4 substitute /(:title:)/\= l:Title_Text /e
    6	substitute /(:date:)/\= strftime("%Y-%m-%dT%T%z",expand("%")->getftime()) /e
    12	delete


    $ append
<!-- vim: set wrap tabstop=8 shiftwidth=4 softtabstop=4 noexpandtab : -->
<!-- vim: set textwidth=79 filetype=markdown foldmethod=marker spell : -->
<!-- vim: set spell spelllang=en_gb : -->
.

    set wrap tabstop=8 shiftwidth=4 softtabstop=4 expandtab
    set textwidth=79 filetype=markdown foldmethod=marker spell
    set spell spelllang=en_gb
endfunction "PMWiki_Add_Front_Matter

function! PMWiki_To_Markdown ()
    " Convert odered list
    "
    % substitute /\v^(#{1,})(.*)/\= repeat(" ", submatch(1)->strlen() - 1) . "1. " . submatch(2)->trim() /e

    " Convert unodered list
    "
    % substitute /\v^(\*{1,})(.*)/\= repeat(" ", submatch(1)->strlen() - 1) . "* " . submatch(2)->trim()/e

    " Convert definition list
    "
    % substitute /\v^[:;](.{-}):(.*)/\= "\n**" . submatch(1)->trim() . "**\n" . ": " . submatch(2)->trim() /e
    % substitute /\v^-\>(.*)/\= ": " . submatch(1)->trim() /e

    " Convert header
    "
    % substitute /\v^(!{1,})(.*)/\= repeat("#", submatch(1)->strlen() - 1) . " " . submatch(2)->trim() /e

    " Convert external links
    "
    % substitute !\v\[\[(https{0,1}://.{-})\|(.{-})\]\]![\2](\1)!ge

    " Convert interal links
    "
    % substitute !\v\[\[(.{-})\|(.{-})\]\]![\2](\1)!ge
    % substitute !\v\[\[(.{-})\]\]![\1](\1)!ge

    " Convert small text
    "
    % substitute !\v\[-(.{-})-\]!<small>\1</small>!e
    % substitute !\v'-(.{-})-'!<small>\1</small>!e

    " Convert bold italic
    "
    % substitute /\v'{5,5}(.{-})'{5,5}/_**\1**_/ge

    " Convert bold
    "
    % substitute /\v'{3,3}(.{-})'{3,3}/**\1**/ge

    " Convert italic
    "
    % substitute /\v'{2,2}(.{-})'{2,2}/_\1_/ge

    " Convert monospaced
    "
    % substitute /\v\@{2,2}(.{-})\@{2,2}/`\1`/ge

    " Convert code blocks
    "
    % substitute /\V\^[@/```text/e
    % substitute /\V\^@]/```/e

    " Convert Picture links
    "
    % substitute #^%25width=\(\d*\)px%25 .*/\(.*.png\) | \(.*\)#![\3](\2?width=\1 "\3")#ge
endfunction "PMWiki_To_Markdown

"   Relace a standart table which begins with {| and |}. Converts one table at
"   a time to. Position cursort in the line above the {|.
"
function! PMWiki_Table_To_Markdown ()
    /{|/ mark s
    /|}/ mark e

    "	Replace single line column marker
    "
    's,'e  substitute /||!\?/|/ge

    "  Replace header marker (denoted by a '!') with column marker
    "
    's,'e  substitute /^!\s.\{-}\s|/|/e

    "  Replace column marker (dentoted by a '|') with column marker
    "
    's,'e  substitute /||/|/ge

    "  Delete row marker
    "
    's,'e  global  /^|-/ delete

    " Convert caption 
    "
    's,'e  substitute /^|+\(.*\)/**\1**/e

    "  Add missing with column marker at end of line
    "
    's,'e  substitute /[^|]$/\0 |/e
endfunction "PMWiki_Table_To_Markdown

"   Relace a simple tables where each row is on one column. Converts one table
"   at a time to. Use line select to select the table from begin to end.
"
function! PMWiki_Simple_Table_To_Markdown () range
    "	Replace single line column marker
    "
    execute a:firstline . "," . a:lastline " substitute /||!\\?/|/ge"
    "  Add missing with column marker at end of line
    "
    execute a:firstline . "," . a:lastline " substitute /[^|]$/\\0 |/e" 
endfunction "PMWiki_Simple_Table_To_Markdown

"   Relace a complex table using the (:table:) markup. Converts one table at a
"   time to. Place the cursor in the line above (:table:). Needs the
"   {{< rawhtml >}} shortcode.
"
function! PMWiki_Complex_Table_To_Raw_HTML () 
    /^(:table[: ]/ mark s
    /^(:tableend/  mark e

    "	Replace rows.
    "
    's,'e substitute !(:cellnr\(.*\):)\(.*\)!\= "<\/tr>\r<tr>\r<td" . submatch(1)->substitute('\s\(.\{-}\)=\(.\{-}\)\s',' \1="\2" ',"g") . ">" . submatch(2)->trim() . "</td>"!g
    normal 's 
    /<\/tr>/ delete

    "	Replace columns.
    "
    's,'e substitute !(:cell\(.*\):)\(.*\)!\= "<td" . submatch(1)->substitute('\s\(.\{-}\)=\(.\{-}\)\s',' \1="\2" ',"ge") . ">" . submatch(2)->trim() . "</td>"!g

    " replace simple picture links.
    "
    's,'e substitute #\v(https://.{-}.png)#<img src="\1"></img>#ge

    "	Replace table start.
    "
    's,'e substitute /(:table[: ]\(.*\):)/\= "{{< rawhtml >}}\r<table " . submatch(1) . ">"/ge

    "	Replace table end.
    "
    's,'e substitute !(:tableend:)!</tr>\r</table>\r{{< /rawhtml >}}!ge
endfunction "PMWiki_Complex_Table_To_Raw_HTML

command		PMWikiExtractText	    :call PMWiki_Extract_Text()
command		PMWikiAddFrontMatter	    :call PMWiki_Add_Front_Matter()
command		PMWikiToMarkdown	    :call PMWiki_To_Markdown()
command		PMWikiTableToMarkdown	    :call PMWiki_Table_To_Markdown()
command -range	PMWikiSimpleTableToMarkdown :<line1>,<line2> call PMWiki_Simple_Table_To_Markdown()
command 	PMWikiComplexTableToRawHTML :call PMWiki_Complex_Table_To_Raw_HTML()

execute "47menu Plugin.Wiki.PMWiki\\ Extract\\ Text<Tab>"			. escape(g:mapleader . "pe" , '\') . " :call PMWiki_Extract_Text()<CR>"
execute "47menu Plugin.Wiki.PMWiki\\ Add\\ Front\\ Matter<Tab>"			. escape(g:mapleader . "pa" , '\') . " :call PMWiki_Add_Front_Matter()<CR>"
execute "47menu Plugin.Wiki.PMWiki\\ To\\ Markdown<Tab>"			. escape(g:mapleader . "pm" , '\') . " :call PMWiki_To_Markdown()<CR>"
execute "47menu Plugin.Wiki.PMWiki\\ Table\\ To\\ Markdown<Tab>"		. escape(g:mapleader . "pt" , '\') . " :call PMWiki_Table_To_Markdown()<CR>"
execute "47menu Plugin.Wiki.PMWiki\\ Simple\\ Table\\ To\\ Markdown<Tab>"	. escape(g:mapleader . "pt" , '\') . " :'<,'>call PMWiki_Simple_Table_To_Markdown()<CR>"
execute "47menu Plugin.Wiki.PMWiki\\ Complex\\ Table\\ To\\ Raw\\ HTML<Tab>"	. escape(g:mapleader . "pt" , '\') . " :'<,'>call PMWiki_Complex_Table_To_Raw_HTML()<CR>"

" vim: set textwidth=78 nowrap tabstop=8 shiftwidth=4 softtabstop=4 noexpandtab :
" vim: set filetype=vim fileencoding= fileformat=unix foldmethod=marker :
" vim: set nospell spelllang=en_bg :
