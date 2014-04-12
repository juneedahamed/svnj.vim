"===============================================================================
" File:         autoload/svnj/log.vim
" Description:  SVN Browser
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
"===============================================================================

"svnj#log {{{1

"script vars {{{2
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
let s:metakey = "meta"
let s:flistkey = "flistd"
"2}}}

"Key mappings for svn log output logops {{{3
fun! s:logops()
    return { 
                \ "\<Enter>"   : ['Ent:Diff', 'svnj#gopshdlr#openFile', 'winj#diffFile'],
                \ "\<C-Enter>" : ['C-Enter:NoSplit', 'svnj#gopshdlr#openFile', 'winj#newBufOpen'],
                \ "\<C-o>"     : ['C-o:Open', 'svnj#gopshdlr#openFile', 'winj#openRepoFileVS'],
                \ "\<C-w>"     : ['C-w:wrap!', 'svnj#gopshdlr#toggleWrap'],
                \ "\<C-u>"     : ['C-u:up', 'svnj#stack#pop'],
                \ "\<C-t>"     : ['C-t:top', 'svnj#stack#top'],
                \ s:selectkey  : [s:selectdscr, 'svnj#gopshdlr#select'],
                \ }
endf
"3}}}

"Key mappings for flist {{{3
fun! s:flistops()
   return { "\<Enter>"  : ['Ent:Select', 'svnj#log#flistSelected']}
endf
"3}}}

"SVNLog {{{2
fun! svnj#log#SVNLog()
    try
        call svnj#init()
        let tfile = svnj#utils#bufFileAbsPath()
    catch
        let ldict = svnj#dict#new("SVN Log")
        call svnj#dict#addErr(ldict, 'Failed ', v:exception)
        return winj#populateJWindow(ldict)
        unlet! ldict
    endtry
    call svnj#log#logs(tfile, 'winj#populateJWindow', 1)
endf

fun! svnj#log#logs(lfile, populatecb, needLCR)
    let s:ldict = svnj#dict#new("SVN Log")
    try
        let s:ldict.meta = svnj#svn#getMeta(a:lfile)
        let entries = svnj#svn#logs(s:ldict.meta.url)
        call svnj#dict#addEntries(s:ldict, 'logd', entries, s:logops())
        call s:logMenus(s:ldict.meta.url)
        if a:needLCR
            let lastChngdRev = svnj#svn#lastChngdRev(a:lfile)
            call s:addToTitle(s:ldict.meta.url . '@' . lastChngdRev, 0)
        else
            call s:addToTitle(s:ldict.meta.url, 0)
        endif
        call svnj#stack#push('svnj#log#logs', [a:lfile, 'winj#populate', a:needLCR])
    catch
        call svnj#dict#addErr(s:ldict, 'Failed ', v:exception)
    endtry
    call call(a:populatecb, [s:ldict])
    return 1
endf
"2}}}

"menu {{{2
fun! s:logMenus(url)
    let menus = []
    if svnj#svn#isBranch(a:url)
        if g:p_turl != ''
            call add(menus, svnj#dict#menuItem("List Trunk Files",
                        \'svnj#log#listFilesFrom', "branch2trunk"))
        endif
        call add(menus, svnj#dict#menuItem("List Branches",
                    \ 'svnj#log#listTopBranchURLs', "branch2branch"))

    elseif svnj#svn#isTrunk(a:url)
        call add(menus, svnj#dict#menuItem("List Branches",
                    \'svnj#log#listTopBranchURLs', "trunk2branch"))

    elseif exists('g:p_burls') "TODO
        call svnj#dict#addErr(s:ldict, 'Failed to get branches/trunk',
                    \ ' use :help g:svnj_branch_url')
    endif
    call add(menus, svnj#dict#menuItem("Browse", 'svnj#log#browse', ''))
    call svnj#dict#addEntries(s:ldict, 'menud', menus, svnj#gopshdlr#menuops())
endf
"2}}}

"callbacks {{{2
fun! svnj#log#browse(key)
    let meta = svnj#svn#getMeta(getcwd())
    call svnj#brwsr#Menu('winj#populate', meta)
    return 1
endf

fun! svnj#log#listFilesFrom(key)
    let contents = s:ldict.menud.contents[a:key]
    let s:ldict = svnj#dict#new(s:ldict.title, {s:metakey : deepcopy(s:ldict.meta)})
    let fileurl = ''
    try
        if contents.convert ==# 'branch2branch'
            let root = svnj#svn#branchRoot(s:ldict.meta.url)
            let new_url = substitute(s:ldict.meta.url, root, s:ldict.title, '')
            let fileurl = s:svnBranchURLFromBranch(new_url, contents.title)
        elseif contents.convert ==# 'branch2trunk'
            let fileurl = s:svnTrunkURLFromBranchURL(s:ldict.meta.url)
        elseif contents.convert ==# 'trunk2branch'
            let fileurl = s:svnBranchURLFromTrunk(s:ldict.meta.url, s:ldict.title, contents.title)
        endif

        let fileurl = svnj#svn#validateSVNURLInteractive(fileurl)
        let s:ldict.meta.url = fileurl
        let s:ldict.title = fileurl
        call svnj#dict#addEntries(s:ldict, 'logd', svnj#svn#logs(s:ldict.meta.url), s:logops())
    catch
        call svnj#utils#dbgHld("At listFilesFrom", v:exception)
        call svnj#dict#addErrUp(s:ldict, 'Failed to construct svn url',' OR File does not exist')
    endtry
    call winj#populate(s:ldict)
endf
"2}}}

"URLs translaters branch2branch, branch2trunk etc., {{{2
fun! s:svnBranchURLFromTrunk(tURL, broot, tbname)
    let bURL = a:broot . a:tbname
    let rbURL = substitute(a:tURL, g:p_turl, bURL, '')

    if !svnj#svn#validURL(rbURL) && g:svnj_find_files == 1
        let tfile = substitute(a:tURL, g:p_turl, "", "")
        let [ tbURLs, result] = s:findFile(bURL, tfile)
        if result | return tbURLs[0] | en
    endif
    return rbURL
endf

fun! s:svnBranchURLFromBranch(bURL, tbname)
    let fbname = svnj#svn#branchName(a:bURL)
    let root = svnj#svn#branchRoot(a:bURL)

    "This check for filename selection
    if !svnj#utils#isSvnDir(a:tbname)
        let tryURL = root . a:tbname
        if svnj#svn#validURL(tryURL) | retu tryURL | en
    en

    let rbURL = substitute(a:bURL, fbname, a:tbname, '')
    if !svnj#svn#validURL(rbURL) && g:svnj_find_files == 1
        let tfile = substitute(a:bURL, root, "", "")
        let [ tbURLs, result] = s:findFile(root . a:tbname, tfile)
        if result | return tbURLs[0] | en
    endif
    return rbURL
endf

fun! s:svnTrunkURLFromBranchURL(bURL)
    let branchname = svnj#svn#branchName(a:bURL)
    if strlen(branchname) > 0
        let root = svnj#svn#branchRoot(a:bURL)
        let currentbranchurl = root . branchname
        let tURL = substitute(a:bURL, currentbranchurl, g:p_turl, '')
        if !svnj#svn#validURL(tURL) && g:svnj_find_files == 1
            let tfile = substitute(a:bURL, currentbranchurl, "", "")
            let [ tURLs, result] = s:findFile(g:p_turl, tfile)
            if result | return tURLs[0] | en
        endif
        return tURL
    endif
    return ''
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
                        \ [svnj#dict#menuItem(burl,'svnj#log#listBranchesHandler',
                        \ convert)], svnj#gopshdlr#menuops())
        endfor
    catch
        call svnj#utils#dbgHld("At listTopBranchURLs", v:exception)
        call svnj#dict#addErr(s:ldict, 'Failed ', v:exception)
        call winj#populate(s:ldict)
        return 1
    endtry
    call winj#populate(s:ldict)
endf

fun! svnj#log#listBranchesHandler(key)
    let url = s:ldict.menud.contents[a:key].title
    let convert = s:ldict.menud.contents[a:key].convert
    return svnj#log#listBranches(url, convert)
endf

fun! svnj#log#listBranches(url, convert)
    let s:ldict = svnj#dict#new(a:url, {s:metakey : s:ldict.meta})
    try
        let svncmd = 'svn ls --non-interactive ' . a:url
        let bstr = svnj#utils#execShellCmd(svncmd)
        let blst = split(bstr, '\n')
        let cbrnch = svnj#svn#branchName(s:ldict.meta.url)
        for branch in blst
            if cbrnch != branch
                call svnj#dict#addEntries(s:ldict, 'menud', 
                            \ [svnj#dict#menuItem(branch, 'svnj#log#listFilesFrom',
                            \ a:convert)], svnj#gopshdlr#menuops())
            endif
        endfor
    catch
        call svnj#dict#addErr(s:ldict, 'Failed ', v:exception)
        return winj#populate(s:ldict)
    endtry
    call winj#populate(s:ldict)
endf
"2}}}

"flist functions findfiles, askUsr {{{2
fun! s:findFile(pURL, tfile)
    let shellist = []
    try
        let fname = fnamemodify(a:tfile, ":t")
        let svncmd = 'svn list -R --non-interactive ' . a:pURL
        echohl Error | echo "" | echon "Please wait, Finding file  : " |  echohl None | echon fname
        let shellout = svnj#utils#execShellCmd(svncmd)
        let tshellist = split(shellout, '\n')
        call s:warnlog(tshellist, a:tfile, fname)
        let pat = ".*".fname
        let shellist = filter(tshellist, 'v:val =~ pat')

        "If shell returned one file we found the required one
        if len(shellist) == 1 
            let fURL = a:pURL . shellist[0]
            if svnj#svn#validURL(fURL) | retu [[fURL,] , 1] | en
        endif

        "If shell returned more than one file will have to narrow it down
        if len(shellist) > 0
            let [shellist, result] = s:narrowfiles(shellist, a:pURL, a:tfile)
            if result | return [shellist, result] | en

            "ask user for a file
            let usrFile = s:askUsrForFile(shellist, a:tfile)
            if usrFile != ""
                let fURL = a:pURL . usrFile
                if svnj#svn#validURL(fURL) | retu [[fURL,] , 1] | en
            endif
        endif
    catch
    endtry
    return [shellist, 0]
endf

fun! s:narrowfiles(flist, pURL, tfile)
    let glist = a:flist
    if len(glist) > 0
        "if whole path matches we are done
        let found = index(glist, a:tfile)
        if found != -1 
            let fURL = a:pURL . glist[found]
            if svnj#svn#validURL(fURL) | retu [[fURL,] , 1] | en
        endif
        
        "whole path did not match lets try to narrow it down
        let expr = ".*".a:tfile
        let flist = filter(copy(glist),  'v:val =~ expr' )
        if len(flist) == 1
            let fURL = a:pURL . flist[0]
            if svnj#svn#validURL(fURL) | retu [[fURL,] , 1] | en
        elseif len(flist) > 1
            let glist = flist
        endif

        if len(glist) > 0 && len(glist) < 400
            "Attempt by trying to match the fpath, parse tfile upwards
            let ttfile = split(a:tfile, "/")
            let dpath = ""
            for cand in ttfile
                let expr = dpath == "" ? cand  : cand . "/" .dpath
                let expr = ".*" . expr
                let dflist = filter(copy(glist),  'v:val =~ expr' )
                if len(dflist) == 1
                    let dURL = a:pURL . dflist[0]
                    if svnj#svn#validURL(dURL) | retu [[dURL,] , 1] | en
                endif
            endfor
    endif
    return [glist, 0]
endf

fun! s:askUsrForFile(files, lfile)
    let s:selectedFile = ""
    if len(a:files) > 0
        let qdict = svnj#dict#new("Select for :" . a:lfile)
        let flistentries = []
        for tfile in a:files
            let flistentryd = {}
            let flistentryd.line = tfile
            call add(flistentries, flistentryd)
        endfor
        call svnj#dict#addEntries(qsvnd, s:flistkey, entries, s:flistops())
        call winj#populate(qsvnd)
        return s:selectedFile
    endif
endf

fun! s:warnlog(flist, tfile, fname)
    if g:svnj_warn_log && len(a:flist) > 100 
        echo "Using svn list command returned "
        echohl Error | echon len(a:flist)  | echohl None | echon " Files"
        echo "You can improve this by providing a in depth directory at "
        echohl Question | echon "g:svnj_branch_url"  | echohl None
        echon "  coma separated values and then select the directory from the " .
                   \ "branches listed."
        echo "Disable this message by setting at .vimrc"
        echohl Question | echon " let g:svnj_warn_log = 0 "  | echohl None
        echo "You can also disable finding files using"
        echohl Question | echon " let g:svnj_find_files = 0 "  | echohl None
        let x = input("Press Enter to continue") 
    en
endf

fun! svnj#log#flistSelected(key)
    let s:selectedFile = a:qsvnd.flistd.contents[a:key].line
endf

fun! s:addToTitle(msg, prefix)
    try | let s:ldict.title = a:prefix == 1 ?  a:msg. ' '. s:ldict.title : 
                \ s:ldict.title. ' ' . a:msg
    catch | endtry
endf
"2}}}
"1}}}
