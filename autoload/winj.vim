" ============================================================================
" File:         autoload/winj.vim
" Description:  svnj_window handling such as new, populate, close
" Author:       Juneed Ahamed
" =============================================================================

"autoload/winj.vim {{{1
"vars "{{{2
let s:jwinname = 'svnj_window'
let [s:winjhi, s:svnjhl] = [g:svnj_custom_statusbar_title, g:svnj_custom_statusbar_hl]
let s:clines = []
let s:fregex = ""
"2}}}

"win new/close handlers {{{2
fun! winj#New(cdict)
    let s:fregex = ""
    call svnj#prompt#clear()
    call winj#close()
    noa call s:init(a:cdict)
endf

fun! s:init(cdict)
    let jwinnr = bufwinnr(s:jwinname)
    silent! exe jwinnr < 0 ? 'keepa botright 1new ' .
                \ fnameescape(s:jwinname) : jwinnr . 'wincmd w'
    call svnj#syntax#build()
    call svnj#bufops#dflts()
    call svnj#prompt#init(a:cdict)
    try | let s:vim_tm = &tm | let &tm = 0 | catch | endt
endf

fun! winj#close()
    let jwinnr = bufwinnr(s:jwinname)
    if jwinnr < 0 | retu | en
    call svnj#altwinnr()
    let prevwinnr=winnr() 
    exe jwinnr . "wincmd w" | wincmd c 
    exe prevwinnr . "wincmd w" 
    if exists('s:vim_tm') | let &tm = s:vim_tm | en
    echo "" | redr 
    retu svnj#passed()
endf

fun! s:resize()
    call svnj#home()
    silent! exe 'resize ' . (line('$') < g:svnj_window_max_size ? line('$') :
                \ g:svnj_window_max_size)
    silent! exe 'normal! gg'
endf
"2}}}

"accessors {{{2
fun! winj#ops(key)
    retu s:cdict.getOps(a:key)
endf

fun! winj#dict()
    retu s:cdict
endf

fun! winj#regex()
    retu s:fregex
endf
"2}}}

"populate {{{2
fun! winj#populateJWindow(cdict)
    try 
        call winj#New(a:cdict)
        call winj#populate(a:cdict) 
        call svnj#prompt#start()
    catch 
        call svnj#utils#dbgMsg("populateJWindow", v:exception)
    endt
endf

fun! winj#populate(cdict)
    call svnj#home()
    let s:cdict = a:cdict
    setl modifiable
    sil! exe '%d _ '
    let linenum = 0
    let s:clines = []

    try
        let [s:clines, displaylines] = s:cdict.lines()
        call s:setline(1, displaylines)
        unlet! displaylines
        call svnj#bufops#map(s:cdict)
    catch 
        call svnj#utils#dbgMsg("At populate", v:exception)
    endtry
    
    let linenum = line('$') == 1 ? 1 : line('$') + 1 
    if s:cdict.hasError()
        call s:setline(linenum, s:cdict.error.line)
    endif

    if linenum == 0 | call s:setNoContents(1) | en
    let s:fregex = ""
    call s:resize()
    call svnj#syntax#highlight()
    call winj#stl()
    setl nomodifiable | redr
endf

fun! winj#repopulate(fltr, incr)
    try
        if len(a:fltr)>= 1 && a:incr && line('$') == 0 | retu | endif
        call svnj#home()
        setl modifiable  

	    sil! exe '%d _ ' | redr
        let [lines, s:fregex] = svnj#fltr#filter(s:clines, a:fltr, g:svnj_fuzzy_search_result_max)

        if len(lines) <= 0 
            call s:setNoContents(1)
        else
            call s:setline(1, lines) 
        endif
        unlet! lines

        call svnj#syntax#highlight()
        call s:resize()
        call winj#stl()
    catch 
        call svnj#utils#dbgMsg("At repopulate", v:exception)
    endtry

    setl nomodifiable | redraws 
    redr
endf

fun! s:setline(start, lines)
    try | let oul = &undolevels | catch | endt
    try | set undolevels=-1 
    catch | endt
    try | call setline(a:start, a:lines) | catch | endt
    try | exec 'set undolevels=' . oul | catch | endt
endf

fun! s:setNoContents(linenum)
    call s:setline(a:linenum, '--ERROR--: No contents')
endf
"2}}}

"statusline update {{{2
fu! winj#stl()
    try
        echo " "
        if !svnj#home()[0] | retu | en
        let opsdsc = g:svnj_custom_statusbar_ops_hide ? "" :
                    \ ' %#'.g:svnj_custom_statusbar_ops_hl.'# ' . s:cdict.opdsc . "?:HELP "
        let opsdsc = opsdsc == "" ? ' %#'.g:svnj_custom_statusbar_ops_hl.'# ?:Help ' : opsdsc
        let title = s:winjhi.s:cdict.title 
        let alignright = '%='
        let scnt = len(svnj#select#dict()) > 0 ? 's['. len(svnj#select#dict()) . ']' : ''
        let scnt = '%#' . g:svnj_custom_statusbar_sel_hl . '#' . scnt
        let sticky = svnj#prompt#isploop() ? "" : '%#' . g:svnj_custom_sticky_hl .'#' . "STICKY "
        let cnt = s:winjhi . ' [' . '%L/' . len(s:clines) . ']'
        let &l:stl = title.alignright.opsdsc.sticky.scnt.cnt
    catch
        call svnj#utils#dbgMsg("At winj#stl", v:exception)
    endtry
endf
"2}}}
"1}}}
