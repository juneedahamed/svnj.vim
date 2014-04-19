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
               \ "\<C-w>"    : ['C-w:wrap!', 'svnj#gopshdlr#toggleWrap'],
               \ s:selectkey : [s:selectdscr, 'svnj#cmmit#handleCommitsSelect'],
               \ }
endf
"3}}}

"SVNCommits {{{2
fun! svnj#cmmit#SVNCommits()
    call svnj#init()
    try
        let wrd =svnj#svn#workingRoot()
        call svnj#cmmit#svnCommits(wrd, 'winj#populateJWindow')
        unlet! s:cdict
    catch
        let cdict = svnj#dict#new("SVNCommits")
        call svnj#utils#dbgHld("At SVNCommits", v:exception)
        call svnj#dict#addErr(cdict, 'Failed ', v:exception)
        call cdict.clearme()
    endtry
endf

fun! svnj#cmmit#svnCommits(wrd, cb)
    let s:cdict = svnj#dict#new("SVNCommits")
    try
        let lastChngdRev = svnj#svn#lastChngdRev(a:wrd)
        let s:cdict.meta = svnj#svn#getMeta(a:wrd)
        let s:cdict.title = 'SVNLog '. s:cdict.meta.url . '@' . lastChngdRev
        let entries = svnj#svn#logs(s:cdict.meta.wrd)
        call svnj#dict#addEntries(s:cdict, 'commitsd', entries, s:commitops())
        call svnj#stack#push('svnj#cmmit#svnCommits', [a:wrd, 'winj#populate'])
        call call(a:cb, [s:cdict])
    catch
        call svnj#utils#dbgHld("At svnCommits", v:exception)
        call svnj#dict#addErrUp(s:cdict, 'Failed ', v:exception)
    endtry
    return 1
endf
"2}}}

"callback handler {{{2
fun! svnj#cmmit#handleCommitsSelect(dict, key)
    try
        if svnj#select#remove(a:key) | retu 1 | en
        let selectd = svnj#select#dict()
        if len(selectd) < 1
            return svnj#select#add(a:key, a:dict.commitsd.contents[a:key].line,
                        \ a:dict.meta.url, "")
        endif
        let oldkey = matchstr(keys(selectd)[0], "\\d\\+")
        call svnj#select#clear()
        let revisionA = a:dict.commitsd.contents[oldkey].revision
        let revisionB = a:dict.commitsd.contents[a:key].revision
        call svnj#cmmit#showCommitsAcross(a:dict, revisionA, revisionB)
    catch
        call svnj#utils#dbgHld("At handleCommitsSelect", v:exception)
        return 0
    endtry
endf

fun! svnj#cmmit#showCommitsAcross(dict, revisionA, revisionB)
    let title = 'SVNDiff:' . a:revisionA . ':' . a:revisionB
    let revisiondiff = a:revisionA.':'.a:revisionB
    let svncmd = 'svn diff --non-interactive  -' . revisiondiff .
                \ ' --summarize '. a:dict.meta.wrd
    retu s:showCommits(a:dict, svncmd, title)
endf

fun! svnj#cmmit#showCommits(dict, key, headOrPrev)
    if len(svnj#select#dict()) > 0 | retu svnj#cmmit#handleCommitsSelect(a:dict, a:key) | en
    let revision = a:dict.commitsd.contents[a:key].revision
    let title = 'SVNDiff:' . revision . a:headOrPrev
    
    let svncmd = 'svn diff --non-interactive -' . revision . a:headOrPrev .
                \ ' --summarize '. a:dict.meta.wrd
    retu s:showCommits(a:dict, svncmd, title)
endf

fun! s:showCommits(dict, svncmd, title)
    let sdict = svnj#dict#new(a:title, {'meta' : deepcopy(a:dict.meta)})
    let slist = svnj#svn#summary(a:svncmd, a:dict.meta)
    if empty(slist)
        call svnj#dict#addErrUp(sdict, 'No commits found ..' , '' )
    else
        let ops = svnj#status#statusops() | call extend(ops, svnj#utils#topop())
        call svnj#dict#addEntries(sdict, 'statusd', slist, ops)
    endif
    call winj#populate(sdict)
endf
"2}}}
"1}}}
