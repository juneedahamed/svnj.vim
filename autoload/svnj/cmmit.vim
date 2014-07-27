"===============================================================================
" File:         autoload/svnj/cmmit.vim
" Description:  SVN Commits (svn diff across directories useful for verifying 
"               checkins
" Author:       Juneed Ahamed
"===============================================================================

"autoload/svnj/cmmit.vim {{{1
"ops commitsop {{{3
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
fun! s:commitops()
   retu { 
               \ "\<Enter>"  :{"bop":"<enter>", "dscr":'Ent:HEAD', "fn":'svnj#cmmit#showCommits', "args":[':HEAD']},
               \ "\<C-p>"    :{"bop":"<c-p>", "dscr":'C-p:PREV', "fn":'svnj#cmmit#showCommits', "args":[':PREV']},
               \ "\<C-w>"    :{"bop":"<c-w>", "dscr":'C-w:Wrap!', "fn":'svnj#gopshdlr#toggleWrap'},
               \ "\<C-a>"    :{"bop":"<c-a>", "dscr":'C-a:Afiles', "fn":'svnj#cmmit#affectedfiles'},
               \ "\<C-y>"    :{"bop":"<c-y>", "dscr":'C-y:Cmd', "fn":'svnj#gopshdlr#cmd'},
               \ s:selectkey :{"bop":"<c-space>", "dscr":s:selectdscr, "fn":'svnj#cmmit#handleCommitsSelect'},
               \ "\<C-s>"    : {"dscr":'C-s:stick!', "fn":'svnj#prompt#setNoLoop'},
               \ "\<F5>"     : {"dscr":'F5:redr', "fn":'svnj#act#forceredr'},
               \ }
endf
"3}}}

"SVNCommits {{{2
fun! svnj#cmmit#SVNCommits(...)
    call svnj#init()
    try
        let [target, numlogs] = svnj#utils#parseTargetAndNumLogs(a:000)
        call svnj#cmmit#svnCommits(target, numlogs, 'winj#populateJWindow')
        unlet! s:cdict
    catch
        let cdict = svnj#dict#new("SVNCommits")
        call svnj#utils#dbgMsg("At SVNCommits", v:exception)
        call svnj#dict#addErr(cdict, 'Failed ', v:exception)
        call winj#populateJWindow(cdict)
        unlet! cdict
    endtry
endf

fun! svnj#cmmit#svnCommits(target, maxlogs, cb)
    let s:cdict = svnj#dict#new("SVNCommits")
    try
        let lastChngdRev = svnj#svn#lastChngdRev(a:target)
        let s:cdict.meta = svnj#svn#getMeta(a:target)
        let s:cdict.title = 'SVNLog '. s:cdict.meta.url . '@' . lastChngdRev
        let [entries, s:cdict.meta.cmd] = svnj#svn#logs(a:maxlogs, a:target)
        call svnj#dict#addEntries(s:cdict, 'commitsd', entries, s:commitops())
        call svnj#stack#push('svnj#cmmit#svnCommits', [a:target, a:maxlogs, 'winj#populate'])
        call call(a:cb, [s:cdict])
    catch
        call svnj#utils#dbgMsg("At svnj#cmmit#svnCommits", v:exception)
        call svnj#dict#addErr(s:cdict, 'Failed ', v:exception)
        call winj#populateJWindow(s:cdict)
    endtry
    retu svnj#passed()
endf
"2}}}

"callback handler {{{2
fun! svnj#cmmit#handleCommitsSelect(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        if svnj#select#remove(akey) | retu svnj#passed() | en
        let selectd = svnj#select#dict()
        if len(selectd) < 1
            retu svnj#select#add(akey, adict.commitsd.contents[akey].line,
                        \ adict.meta.url, "")
        endif
        let oldkey = matchstr(keys(selectd)[0], "\\d\\+")
        call svnj#select#clear()
        let revisionA = adict.commitsd.contents[oldkey].revision
        let revisionB = adict.commitsd.contents[akey].revision
        call svnj#cmmit#showCommitsAcross(adict, revisionA, revisionB)
    catch
        call svnj#utils#dbgMsg("At handleCommitsSelect", v:exception)
        retu svnj#failed()
    endtry
endf

fun! svnj#cmmit#showCommitsAcross(dict, revisionA, revisionB)
    let title = 'SVNDiff:' . a:revisionA . ':' . a:revisionB . 
                \ " : " . a:dict.meta.fpath
    let revisiondiff = a:revisionA.':'.a:revisionB
    let svncmd = 'svn diff --non-interactive  -' . revisiondiff .
                \ ' --summarize '. a:dict.meta.fpath
    retu s:showCommits(a:dict, svncmd, title)
endf

fun! svnj#cmmit#showCommits(argdict)
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    let aheadOrPrev = a:argdict.opt[0]
    if len(svnj#select#dict()) > 0 
        retu svnj#cmmit#handleCommitsSelect(a:argdict)
    endif
    let revision = adict.commitsd.contents[akey].revision
    let title = 'SVNDiff:' . revision . aheadOrPrev . " : " . adict.meta.fpath
    
    let svncmd = 'svn diff --non-interactive -' . revision . aheadOrPrev .
                \ ' --summarize '. adict.meta.fpath
    retu svnj#gopshdlr#showCommits(a:argdict.dict, svncmd, title)
endf

fun! svnj#cmmit#affectedfiles(argdict)
    try
        let title = ""
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        let url = filereadable(adict.meta.fpath) || isdirectory(adict.meta.fpath) ? 
                    \ adict.meta.fpath : adict.meta.url
        let slist = []

        if !svnj#select#exists(akey)
           call svnj#select#add(akey, adict.commitsd.contents[akey].line, url, "")
        endif

        let revision = adict.commitsd.contents[akey].revision
        let title = revision . '@' . url
        let [slist, adict.meta.cmd] = svnj#svn#affectedfiles(url, revision)
        call svnj#select#clear()
        retu svnj#gopshdlr#displayAffectedFiles(adict, title, slist)
    catch
        call svnj#utils#dbgMsg("At svnj#cmmit#affectedfiles", v:exception)
    endtry
endf
"2}}}
"1}}}
