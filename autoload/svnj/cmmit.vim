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
   return { 
               \ "\<Enter>"  : ['Ent:HEAD', 'svnj#cmmit#showCommits', ':HEAD'],
               \ "\<C-p>"    : ['C-p:PREV', 'svnj#cmmit#showCommits', ':PREV'],
               \ "\<C-w>"    : ['C-w:Wrap!', 'svnj#gopshdlr#toggleWrap'],
               \ "\<C-a>"     : ['C-a:Afiles', 'svnj#cmmit#affectedfiles'],
               \ "\<C-y>"    : ['C-y:Cmd', 'svnj#gopshdlr#cmd'],
               \ s:selectkey : [s:selectdscr, 'svnj#cmmit#handleCommitsSelect'],
               \ }
endf
"3}}}

"SVNCommits {{{2
fun! svnj#cmmit#SVNCommits(...)
    call svnj#init()
    try
        let target = a:0>0 && len(a:1) > 0 ? expand(a:1) : svnj#svn#workingRoot()
        let target = (target == "." || len(target) == 0 ) ?
                    \ getcwd() : target
        call svnj#cmmit#svnCommits(target, 'winj#populateJWindow')
        unlet! s:cdict
    catch
        let cdict = svnj#dict#new("SVNCommits")
        call svnj#utils#dbgHld("At SVNCommits", v:exception)
        call svnj#dict#addErr(cdict, 'Failed ', v:exception)
        call winj#populateJWindow(cdict)
        call cdict.clearme()
    endtry
endf

fun! svnj#cmmit#svnCommits(target, cb)
    let s:cdict = svnj#dict#new("SVNCommits")
    try
        let lastChngdRev = svnj#svn#lastChngdRev(a:target)
        let s:cdict.meta = svnj#svn#getMeta(a:target)
        let s:cdict.title = 'SVNLog '. s:cdict.meta.url . '@' . lastChngdRev
        let [entries, s:cdict.meta.cmd] = svnj#svn#logs(a:target)
        call svnj#dict#addEntries(s:cdict, 'commitsd', entries, s:commitops())
        call svnj#stack#push('svnj#cmmit#svnCommits', [a:target, 'winj#populate'])
        call call(a:cb, [s:cdict])
    catch
        call svnj#utils#dbgHld("At svnCommits", v:exception)
        call svnj#dict#addErr(s:cdict, 'Failed ', v:exception)
        call winj#populateJWindow(s:cdict)
    endtry
    return 1
endf
"2}}}

"callback handler {{{2
fun! svnj#cmmit#handleCommitsSelect(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        if svnj#select#remove(akey) | retu 1 | en
        let selectd = svnj#select#dict()
        if len(selectd) < 1
            return svnj#select#add(akey, adict.commitsd.contents[akey].line,
                        \ adict.meta.url, "")
        endif
        let oldkey = matchstr(keys(selectd)[0], "\\d\\+")
        call svnj#select#clear()
        let revisionA = adict.commitsd.contents[oldkey].revision
        let revisionB = adict.commitsd.contents[akey].revision
        call svnj#cmmit#showCommitsAcross(adict, revisionA, revisionB)
    catch
        call svnj#utils#dbgHld("At handleCommitsSelect", v:exception)
        return 0
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
    let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
    let aheadOrPrev = a:argdict.opt[0]
    if len(svnj#select#dict()) > 0 
        retu svnj#cmmit#handleCommitsSelect(a:argdict)
    endif
    let revision = adict.commitsd.contents[akey].revision
    let title = 'SVNDiff:' . revision . aheadOrPrev . " : " . adict.meta.fpath
    
    let svncmd = 'svn diff --non-interactive -' . revision . aheadOrPrev .
                \ ' --summarize '. adict.meta.fpath
    retu s:showCommits(adict, svncmd, title)
endf

fun! s:showCommits(dict, svncmd, title)
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
        return svnj#gopshdlr#displayAffectedFiles(adict, title, slist)
    catch
        call svnj#utils#dbgHld("At svnj#cmmit#affectedfiles", v:exception)
    endtry
endf
"2}}}
"1}}}
