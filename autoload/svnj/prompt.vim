"===============================================================================
" File:         autoload/svnj/prompt.vim
" Description:  SVNJ Prompt
" Author:       Juneed Ahamed
"===============================================================================
let s:fltr = ""
let s:ploop = 1

fun! svnj#prompt#init(cdict)
    call svnj#prompt#clear()
    let s:ploop = !(g:svnj_sticky_on_start && a:cdict.hasbufops)
    let s:ploop = has('gui_running') ? s:ploop : 1
endf

fun! svnj#prompt#start()
    call call(s:ploop ? "svnj#prompt#loop" : "svnj#prompt#show", [])
endf 

fun! svnj#prompt#isploop()
    retu s:ploop
endf

fun! svnj#prompt#setNoLoop(...)
    let s:ploop = 0
    retu svnj#noPloop()
endf

fun! svnj#prompt#clear()
    let s:fltr = ""
    retu s:fltr
endf

fun! svnj#prompt#append(chr)
    if len(s:fltr)<=90
        let s:fltr = s:fltr . a:chr
        call winj#repopulate(s:fltr, 1)
        call svnj#prompt#show()
    endif
endf

fun! svnj#prompt#del()
    let s:fltr = s:fltr[:-2]
    call winj#repopulate(s:fltr, 0)
    call svnj#prompt#show()
endf

fun! svnj#prompt#str()
    retu s:fltr
endf

fun! svnj#prompt#len()
    retu len(s:fltr)
endf

fun! svnj#prompt#empty()
    return s:fltr == ""
endf

fun! svnj#prompt#show()
    redr | exec 'echohl ' . g:svnj_custom_prompt_color
    echon "filter :" | echohl None | echon s:fltr | echon s:ploop ? "" : "_"
endf

fun! svnj#prompt#loop()
    let s:ploop = 1
    call winj#stl()
    while !svnj#doexit()
        try
            call svnj#prompt#show()
            let nr = getchar()
            let chr = !type(nr) ? nr2char(nr) : nr
            if nr == 32 && svnj#prompt#empty() | cont | en
            if chr == "?" | call svnj#act#help() | cont | en

            call svnj#home()
            let [key, line] = svnj#utils#extractkey(getline('.'))

            let opsd = winj#ops(key)
            if len(opsd) > 0 && has_key(opsd, chr)
                try
                    let cbret = svnj#prompt#cb(opsd[chr].fn, get(opsd[chr], 'args', []))
                    if cbret == svnj#fltrclearandexit() | retu | en  "esc example commit
                    if cbret == svnj#noPloop() 
                        redr! | call svnj#prompt#setNoLoop() | call winj#stl()
                        call svnj#prompt#show() | retu
                    endif
                    if cbret != svnj#nofltrclear() | call svnj#prompt#clear() | en
                    call winj#stl() | redr! | cont
                catch 
                    call svnj#utils#dbgMsg("svnj#prompt#loop", v:exception)
                    call svnj#utils#showerr("Oops error ") | cont
                endtry
            endif

            if chr ==# "\<BS>" || chr ==# '\<Del>'
                call svnj#prompt#del()
            elseif chr == "\<Esc>"
                call svnj#prepexit()
                call winj#close() | break
            elseif nr >=# 0x20
                call svnj#prompt#append(chr)
            else | exec "normal!" . chr
            endif
        catch | call svnj#utils#dbgMsg("svnj#prompt#loop", v:exception) | endt
    endwhile
    exe 'echo ""' |  redr
    call winj#close()
endf

fun! svnj#prompt#cb(cbfn, optargs)
    let [key, line] = svnj#utils#extractkey(getline('.'))
    let result = 0
    try
        let argdict = { 
                    \ "dict" : winj#dict(),
                    \ "key"  : key,
                    \ "line" : line,
                    \ "opt"  : a:optargs,
                    \ }
        let result = call(a:cbfn, [argdict]) 
    catch 
        call svnj#utils#dbgMsg("At s:callbac", v:exception)
        call svnj#utils#showerr("Oops error ")
    endtry
    retu result
endf


