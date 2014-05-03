"===============================================================================
" File:         autoload/svnj/stack.vim
" Description:  SVNJ Stack
" Author:       Juneed Ahamed
"===============================================================================

"svnj#stack.vim {{{1

"vars {{{2
let s:svnj_stack = []
"2}}}

"functions {{{2
fun! svnj#stack#show()
    echo s:svnj_stack
    let x = input("There stack")
endf

fun! svnj#stack#clear()
    let s:svnj_stack = []
endf

fun! svnj#stack#push(...)
    "call add(s:svnj_stack, a:000)    
    "Older version of vim 7.1.138 seems to cause
    "issues with [[], []] else the upper line will do all is needed 
    let elems = []
    if a:0 >= 1 | call add(elems, a:1) | en
    if a:0 >=2 && type(a:2) == type([]) | call extend(elems, a:2) | en
    call add(s:svnj_stack, elems)
endf

fun! svnj#stack#pop(...)
    try
        let callnow = s:svnj_stack[len(s:svnj_stack)-2]
        let s:svnj_stack = s:svnj_stack[:-3]
        call call(callnow[0], callnow[1:])
     catch | call svnj#utils#dbgHld("At pop", v:exception) | endt
    return 1
endf

fun! svnj#stack#top(...)
    try
        if len(s:svnj_stack) > 0
            let cb = s:svnj_stack[0]
            let s:svnj_stack = []
            call call(cb[0], cb[1:])
        else
            call svnj#utils#dbgHld("At top ", "Nothing in stack")
        endif
    catch | call svnj#utils#dbgHld("At top", v:exception) | endtry
    return 1
endf
"2}}}
"1}}}
