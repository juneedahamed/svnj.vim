"===============================================================================
" File:         autoload/svnj/gopshdlr.vim
" Description:  Handle generic call backs/operations
" Author:       Juneed Ahamed
"===============================================================================

"Key mappings  menuops {{{2
let [s:topkey, s:topdscr] = svnj#utils#topkey()
fun! svnj#gopshdlr#menuops()
   retu { "\<Enter>" : {"bop":"<enter>", "dscr":'Enter:Open', "fn":'svnj#gopshdlr#handleMenuOps'},
           \ "\<C-u>" : {"bop":"<c-u>", "dscr":'C-u:Up', "fn":'svnj#stack#pop'},
           \ s:topkey : {"bop":"<c-t>", "dscr":s:topdscr, "fn":'svnj#stack#top'},
           \ }
endf
"2}}}

fun! svnj#gopshdlr#handleMenuOps(argdict) "{{{2
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu svnj#nofltrclear() | en
    retu call(adict.menud.contents[akey].callback, [akey])
endf
"2}}}

fun! svnj#gopshdlr#toggleWrap(...) "{{{2
    setl wrap! 
    retu svnj#nofltrclear()
endf
"2}}}

fun! svnj#gopshdlr#openFile(argdict) "{{{2
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu svnj#nofltrclear() | en
    if has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
        let revision = adict.logd.contents[akey].revision
        call svnj#select#add(akey, adict.logd.contents[akey].line,
                \ adict.meta.url, revision)
        if adict.meta.isdir | retu svnj#log#affectedfiles(a:argdict)|en

    elseif has_key(adict, 'browsed')
        if !svnj#select#exists(akey) | call svnj#gopshdlr#select(a:argdict) | en

    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        if !svnj#utils#isdir(adict.statusd.contents[akey].fpath)
            if !svnj#select#exists(akey) | call svnj#gopshdlr#select(a:argdict) | en
        endif
    endif

    retu svnj#select#openFiles(a:argdict.opt[0], g:svnj_max_open_files)
endf
"2}}}

fun! svnj#gopshdlr#openAllFiles(argdict) "{{{2
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu svnj#nofltrclear() | en
    if has_key(adict, 'statusd') && len(adict.statusd.contents) > 0
        call map(keys(adict.statusd.contents, 'svnj#gopshdlr#select(adict, v:val , a:line)'))
    elseif has_key(adict, 'browsed') && len(adict.browsed.contents) > 0
        call map(keys(adict.browsed.contents, 'svnj#gopshdlr#select(adict, v:val , a:line)'))
    endif
    retu svnj#select#openFiles(a:argdict.opt[0], g:svnj_max_open_files)
endf
"2}}}

fun! svnj#gopshdlr#openFltrdFiles(argdict) "{{{2
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu svnj#nofltrclear() | en
    call svnj#gopshdlr#selectFltrd(a:argdict)
    retu svnj#select#openFiles(a:argdict.opt[0], g:svnj_max_open_files)
endf
"2}}}

fun! svnj#gopshdlr#select(argdict) "{{{2
    "select line for log, browse and status dict
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu svnj#nofltrclear() | en
    if svnj#select#remove(akey) | retu svnj#nofltrclear() | en
    if has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
        retu svnj#select#add(akey, adict.logd.contents[akey].line,
                \ adict.meta.url, adict.logd.contents[akey].revision)

    elseif has_key(adict, 'browsed')
        let pathurl = svnj#utils#joinPath(adict.bparent, aline)
        retu svnj#select#add(akey, aline, pathurl, "")

    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        retu svnj#select#add(akey, adict.statusd.contents[akey].line,
                    \ adict.statusd.contents[akey].fpath, "")
    endif
    retu svnj#nofltrclear()
endf
"2}}}

fun! svnj#gopshdlr#selectFltrd(argdict) "{{{2
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu svnj#nofltrclear() | en
    if svnj#select#remove(akey) | retu svnj#passed() | en
    if has_key(adict, 'browsed')
        retu s:selectFltrdBrowsed(a:argdict)
    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        retu s:selectFltrdStatusd(a:argdict)
    endif
    retu svnj#nofltrclear()
endf

fun! s:selectFltrdBrowsed(argdict)
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    for i in range(1, line('$'))
        let [key, line] = svnj#utils#extractkey(getline(i))
        if key != "err" && line != ""
            let pathurl = svnj#utils#joinPath(adict.bparent, line)
            if svnj#utils#isSvnDirReg(pathurl) | cont | en
            call svnj#select#add(key, aline, pathurl, "")
        endif
    endfor
    retu svnj#nofltrclear() 
endf

fun! s:selectFltrdStatusd(argdict)
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    let keys =  svnj#utils#keysCurBuffLines()
    if len(keys) <= 0 | retu svnj#passed() | en
    for key in keys
        if has_key(adict.statusd.contents, key)
            "if svnj#utils#isdir(adict.statusd.contents[key].fpath) | cont | en
            call svnj#select#add(key, adict.statusd.contents[key].line,
                        \ adict.statusd.contents[key].fpath, "")
        endif
    endfor
    retu svnj#nofltrclear()
endf
"2}}}

fun! svnj#gopshdlr#selectall(argdict) "{{{2
    call svnj#gopshdlr#selectFltrd(a:argdict)
    call svnj#select#resign(a:argdict.dict)
endf
"2}}}

fun! svnj#gopshdlr#book(argdict) "{{{2
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu svnj#nofltrclear() | en
    if has_key(adict, 'browsed')
        call svnj#select#book(svnj#utils#joinPath(adict.bparent, aline))
    elseif has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
        call svnj#select#book(adict.statusd.contents[akey].fpath)
    endif
    retu svnj#nofltrclear()
endf
"2}}}

fun! svnj#gopshdlr#info(argdict) "{{{2
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu svnj#nofltrclear() | en
    let info = ""
    try
        if has_key(adict, 'statusd') && has_key(adict.statusd.contents, akey)
            let info =  svnj#svn#info(adict.statusd.contents[akey].fpath)
        elseif has_key(adict, 'logd') && has_key(adict.logd.contents, akey)
            let info =  svnj#svn#infolog(adict.logd.contents[akey].revision . "\ " . adict.meta.url)
        elseif has_key(adict, 'browsed') 
            let info = svnj#svn#info(svnj#utils#joinPath(adict.bparent, aline))
        endif
        if info != "" | call svnj#utils#showConsoleMsg(info, 1) | en
        retu svnj#nofltrclear() 
    catch
        call svnj#utils#showerr(v:exception)
    endtry
    retu svnj#nofltrclear() 
endf
"2}}}

fun! svnj#gopshdlr#displayinfo(revision, svnurl) "{{{2
    let arg = a:revision . "\ " . a:svnurl
    let info = svnj#svn#infolog(arg)
    call svnj#utils#showConsoleMsg(info, 1)
endf
"2}}}


fun! svnj#gopshdlr#displayAffectedFiles(dict, title, slist) "{{{2
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
        call svnj#utils#dbgMsg("At svnj#gopshdlr#affectedfiles", v:exception)
    endtry
    retu svnj#passed()
endf
"2}}}

fun! svnj#gopshdlr#cmd(argdict) "{{{2
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    if akey == 'err' | retu svnj#nofltrclear() | en
    let x = has_key(adict, "meta") && has_key(adict.meta, "cmd") ? 
                \ svnj#utils#showConsoleMsg(adict.meta.cmd, 1) : 0
    retu svnj#nofltrclear() 
endf
"2}}}

fun! svnj#gopshdlr#showCommits(dict, svncmd, title) "{{{2
    let sdict = svnj#dict#new(a:title, {'meta' : deepcopy(a:dict.meta)})
    let [slist, sdict.meta.cmd] = svnj#svn#summary(a:svncmd)
    if empty(slist)
        call svnj#dict#addErrTop(sdict, 'No commits found ..' , '' )
    else
        let ops = svnj#status#statusops() | call extend(ops, svnj#utils#topop())
        call svnj#dict#addEntries(sdict, 'statusd', slist, ops)
    endif
    call winj#populate(sdict)
endf
"2}}}

fun! svnj#gopshdlr#commit(argdict) "{{{2
    let commitfiles = [] 
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu svnj#nofltrclear() | en

    if !svnj#select#exists(akey) | call svnj#gopshdlr#select(a:argdict) | en
    let commitfiles = map(values(svnj#select#dict()), 'v:val.path')
    
    if len(commitfiles) > 0
        call svnj#commit#prepCommit(commitfiles)
        retu svnj#fltrclearandexit() "clear filter, feed esc
    endif
endf
"2}}}

fun! svnj#gopshdlr#add(argdict) "{{{2
    let addfiles = [] 
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    if akey == 'err' | retu svnj#nofltrclear() | en

    if !svnj#select#exists(akey) | call svnj#gopshdlr#select(a:argdict) | en
    let addfiles = map(values(svnj#select#dict()), 'v:val.path')

    if len(addfiles) > 0
        call svnj#svnadd#prepAdd(addfiles)
        retu svnj#fltrclearandexit() "clear filter, feed esc
    endif
endf
"2}}}

fun! svnj#gopshdlr#closeBuffer(argdict) "{{{2
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    let curbufname = a:argdict.opt[0]
    if has_key(adict, 'browsed') 
        let buffile = svnj#utils#joinPath(adict.bparent, aline)
        try
            if a:argdict.opt[0] == buffile | retu | en
            exec "bd " fnameescape(buffile)
            call svnj#brwsr#brwsBuffer('winj#populate', curbufname)
        catch | call svnj#utils#dbgMsg("At svnj#gopshdlr#closeBuffer: ", v:exception) | endt
    endif
endf
"2}}}

fun! svnj#gopshdlr#removeSticky(...) "{{{2
    if !svnj#prompt#isploop()
        call feedkeys("\<C-s>")
    endif
endf
"2}}}

