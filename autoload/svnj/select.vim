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
    return 1
endf

fun! svnj#select#remove(key)
    if has_key(s:selectd, a:key)
        call remove(s:selectd, a:key) | call svnj#select#sign(a:key, 0)
        return 1
    endif
    return 0
endf

fun! svnj#select#exists(key)
    return has_key(s:selectd, a:key)
endf

fun! svnj#select#openFiles(callback, maxopen)
    let cnt = 0
    for [key, sdict] in items(s:selectd)
        if svnj#utils#isSvnDir(sdict.path) | cont | en
        let cnt += 1
        call call(a:callback, [sdict.revision, sdict.path])
        if cnt == a:maxopen | break | en
    endfor
    if cnt != 0 | call svnj#prepexit() | en
    return cnt
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
endf

fun! svnj#select#booked()
    let entries = []
    for [line, val] in items(g:bmarks)
        let listentryd = {}
        let listentryd.line = line
        call add(entries, listentryd)
    endfor
    return entries
endf
"2}}}

"sign functions {{{2
fun! svnj#select#sign(theid, isadd)
    try
        if !g:svnj_signs | return | en
        let theid = matchstr(a:theid, "\\d\\+")
        if a:isadd | exe 'silent! sign place ' . theid . ' line=' . line('.') . 
                    \ ' name=svnjmark '.' buffer='.bufnr('%')
        else | exe 'silent! sign unplace ' . theid | en
    catch 
        call svnj#utils#dbgHld("At dosign", v:exception)
    endtry
endf

fun! svnj#select#clearsigns()
    exec 'silent! sign unplace *'
endf

fun! svnj#select#resign(dict)
    try
        if !g:svnj_signs | return 1 | en
        call svnj#select#clearsigns()
        call s:resign(a:dict)
    catch | call svnj#utils#dbgHld("At svnj#select#resign", v:exception) | endt
endf
    
fun! s:resign(dict) 
    let bdict = len(g:bmarks) > 0 ? svnj#dict#bmarkable(a:dict) : {}
    let dobmrks = len(g:bmarks) < len(bdict) ? len(g:bmarks) : len(bdict)
    let dosel = len(s:selectd)
    if (dosel || dobmrks)
        let scmdpost = ' name=svnjmark buffer=' . bufnr('%')
        let bcmdpost = ' name=svnjbook buffer=' . bufnr('%')
        let linenum = 1
        for line in getbufline(bufnr('%'), 1, 80)
            let tkey = matchstr(line, "^\\d\\+: ")
            let key = matchstr(tkey, "\\d\\+")
            let line = substitute(line, "\*", "", "")
            let linenokey = substitute(line, tkey, "", "")
            let dosel = s:resignselect(line, key, linenum, scmdpost, dosel)
            let dobmrks = s:resignbmarks(a:dict, linenokey, bdict, linenum, bcmdpost, dobmrks)
            if (dosel == 0 && dobmrks == 0) | break | en
            let linenum += 1
        endfor
    endif
endf

fun! s:resignselect(line, key, linenum, cmdpost, selcnt)
    if !has_key(s:selectd, a:key) | retur a:selcnt | en
    if matchstr(a:line, s:selectd[a:key].line) == ""  | retur a:selcnt | en
    exe 'silent! sign place ' . a:key . ' line=' . a:linenum . a:cmdpost
    retu a:selcnt - 1
endf

fun! s:resignbmarks(dict, line, bdict, linenum, cmdpost, bmrkcnt)
    let line = svnj#utils#joinPath(a:dict.meta.url, a:line)
    if !has_key(g:bmarks, line) | retu a:bmrkcnt | en
    if !has_key(a:bdict, line)  | retu a:bmrkcnt | en
    let id = g:bmarks[line]
    exe 'silent! sign place ' . id . ' line=' . a:linenum . a:cmdpost
    return a:bmrkcnt - 1
endf

fun! s:signbmark(theid, isadd)
    try
        if !g:svnj_signs | return | en
        let theid = matchstr(a:theid, "\\d\\+")
        if a:isadd | exe 'silent! sign place ' . theid . ' line=' . line('.') . 
                    \ ' name=svnjbook '.' buffer='.bufnr('%')
        else | exe 'silent! sign unplace ' . theid | en
    catch 
        call svnj#utils#dbgHld("At signbmark", v:exception)
    endtry
endf
"2}}}
"1}}}
