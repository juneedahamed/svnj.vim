"===============================================================================
" File:         autoload/svnj/gopshdlr.vim
" Description:  Handle generic call backs/operations
" Author:       Juneed Ahamed
"===============================================================================

"Key mappings  menuops {{{2
let [s:topkey, s:topdscr] = svnj#utils#topkey()
fun! svnj#gopshdlr#menuops()
   return { "\<Enter>" : {"bop":"<enter>", "dscr":'Enter:Open', "fn":'svnj#gopshdlr#handleMenuOps'},
               \ "\<C-u>" : {"bop":"<c-u>", "dscr":'C-u:Up', "fn":'svnj#stack#pop'},
               \ s:topkey : {"bop":"<c-t>", "dscr":s:topdscr, "fn":'svnj#stack#top'},
               \ }
endf
"2}}}

fun! svnj#gopshdlr#handleMenuOps(argdict)
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu 2 | en
    return call(adict.menud.contents[akey].callback, [akey])
endf

fun! svnj#gopshdlr#toggleWrap(...)
    setl wrap! 
    return 2 "Donot clear fltr
endf

fun! svnj#gopshdlr#openFile(argdict)
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu 2 | en
    if has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
        let revision = adict.logd.contents[akey].revision
        call svnj#select#add(akey, adict.logd.contents[akey].line,
                \ adict.meta.url, revision)

        if adict.meta.isdir | return svnj#log#affectedfiles(a:argdict)|en

    elseif has_key(adict, 'browsed')
        if !svnj#select#exists(akey) | call svnj#gopshdlr#select(a:argdict) | en

    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        if !svnj#select#exists(akey) | call svnj#gopshdlr#select(a:argdict) | en
    endif

    retu svnj#select#openFiles(a:argdict.opt[0], g:svnj_max_open_files)
endf

fun! svnj#gopshdlr#openAllFiles(argdict)
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu 2 | en
    if has_key(adict, 'statusd') && len(adict.statusd.contents) > 0
        for key in keys(adict.statusd.contents)
            call svnj#gopshdlr#select(adict, key, a:line)
        endfor
    elseif has_key(adict, 'browsed') && len(adict.browsed.contents) > 0
        for key in keys(adict.browsed.contents)
            call svnj#gopshdlr#select(adict, key, a:line)
        endfor
    endif
    retu svnj#select#openFiles(a:argdict.opt[0], g:svnj_max_open_files)
endf

fun! svnj#gopshdlr#openFltrdFiles(argdict)
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu 2 | en
    call svnj#gopshdlr#selectFltrd(a:argdict)
    retu svnj#select#openFiles(a:argdict.opt[0], g:svnj_max_open_files)
endf

fun! svnj#gopshdlr#select(argdict)
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu 2 | en
    if svnj#select#remove(akey) | retu 2 | en
    if has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
        retu svnj#select#add(akey, adict.logd.contents[akey].line,
                \ adict.meta.url, adict.logd.contents[akey].revision)

    elseif has_key(adict, 'browsed')
        let pathurl = svnj#utils#joinPath(adict.bparent, aline)
        if svnj#utils#isSvnDirReg(pathurl) | retu 2 | en
        retu svnj#select#add(akey, aline, pathurl, "")

    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        if isdirectory(adict.statusd.contents[akey].fpath) | retu 2 | en
        retu svnj#select#add(akey, adict.statusd.contents[akey].line,
                    \ adict.statusd.contents[akey].fpath, "")
    endif
    return 2 "Donot clear fltr
endf

fun! svnj#gopshdlr#selectFltrd(argdict)
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu 2 | en
    if svnj#select#remove(akey) | retu 1 | en
    if has_key(adict, 'browsed')
        for i in range(1, line('$'))
            let [key, line] = svnj#utils#extractkey(getline(i))
            if key != "err" && line != ""
                let pathurl = svnj#utils#joinPath(adict.bparent, line)
                if svnj#utils#isSvnDirReg(pathurl) | cont | en
                call svnj#select#add(key, aline, pathurl, "")
            endif
        endfor
    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        let keys =  svnj#utils#keysCurBuffLines()
        if len(keys) <= 0 | retu 1 | en
        for key in keys
            if has_key(adict.statusd.contents, key)
                if isdirectory(adict.statusd.contents[key].fpath) | cont | en
                call svnj#select#add(key, adict.statusd.contents[key].line,
                            \ adict.statusd.contents[key].fpath, "")
            endif
        endfor
    endif
    return 2 "Donot clear fltr
endf

fun! svnj#gopshdlr#book(argdict)
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu 2 | en
    if has_key(adict, 'browsed')
        let pathurl = svnj#utils#joinPath(adict.bparent, aline)
        call svnj#select#book(pathurl)
    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        let fpath = adict.statusd.contents[akey].fpath
        call svnj#select#book(fpath)
    endif
    return 2 "Donot clear fltr
endf

fun! svnj#gopshdlr#info(argdict)
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu 2 | en
    let info = ""
    try
        if  has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
            let info =  svnj#svn#info(adict.statusd.contents[akey].fpath)
        elseif  has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
            let info =  svnj#svn#infolog(adict.logd.contents[akey].revision . "\ " . adict.meta.url)
        elseif has_key(adict, 'browsed') 
            let url = svnj#utils#joinPath(adict.bparent, aline)
            let info = svnj#svn#info(url)
        endif
        if info != "" | call svnj#utils#showConsoleMsg(info, 1)|en
        retu 2 "Donot clear fltr
    catch
        call svnj#utils#showErrorConsole(v:exception)
    endtry
    return 2 "Donot clear fltr
endf

fun! svnj#gopshdlr#displayAffectedFiles(dict, title, slist)
    try
        let title = "SVN Diff:" . a:title
        let sdict = svnj#dict#new(title, {'meta' : deepcopy(a:dict.meta)})
        if empty(a:slist)
            call svnj#dict#addErrUp(sdict, 'No affected files found ..' , '' )
        else
            let ops = svnj#status#statusops() 
            call extend(ops, svnj#utils#topop())
            call extend(ops, svnj#utils#upop())
            call svnj#dict#addEntries(sdict, 'statusd', a:slist, ops)
        endif
        call svnj#stack#push('svnj#gopshdlr#displayAffectedFiles', [a:dict, a:title, a:slist])
        call winj#populate(sdict)
    catch
        call svnj#utils#dbgHld("At svnj#gopshdlr#affectedfiles", v:exception)
    endtry
    return 1
endf

fun! svnj#gopshdlr#cmd(argdict)
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu 2 | en
    let x = has_key(adict, "meta") && has_key(adict.meta, "cmd") ? 
                \ svnj#utils#showConsoleMsg(adict.meta.cmd, 1) : 0
    retu 2 "Donot clear fltr
endf
