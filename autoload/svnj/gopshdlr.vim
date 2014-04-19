"===============================================================================
" File:         autoload/svnj/gopshdlr.vim
" Description:  Handle generic call backs/operations
" Author:       Juneed Ahamed
"===============================================================================

"Key mappings  menuops {{{2
fun! svnj#gopshdlr#menuops()
   return { "\<Enter>": ['Enter:Open', 'svnj#gopshdlr#handleMenuOps'],
               \ "\<C-u>": ['C-u:up', 'svnj#stack#pop'],
               \ "\<C-t>": ['C-t:top', 'svnj#stack#top']}
endf
"2}}}

fun! svnj#gopshdlr#handleMenuOps(dict, key)
    return call(a:dict.menud.contents[a:key].callback, [a:key])
endf

fun! svnj#gopshdlr#toggleWrap(...)
    setl wrap! 
    return 2 
endf

fun! svnj#gopshdlr#openFile(dict, key, callback)
    if has_key(a:dict, 'logd') && has_key(a:dict.logd.contents, a:key)
        let revision = a:dict.logd.contents[a:key].revision
        call svnj#select#add(a:key, a:dict.logd.contents[a:key].line,
                \ a:dict.meta.url, revision)

    elseif has_key(a:dict, 'browsed') && has_key(a:dict.browsed.contents, a:key)
        if !svnj#select#exists(a:key) | call svnj#gopshdlr#select(a:dict, a:key) | en

    elseif has_key(a:dict, 'statusd') && has_key(a:dict.statusd.contents, a:key)
        if !svnj#select#exists(a:key) | call svnj#gopshdlr#select(a:dict, a:key) | en
    endif

    let cnt = svnj#select#openFiles(a:callback, g:svnj_max_open_files)
    retu cnt
endf

fun! svnj#gopshdlr#openAllFiles(dict, key, callback)
    if has_key(a:dict, 'statusd') && len(a:dict.statusd.contents) > 0
        for key in keys(a:dict.statusd.contents)
            call svnj#gopshdlr#select(a:dict, key)
        endfor
    elseif has_key(a:dict, 'browsed') && len(a:dict.browsed.contents) > 0
        for key in keys(a:dict.browsed.contents)
            call svnj#gopshdlr#select(a:dict, key)
        endfor
    endif
    retu svnj#select#openFiles(a:callback, g:svnj_max_open_files)
endf

fun! svnj#gopshdlr#openFltrdFiles(dict, key, callback)
    call svnj#gopshdlr#selectFltrd(a:dict, a:key)
    retu svnj#select#openFiles(a:callback, g:svnj_max_open_files)
endf

fun! svnj#gopshdlr#select(dict, key)
    if svnj#select#remove(a:key) | retu 2 | en
    if has_key(a:dict, 'logd') && has_key(a:dict.logd.contents, a:key)
        retu svnj#select#add(a:key, a:dict.logd.contents[a:key].line,
                \ a:dict.meta.url, a:dict.logd.contents[a:key].revision)

    elseif has_key(a:dict, 'browsed') && has_key(a:dict.browsed.contents, a:key)
        let pathurl = svnj#utils#joinPath(a:dict.meta.url, a:dict.browsed.contents[a:key].line)
        if svnj#utils#isSvnDirReg(pathurl) | retu 2 | en
        retu svnj#select#add(a:key, a:dict.browsed.contents[a:key].line, pathurl, "")

    elseif has_key(a:dict, 'statusd') && has_key(a:dict.statusd.contents, a:key)
        retu svnj#select#add(a:key, a:dict.statusd.contents[a:key].line,
                    \ a:dict.statusd.contents[a:key].fpath, "")
    endif
    return 2
endf

fun! svnj#gopshdlr#selectFltrd(dict, key)
    if svnj#select#remove(a:key) | retu 1 | en
    let keys =  svnj#utils#keysCurBuffLines()
    if len(keys) <= 0 | retu 1 | en
    if has_key(a:dict, 'browsed') && has_key(a:dict.browsed.contents, a:key)
        for key in keys
            if has_key(a:dict.browsed.contents, key)
                let pathurl = svnj#utils#joinPath(a:dict.meta.url, a:dict.browsed.contents[key].line)
                if svnj#utils#isSvnDirReg(pathurl) | cont | en
                call svnj#select#add(key, a:dict.browsed.contents[key].line, pathurl, "")
            endif
        endfor
    elseif has_key(a:dict, 'statusd') && has_key(a:dict.statusd.contents, a:key)
        for key in keys
            if has_key(a:dict.statusd.contents, key)
                call svnj#select#add(key, a:dict.statusd.contents[key].line,
                            \ a:dict.statusd.contents[key].fpath, "")
            endif
        endfor
    endif
    retu 1
endf

fun! svnj#gopshdlr#book(dict, key)
    if has_key(a:dict, 'browsed') && has_key(a:dict.browsed.contents, a:key)
        let pathurl = svnj#utils#joinPath(a:dict.meta.url, 
                    \ a:dict.browsed.contents[a:key].line)
        call svnj#select#book(pathurl)
    endif
    return 1
endf

fun! svnj#gopshdlr#info(dict, key)
    let info = ""
    try
        if has_key(a:dict, 'browsed') && has_key(a:dict.browsed.contents, a:key)
            let url = svnj#utils#joinPath(a:dict.meta.url, 
                        \ a:dict.browsed.contents[a:key].line)
            let info = svnj#svn#info(url)
        elseif  has_key(a:dict, 'statusd') && has_key(a:dict.statusd.contents, a:key)
            let info =  svnj#svn#info(a:dict.statusd.contents[a:key].fpath)
        endif
        if info != "" | return svnj#utils#showConsoleMsg(info, 1)|en
    catch
        "call svnj#utils#dbgHld("At svnj#gopshdlr#info", v:exception)
        call svnj#utils#showErrorConsole(v:exception)
    endtry
    retu 1
endf
