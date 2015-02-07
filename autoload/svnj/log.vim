"===============================================================================
" File:         autoload/svnj/log.vim
" Description:  SVN Log
" Author:       Juneed Ahamed
"===============================================================================

"svnj#log {{{1

"script vars {{{2
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
let s:metakey = "meta"
"2}}}

"Key mappings for svn log output logops {{{3
let [s:topkey, s:topdscr] = svnj#utils#topkey()
let [s:ctrEntkey, s:ctrEntDescr] = svnj#utils#CtrlEntReplace('NoSplit')
fun! s:logops()
    retu { 
                \ "\<Enter>"   : {"bop":"<enter>", "dscr":'Ent:Diff', "fn":'svnj#gopshdlr#openFile', "args":['svnj#act#diff']},
                \ s:ctrEntkey  : {"bop":"<c-enter>", "dscr":s:ctrEntDescr, "fn":'svnj#gopshdlr#openFile', "args":['svnj#act#efile']},
                \ "\<C-v>"     : {"bop":"<c-v>", "dscr":'C-v:VS', "fn":'svnj#gopshdlr#openFile', "args":['svnj#act#vs']},
                \ "\<C-w>"     : {"bop":"<c-w>", "dscr":'C-w:Wrap!', "fn":'svnj#gopshdlr#toggleWrap'},
                \ "\<C-u>"     : {"bop":"<c-u>", "dscr":'C-u:Up', "fn":'svnj#stack#pop'},
                \ "\<C-a>"     : {"bop":"<c-a>", "dscr":'C-a:Afiles', "fn":'svnj#log#affectedfiles'},
                \ "\<C-h>"     : {"bop":"<c-h>", "dscr":'C-h:HEAD', "fn":'svnj#log#showCommits', "args":[":HEAD"]},
                \ "\<C-p>"     : {"bop":"<c-p>", "dscr":'C-p:PREV', "fn":'svnj#log#showCommits', "args":[":PREV"]},
                \ "\<C-i>"     : {"bop":"<c-i>", "dscr":'C-i:Info', "fn":'svnj#gopshdlr#info'},
                \ s:topkey     : {"bop":"<c-t>", "dscr":s:topdscr, "fn":'svnj#stack#top'},
                \ s:selectkey  : {"bop":"<c-space>", "dscr":s:selectdscr, "fn":'svnj#gopshdlr#select'},
                \ "\<C-s>"     : {"dscr":'C-s:stick!', "fn":'svnj#prompt#setNoLoop'},
                \ "\<F5>"      : {"dscr":'F5:redr', "fn":'svnj#act#forceredr'},
                \ }
endf
"3}}}

"SVNLog {{{2
fun! svnj#log#SVNLog(...)
    try
        call svnj#init()
        let [target, numlogs] = svnj#utils#parseTargetAndNumLogs(a:000)
    catch
        let ldict = svnj#dict#new("Log")
        call svnj#dict#addErr(ldict, 'Failed ', v:exception)
        retu winj#populateJWindow(ldict)
        unlet! ldict
    endtry
    call svnj#log#logs(target, numlogs, 'winj#populateJWindow', 1)
endf

fun! svnj#log#logs(lfile, maxlogs, populatecb, needLCR)
    let s:ldict = svnj#dict#new("Log")
    try
        let s:ldict.meta = svnj#svn#getMeta(a:lfile)
        let [entries, s:ldict.meta.cmd] = svnj#svn#logs(a:maxlogs,
                    \ s:ldict.meta.url)
        call svnj#dict#addEntries(s:ldict, 'logd', entries, s:logops())
        call s:logMenus(s:ldict.meta.url)

        let soc_rev = ""
        try 
            if g:svnj_send_soc_command
                let soc_rev = svnj#svn#log_stoponcopy(a:lfile)
                let soc_rev = " S@". soc_rev
            endif
        catch | endt

        if a:needLCR
            let lastChngdRev = svnj#svn#lastChngdRev(a:lfile)
            call s:addToTitle(s:ldict.meta.url . '@r' . lastChngdRev . soc_rev, 0)
        else
            call s:addToTitle(s:ldict.meta.url, 0)
        endif
        call svnj#stack#push('svnj#log#logs', [a:lfile, a:maxlogs, 
                    \ 'winj#populate', a:needLCR])
    catch
        call svnj#dict#addErr(s:ldict, 'Failed ', v:exception)
    endtry
    call call(a:populatecb, [s:ldict])
    retu svnj#passed()
endf
"2}}}

"menu {{{2
fun! s:logMenus(url)
    let menus = []
    if svnj#svn#isTrunk(a:url)
        call add(menus, svnj#dict#menuItem("List Branches",
                    \'svnj#log#listTopBranchURLs', "trunk2branch"))

    elseif svnj#svn#isBranch(a:url)
        if g:p_turl != ''
            call add(menus, svnj#dict#menuItem("List Trunk Files",
                        \'svnj#log#listFilesFrom', "branch2trunk"))
        endif
        call add(menus, svnj#dict#menuItem("List Branches",
                    \ 'svnj#log#listTopBranchURLs', "branch2branch"))

    elseif exists('g:p_burls') && g:svnj_warn_branch_log 
        call svnj#dict#addErr(s:ldict, 'Failed to get branches/trunk',
                    \ ' use :help g:svnj_branch_url or ' .
                    \ ' set g:svnj_warn_branch_log=0 at .vimrc' . 
                    \ ' to disable this message')

    endif
    call add(menus, svnj#dict#menuItem("Browse", 'svnj#log#browse', ''))
    call svnj#dict#addEntries(s:ldict, 'menud', menus, svnj#gopshdlr#menuops())
endf
"2}}}

"callbacks {{{2
fun! svnj#log#browse(key)
    retu svnj#brwsr#Menu('winj#populate')
endf

fun! svnj#log#listFilesFrom(key)
    let contents = s:ldict.menud.contents[a:key]
    let s:ldict = svnj#dict#new(s:ldict.title, {s:metakey : deepcopy(s:ldict.meta)})
    try
        let newroot = contents.convert ==# 'branch2trunk' ? g:p_turl : s:ldict.title . contents.title
        let [newurl, result] = s:converturl(s:ldict.meta.url, newroot)
        if result == "browserdisplayed" | retu "" | en

        let s:ldict.meta.url = newurl
        let s:ldict.title = newurl
        let [entries, s:ldict.meta.cmd] = svnj#svn#logs(g:svnj_max_logs, s:ldict.meta.url)
        call svnj#dict#addEntries(s:ldict, 'logd', entries, s:logops())
    catch
        call svnj#utils#dbgMsg("At listFilesFrom", v:exception)
        call svnj#dict#addErrUp(s:ldict, 'Failed to construct svn url',' OR File does not exist')
    endtry
    call winj#populate(s:ldict)
endf

fun! svnj#log#showCommits(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        let aheadOrPrev = a:argdict.opt[0]
        let url = filereadable(adict.meta.fpath) || isdirectory(adict.meta.fpath) ? 
                    \ adict.meta.fpath : adict.meta.url
        let revision =  adict.logd.contents[akey].revision
        let svncmd = 'svn diff --non-interactive -' .revision . aheadOrPrev . 
                    \ ' --summarize ' . fnameescape(url)
        let title = 'SVNDiff:'. revision . aheadOrPrev . " " . url
        retu svnj#gopshdlr#showCommits(a:argdict.dict, svncmd, title)
    catch
        call svnj#utils#dbgMsg("At svnj#log#showCommits", v:exception)
    endtry
endf

fun! svnj#log#affectedfiles(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        let title = ""
        let url = filereadable(adict.meta.fpath) || isdirectory(adict.meta.fpath) ? 
                    \ adict.meta.fpath : adict.meta.url
        let slist = []
        
        if !svnj#select#exists(akey)
           call svnj#select#add(akey, adict.logd.contents[akey].line,
                       \ url, adict.logd.contents[akey].revision)
        endif

        let [revisionA, revisionB] = ["", ""]
        for [key, sdict] in items(svnj#select#dict())
            if sdict.revision != ""
                if revisionA == "" | let revisionA = sdict.revision | cont | en
                if revisionB == "" | let revisionB = sdict.revision | cont | en
            endif
        endfor

        if revisionA != "" && revisionB != ""
            let title = revisionB . ':' . revisionA . '@' . url
            let [slist, adict.meta.cmd] = svnj#svn#affectedfilesAcross(url,
                        \ revisionB, revisionA)
        else 
            let revision = adict.logd.contents[akey].revision
            let title = revision . '@' . url
            let [slist, adict.meta.cmd] = svnj#svn#affectedfiles(url, revision)
        endif
        call svnj#select#clear()
        retu svnj#gopshdlr#displayAffectedFiles(adict, title, slist)
    catch
        call svnj#utils#dbgMsg("At svnj#log#affectedfiles", v:exception)
    endtry
endf
"2}}}

"branch/trunk listers {{{2
fun! svnj#log#listTopBranchURLs(key)
    let convert = s:ldict.menud.contents[a:key].convert
    let meta = deepcopy(s:ldict.meta)
    let s:ldict = svnj#dict#new("branches", {s:metakey : meta})
    try
        for burl in g:p_burls
            call svnj#dict#addEntries(s:ldict, 'menud',
                        \ [svnj#dict#menuItem(burl,'svnj#log#listBranches',
                        \ convert)], svnj#gopshdlr#menuops())
        endfor
    catch
        call svnj#utils#dbgMsg("At listTopBranchURLs", v:exception)
        call svnj#dict#addErr(s:ldict, 'Failed ', v:exception)
        call winj#populate(s:ldict)
        retu svnj#failed()
    endtry
    call winj#populate(s:ldict)
endf

fun! svnj#log#listBranches(key)
    let url = s:ldict.menud.contents[a:key].title
    let convert = s:ldict.menud.contents[a:key].convert
    let s:ldict = svnj#dict#new(url, {s:metakey : s:ldict.meta})
    try
        let svncmd = 'svn ls --non-interactive ' . url
        let bstr = svnj#utils#execShellCmd(svncmd)
        let blst = split(bstr, '\n')
        for branch in blst
            call svnj#dict#addEntries(s:ldict, 'menud', 
                        \ [svnj#dict#menuItem(branch, 'svnj#log#listFilesFrom',
                        \ convert)], svnj#gopshdlr#menuops())
        endfor
    catch
        call svnj#dict#addErr(s:ldict, 'Failed ', v:exception)
        retu winj#populate(s:ldict)
    endtry
    call winj#populate(s:ldict)
    retu svnj#passed()
endf
"2}}}

"conversion, browserdisplay {{{2
fun! s:converturl(furl, tonewroot)
    try
        let [fromlst, tolst] = [split(a:furl, '/\zs'), split(a:tonewroot, '/\zs')]
        if len(fromlst) < len(tolst) 
            retu s:displayBrowser(a:furl, a:tonewroot)
        endif
        
        let retlst = []
        for idx in range(0, len(tolst) -1)
            if fromlst[idx] == tolst[idx]
                call add(retlst, fromlst[idx])
            else
                call extend(retlst, tolst[idx :]) "Push rest of tourl
                let fromlst = fromlst[idx + 1 :] "idx + 1 as assuming it will be branch name
                break
            endif
        endfor

        while len(fromlst) > 0 && len(retlst) > 1
            let newurl = join(retlst, "") . join(fromlst, "")
            if svnj#svn#validURL(newurl) | retu [newurl, "filefound"] | en
            let fromlst = fromlst[1:]
        endwhile

    catch | call svnj#utils#dbgMsg("At s:converturl", v:exception) | endt
    retu s:displayBrowser(a:furl, a:tonewroot)
endf

fun! s:displayBrowser(fromURL, tonewroot)
    let root =  s:findroot(a:fromURL, a:tonewroot)
    if len(root) > 0 
        let filepath = substitute(a:fromURL, root, "", "") "Remove one element from from
        let filepath = join(split(filepath, '/\zs')[1:], "")
        call svnj#utils#input("Failed to construct url, Will provide the browser to get to it",
                    \ a:tonewroot . 
                    \ "\nNavigate:<Ctr-u> or <Ctrl-Ent> or <Enter>, Log:<Ctrl-l>, Diff:<Enter>\n",
                    \ "Any <Enter> to continue : ")
        call svnj#brwsr#svnBrowse(a:tonewroot, root, 0, 1, 'winj#populate', )
    endif
    retu ["", "browserdisplayed"]
endf

fun! s:findroot(url1, url2)
    let lst1 = split(a:url1, '/\zs')
    let lst2 = split(a:url2, '/\zs')
    let root = []
    for idx in range(0, (len(lst1)<=len(lst2) ? len(lst1) : len(lst2)) - 1)
        if lst1[idx] == lst2[idx] | call add(root, lst1[idx]) | cont | en
        break
    endfor
    return join(root, "")
endf

fun! s:addToTitle(msg, prefix)
    try | let s:ldict.title = a:prefix == 1 ?  a:msg. ' '. s:ldict.title : 
                \ s:ldict.title. ' ' . a:msg
    catch | endtry
endf
"2}}}
"1}}}
