" =============================================================================
" File:         plugin/select.vim
" Description:  select/marks/bmarks handler and highlighter
" Author:       Juneed Ahamed
" =============================================================================
"
" plugin/select.vim {{{1
let s:selectd = {}

"select functions {{{2
fun! svnj#select#dict()
    retu s:selectd
endf

fun! svnj#select#clear()
    let s:selectd = {}
endf

fun! svnj#select#add(key, line, path, revision)
    let s:selectd[a:key] = {'line': a:line, 'path': a:path,
                \ 'revision': a:revision}
    call svnj#select#sign(a:key, 1)
    retu svnj#nofltrclear()
endf

fun! svnj#select#remove(key)
    if has_key(s:selectd, a:key)
        call remove(s:selectd, a:key) | call svnj#select#sign(a:key, 0)
        retu svnj#passed()
    endif
    retu svnj#failed()
endf

fun! svnj#select#exists(key)
    retu has_key(s:selectd, a:key)
endf

fun! svnj#select#openFiles(callback, maxopen)
    let cnt = 0
    for [key, sdict] in items(s:selectd)
        if key == 'err' || svnj#utils#isSvnDirReg(sdict.path) 
                    \ || svnj#utils#isdir(sdict.path)
        cont | en
        let cnt += 1
        call call(a:callback, [sdict.revision, sdict.path])
        if cnt == a:maxopen | break | en
    endfor
    if cnt != 0 | call svnj#prepexit() | en
    retu svnj#nofltrclear() 
endf
"2}}}

"bmark functions {{{2
fun! svnj#select#book(url)
    if has_key(g:bmarks, a:url) 
        let eid = g:bmarks[a:url]
        call s:signbmark(eid, 0)
        call remove(g:bmarks, a:url)
    else
        let g:bmarkssid += 1
        let g:bmarks[a:url] = g:bmarkssid
        call s:signbmark(g:bmarkssid, 1)
    endif
    call svnj#caop#cachebmarks()
    retu svnj#nofltrclear() 
endf

fun! svnj#select#booked()
    retu keys(svnj#caop#fetchbmarks())
endf
"2}}}

"sign functions {{{2
fun! svnj#select#sign(theid, isadd)
    try
        if !g:svnj_signs | retu | en
        let theid = matchstr(a:theid, "\\d\\+")
        if a:isadd | exe 'silent! sign place ' . theid . ' line=' . line('.') . 
                    \ ' name=svnjmark '.' buffer='.bufnr('%')
        else | exe 'silent! sign unplace ' . theid | en
    catch 
        call svnj#utils#dbgMsg("At dosign", v:exception)
    endtry
endf

fun! svnj#select#clearsigns()
    exec 'silent! sign unplace *'
endf

fun! svnj#select#resign(dict)
    try
        if !g:svnj_signs | retu svnj#passed() | en
        call svnj#select#clearsigns()
        call s:resign(a:dict)
    catch | call svnj#utils#dbgMsg("At svnj#select#resign", v:exception) | endt
endf
    
fun! s:resign(dict) 
    let brwsd = has_key(a:dict, 'browsed')
    let dobmrks = brwsd ? len(g:bmarks) : 0
    let dosel = len(s:selectd)

    if (dosel || dobmrks)
        let selectpaths = []
        for [key, dict] in items(s:selectd)
            call add(selectpaths, dict.path)
        endfor
        let scmdpost = ' name=svnjmark buffer=' . bufnr('%')
        let bcmdpost = ' name=svnjbook buffer=' . bufnr('%')
        let linenum = 1
        for line in getbufline(bufnr('%'), 1, 80)
            let [key, value] =  svnj#utils#extractkey(line)
            let tkey = printf("%4d:", key)
            let line = substitute(line, "\*", "", "")
            let linenokey = substitute(line, tkey, "", "")

            if !brwsd 
                let dosel = s:resignselect(line, key, linenum, scmdpost, dosel)
            else
                let path = svnj#utils#joinPath(a:dict.bparent, linenokey)
                if index(selectpaths, path) >=0 
                    exe 'silent! sign place ' . key . ' line=' . linenum . scmdpost
                    let dosel -= 1
                endif
                let path = svnj#utils#strip(path)
                if has_key(g:bmarks, path)
                    exe 'silent! sign place ' . g:bmarks[path] . ' line=' . linenum . bcmdpost
                    let dobmrks -= 1
                endif
            endif
            if (dosel == 0 && dobmrks == 0) | break | en
            let linenum += 1
        endfor
        unlet! selectpaths
    endif
endf

fun! s:resignselect(line, key, linenum, cmdpost, selcnt)
    if !has_key(s:selectd, a:key) | retur a:selcnt | en
    let selectdline = '\V' . substitute(s:selectd[a:key].line, '\\', '\\\\', 'g')
    if matchstr(a:line, selectdline) == ""  | retur a:selcnt | en
    exe 'silent! sign place ' . a:key . ' line=' . a:linenum . a:cmdpost
    retu a:selcnt - 1
endf

fun! s:signbmark(theid, isadd)
    try
        if !g:svnj_signs | retu | en
        let theid = matchstr(a:theid, "\\d\\+")
        if a:isadd | exe 'silent! sign place ' . theid . ' line=' . line('.') . 
                    \ ' name=svnjbook '.' buffer='.bufnr('%')
        else | exe 'silent! sign unplace ' . theid | en
    catch 
        call svnj#utils#dbgMsg("At signbmark", v:exception)
    endtry
endf
"2}}}
"1}}}
