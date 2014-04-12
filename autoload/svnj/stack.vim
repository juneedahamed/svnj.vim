
let s:svnj_stack = []

fun! svnj#stack#clear()
    let s:svnj_stack = []
endf

fun! svnj#stack#push(...)
    call add(s:svnj_stack, a:000)
endf

fun! svnj#stack#pop(...)
    try
        let callnow = s:svnj_stack[len(s:svnj_stack)-2]
        let s:svnj_stack = s:svnj_stack[:-3]
        call call(callnow[0], callnow[1])
     catch | call svnj#utils#dbgHld("At pop", v:exception) | endt
    return 1
endf

fun! svnj#stack#top(...)
    try
        if len(s:svnj_stack) > 0
            let callnow = s:svnj_stack[0]
            let s:svnj_stack = []
            call call(callnow[0], callnow[1])
        else
            call svnj#utils#dbgHld("At top ", "Nothing in stack")
        endif
    catch | call svnj#utils#dbgHld("At top", v:exception) | endtry
    return 1
endf

