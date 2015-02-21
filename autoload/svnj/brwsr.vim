"===============================================================================
" File:         autoload/svnj/brwsr.vim
" Description:  SVN Browser
" Author:       Juneed Ahamed
"===============================================================================

"svnj#brwsr.vim {{{1

"vars {{{2
call svnj#caop#fetchbmarks()
let [s:selkey, s:selectdscr] = svnj#utils#selkey()
let [s:topkey, s:topdscr] = svnj#utils#topkey()
let [s:reckey, s:recdscr] = svnj#utils#CtrlEntReplace('Rec')
"2}}}

"Key mappings for browseops {{{3
fun! s:browseops()
   retu { 
       \ "\<Enter>": {"bop":"<enter>", "dscr":'Ent:Opn', "fn":'svnj#brwsr#digin', "args":[0, 0]},
       \ s:reckey  : {"bop":"<c-enter>", "dscr":s:recdscr, "fn":'svnj#brwsr#digin', "args":[1]},
       \ "\<C-u>"  : {"bop":"<c-u>", "dscr":'C-u:Up', "fn":'svnj#brwsr#digout'},
       \ "\<C-h>"  : {"bop":"<c-h>", "dscr":'C-h:Home', "fn":'svnj#brwsr#root'},
       \ "\<C-o>"  : {"bop":"<c-o>", "dscr":'C-o:OpnAll', "fn":'svnj#gopshdlr#openFltrdFiles', "args":['svnj#act#efile']},
       \ "\<C-v>"  : {"bop":"<c-v>", "dscr":'C-v:VS', "fn":'svnj#gopshdlr#openFile', "args":['svnj#act#vs']},
       \ "\<C-d>"  : {"bop":"<c-d>", "dscr":'C-d:Diff', "fn":'svnj#gopshdlr#openFile', "args":['svnj#act#diff']},
       \ "\<C-l>"  : {"bop":"<c-l>", "dscr":'C-l:Log', "fn":'svnj#brwsr#fileLogs'},
       \ "\<C-b>"  : {"bop":"<c-b>", "dscr":'C-b:Book', "fn":'svnj#gopshdlr#book'},
       \ s:topkey  : {"bop":"<c-t>", "dscr":s:topdscr, "fn":'svnj#stack#top'},
       \ "\<C-i>"  : {"bop":"<c-i>", "dscr":'C-i:Info', "fn":'svnj#gopshdlr#info'},
       \ "\<C-a>"  : {"bop":"<c-a>", "dscr":'C-a:Afls', "fn":'svnj#brwsr#affectedfiles'},
       \ "\<C-r>"  : {"bop":"<c-r>", "dscr":'C-r:Redo', "fn":'svnj#brwsr#refresh'},
       \ "\<C-k>"  : {"bop":"<c-k>", "dscr":'C-k:CheckOut', "fn":'svnj#brwsr#checkout'},
       \ "\<C-z>"  : {"bop":"<c-z>", "dscr":'C-z:Commit', "fn":'svnj#gopshdlr#commit'},
       \ "\<C-g>"  : {"bop":"<c-g>", "dscr":'C-g:Add', "fn":'svnj#gopshdlr#add'},
       \ "\<C-p>"  : {"bop":"<c-p>", "dscr":'C-p:Paste', "fn":'svnj#brwsr#paste'},
       \ s:selkey  : {"bop":"<c-space>", "dscr":s:selectdscr, "fn":'svnj#gopshdlr#select'},
       \ "\<C-s>"  : {"dscr":'C-s:stick!', "fn":'svnj#prompt#setNoLoop'},
       \ "\<C-e>"  : {"bop":"<c-e>", "dscr":'C-e:SelectAll', "fn":'svnj#gopshdlr#selectall'},
       \ "\<F5>"   : {"dscr":'F5:redr', "fn":'svnj#act#forceredr'},
       \ }
endf
"2}}}
"3}}}

"Browser {{{2
fun! svnj#brwsr#SVNBrowse()
    try
        call svnj#init()
        call svnj#brwsr#Menu('winj#populateJWindow')
    catch 
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErrUp(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        call svnj#utils#dbgMsg('At svnj#Browse', v:exception)
        call bdict.clear()
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#SVNBrowseRepo(...)
    try
        call svnj#init()
        if a:0 > 0 && a:1 == "/" 
            let url = svnj#svn#repoRoot()
        else
            let url = svnj#svn#url(a:0 > 0 ? a:1 : getcwd())
        endif
        call svnj#brwsr#svnBrowse(url, "", 0, 0, 'winj#populateJWindow')
    catch
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErr(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#SVNBrowseWC(...)
    try
        call svnj#init()
        let recursive = a:1
        let url = (a:0 > 1  && svnj#utils#isdir(a:2)) ? (a:2) : getcwd()
        call svnj#brwsr#svnBrowse(url, "", 0, recursive, 'winj#populateJWindow')
    catch
        call svnj#utils#dbgMsg("At svnj#brwsr#SVNBrowseWC", v:exception)
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErr(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#Menu(populatecb)
    let bdict = svnj#dict#new("SVNJ Browser Menu")
    call bdict.setMeta(svnj#svn#blankMeta())

    call svnj#dict#addEntries(bdict, 'menud',
                \  [svnj#dict#menuItem('Repository', 'svnj#brwsr#browseRepoMenuCb', "")], {})
    call svnj#dict#addEntries(bdict, 'menud',
                \ [svnj#dict#menuItem('Working Copy/Current Dir', 'svnj#brwsr#browseWCMenuCb', "")], {})
    call svnj#dict#addEntries(bdict, 'menud',
                \ [svnj#dict#menuItem('MyList', 'svnj#brwsr#browseMyListMenuCb', "")], {})
    call svnj#dict#addEntries(bdict, 'menud',
                \ [svnj#dict#menuItem('BookMarks', 'svnj#brwsr#browseBMarksMenuCb', "")], {})
    call svnj#dict#addEntries(bdict, 'menud',
                \ [svnj#dict#menuItem('Buffer', 'svnj#brwsr#browseBufferMenuCb', "")], {})
    
    let menuops = { 
                \ "\<Enter>": {"bop":"<enter>", "dscr":'Enter:Open', "fn":'svnj#brwsr#browseMenuHandler'},
                \ s:reckey  : {"bop":"<c-enter>", "dscr":s:recdscr, "fn":'svnj#brwsr#browseMenuHandler', "args":["recursive"]},
                \ "\<C-u>"  : {"bop":"<c-u>", "dscr":'C-u:up', "fn":'svnj#stack#pop'},
                \ s:topkey  : {"bop":"<c-t>", "dscr":s:topdscr, "fn":'svnj#stack#top'},
                \ }

    call svnj#dict#addOps(bdict, 'menud', menuops)
    call svnj#stack#push('svnj#brwsr#Menu', ['winj#populate'])
    call call(a:populatecb, [bdict])
endf

fun! svnj#brwsr#browseMenuHandler(argdict)
    let [adict, akey] = [a:argdict.dict, a:argdict.key]
    retu call(adict.menud.contents[akey].callback, [a:argdict])
endf

fun! svnj#brwsr#browseRepoMenuCb(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        call adict.setMeta(svnj#svn#getMeta(getcwd()))
        let url = adict.meta.url
        let recursive = len(a:argdict.opt) > 0 && a:argdict.opt[0] ==# 'recursive' ? 1 : 0
        let args = s:browsItArgs(url, "", 0, recursive, 'winj#populate')
        retu svnj#brwsr#browseIt(args)
    catch
        call svnj#utils#dbgMsg("At svnj#brwsr#browseRepoMenuCb", v:exception)
        call svnj#utils#showerr("Failed the current dir/file " .
                    \ "May not be a valid svn entity")
    endtry
endf

fun! svnj#brwsr#browseWCMenuCb(argdict)
    try
        let [adict, akey] = [a:argdict.dict, a:argdict.key]
        call adict.setMeta(svnj#svn#getMetaFS(getcwd()))
        let url = adict.meta.fpath
        if url == "" | let url = getcwd() | en
        let recursive = len(a:argdict.opt) > 0 && a:argdict.opt[0] ==# 'recursive' ? 1 : 0
        let args = s:browsItArgs(url, "", 0, recursive, 'winj#populate')
        retu svnj#brwsr#browseIt(args)
    catch
        retu svnj#utils#showerr("Failed the current dir/file " .
                    \ "May not be a valid svn entity")
    endtry
endf

fun! svnj#brwsr#svnBrowse(url, purl, ignore_dirs, recursive, populatecb)
    let args = s:browsItArgs(a:url, a:purl, a:ignore_dirs, a:recursive, a:populatecb)
    call svnj#stack#push('svnj#brwsr#svnBrowse', 
                \ [a:url, a:purl, a:ignore_dirs, a:recursive, 'winj#populate'])

    call svnj#brwsr#browseIt(args)
endf

fun! s:browsItArgs(url, purl, ignore_dirs, recursive, populatecb)
    retu {
                \ 'url' : a:url,
                \ 'purl' : a:purl,
                \ 'igndirs' : a:ignore_dirs,
                \ 'recursive' : a:recursive,
                \ 'populatecb' : a:populatecb,
                \ }
endf

fun! svnj#brwsr#browseIt(args)
    let result = 1
    let bdict = svnj#dict#new("Browser")
    try
        let url = a:args.url
        let bdict.meta = svnj#svn#getMetaURL(url)
        let bdict.title = bdict.meta.url
        let bdict.bparent = bdict.meta.url
        let bdict.brecursive = a:args.recursive
        let is_repo = !svnj#utils#localFS(url)
        let files_lister = is_repo ? 'svnj#svn#list' : 'svnj#utils#listFiles'
        let entries = call(files_lister, [url, a:args.recursive, a:args.igndirs])
        if empty(entries)
            if has_key(a:args, 'purl') && a:args.purl != ""
                let args = a:args
                let args.url = a:args.purl
                let args.purl = url
                let args.populatecb = 'winj#populate'
                call svnj#stack#push('svnj#brwsr#browseIt', [args])
                call svnj#dict#addErrUp(bdict, "No files listed for ", url)
            else
                call svnj#dict#addErrUp(bdict, "No files listed for ", url)
            endif
            let result = 0
        else
            call svnj#dict#addBrowseEntries(bdict, 'browsed', entries, s:browseops())
        endif
        unlet! entries
    catch
        call svnj#dict#addErrUp(bdict, 'Failed ', v:exception)
        call svnj#utils#dbgMsg("At svnj#brwsr#browseIt", v:exception)
        let result = 0
    endtry
    call call(a:args.populatecb, [bdict])
    retu result
endf
"2}}}

"callbacks from window {{{2
fun! svnj#brwsr#root(argdict)
    try
        let bparent = a:argdict.dict.bparent
        let brecursive = a:argdict.dict.brecursive
        let url = ""

        if svnj#utils#isdir(bparent) 
            let wcrp = svnj#svn#workingCopyRootPath()
            let url = (wcrp != bparent) ? wcrp : expand("$HOME")
        endif

        if url == "" && svnj#svn#issvndir(getcwd())
            let url = svnj#svn#repoRoot()
        endif

        if url == "" | let url = expand("$HOME") | en
        call svnj#brwsr#svnBrowse(url, "", 0, brecursive, 'winj#populate')
        retu svnj#passed()
    catch | call svnj#utils#dbgMsg("At svnj#brwsr#root", v:exception) | endt
    retu svnj#failed()
endf

fun! svnj#brwsr#digin(argdict)
    try
        let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
        let arec = a:argdict.opt[0]
        let newurl = svnj#utils#joinPath(adict.bparent, aline)
        if svnj#utils#isdir(newurl) || svnj#svn#issvndir(newurl)
            let args = {'url' : newurl, 'purl': adict.bparent, 'igndirs' : 0,
                        \ 'recursive' : arec, 'populatecb' : 'winj#populate'}
            retu svnj#brwsr#browseIt(args)
        else
            call svnj#select#add(akey, aline, newurl, "")
            "1 is passed from BrowseBuffer to close on open
            if a:argdict.opt[1]  
                call svnj#select#openFiles('svnj#act#efile', g:svnj_max_open_files)
                retu svnj#fltrclearandexit()
            else
                retu svnj#select#openFiles('svnj#act#efile', g:svnj_max_open_files)
            endif
        endif
    catch | call svnj#utils#dbgMsg("At svnj#brwsr#digin", v:exception) | endt
    retu svnj#failed()
endf

fun! svnj#brwsr#digout(argdict)
    try
        let [adict, akey, aline] = [a:argdict.dict, a:argdict.key, a:argdict.line]
        let newurl = svnj#utils#getparent(adict.bparent)
        let is_repo = !svnj#utils#localFS(newurl)
        if (is_repo && !svnj#svn#validURL(newurl)) || (!is_repo && newurl == "//")
            call svnj#dict#addErrUp(adict, "Looks, like reached tip of the SVN/FS", "")
            call winj#populate(adict) | retu 0
        endif
        let args = {'url' : newurl, 'purl': adict.bparent, 'igndirs' : 0,
                    \ 'recursive' : adict.brecursive, 'populatecb' : 'winj#populate'}
        let result = svnj#brwsr#browseIt(args)
        call s:findAndSetCursor(adict.bparent, newurl)
        retu result
    catch | call svnj#utils#dbgMsg("Exception at digout", v:exception)
    endtry
    retu svnj#failed()
endf

fun! s:findAndSetCursor(subdir, topdir)
    try
        let displayed_dir = substitute(a:subdir, a:topdir, "", "")
        let pattern = '\v\c:' . displayed_dir
        let matchedat = match(getline(1, "$"), pattern)
        if matchedat >= 0 | call cursor(matchedat + 1, 0) | en
    catch | call svnj#utils#dbgMsg("At findAndSetCursor", v:exception) | endt
endf

fun! svnj#brwsr#fileLogs(argdict)
    try
        let [adict, aline] = [a:argdict.dict, a:argdict.line]
        try
            let args = {'url' : adict.bparent, 'purl': '',
                        \  'igndirs' : 0, 'recursive' : 0,
                        \  'populatecb' : 'winj#populate'}
            call svnj#stack#push('svnj#brwsr#browseIt', [args])
        catch 
            call svnj#utils#dbgMsg("Exception at svnj#brwsr#fileLogs", v:exception)
        endt

        let pathurl = svnj#utils#joinPath(adict.bparent, aline)
        if svnj#svn#validURL(pathurl)
            call svnj#log#logs(pathurl, g:svnj_max_logs, 'winj#populate', 0)
        else 
            call svnj#utils#showerr("Failed, May not be a valid svn entity")
        endif
    catch | call svnj#utils#showerr("Failed, Exception") | endt
    retu svnj#passed()
endf

fun! svnj#brwsr#affectedfiles(argdict)
    let [adict, aline] = [a:argdict.dict, a:argdict.line]
    try
        let args = {'url' : adict.bparent, 'purl': '',
                    \  'igndirs' : 0, 'recursive' : 0,
                    \  'populatecb' : 'winj#populate'}
        call svnj#stack#push('svnj#brwsr#browseIt', [args])
    catch | call svnj#utils#dbgMsg("Exception at svnj#brwsr#affectedfiles", v:exception)
    endt

    try
        let url = svnj#utils#joinPath(adict.bparent, aline)
        let lcr = svnj#svn#lastChngdRev(url)
        if lcr == ""
            call svnj#utils#showerr("May Not be a valid svn entity")
            retu
        endif
        let title = lcr . '@' . url
        let [slist, adict.meta.cmd] = svnj#svn#affectedfiles(url, lcr)
        retu svnj#gopshdlr#displayAffectedFiles(adict, title, slist)
    catch
        call svnj#utils#dbgMsg("At svnj#brwsr#affectedfiles", v:exception)
    endtry
endf

fun! svnj#brwsr#refresh(argdict)
    try
        let [adict, aline] = [a:argdict.dict, a:argdict.line]
        let newurl = adict.bparent
        call svnj#caop#cls(newurl)
        let args = {'url' : newurl, 'purl': adict.bparent, 'igndirs' : 0,
                    \ 'recursive' : 1, 'populatecb' : 'winj#populate'}
        retu svnj#brwsr#browseIt(args)
    catch | call svnj#utils#dbgMsg("At svnj#brwsr#refresh", v:exception) | endt
endf

fun! svnj#brwsr#checkout(argdict)
    try
        let [adict, aline] = [a:argdict.dict, a:argdict.line]
        let newurl = svnj#utils#joinPath(adict.bparent, aline)
        if svnj#svn#issvndir(newurl) && !svnj#utils#isdir(newurl)
            let title = " SVN CHECKOUT : " . newurl
            let descr = "   Applicable Args are \n" .
                        \ "   . = " . getcwd() . ",\n" .
                        \ "   Enter = NoArgs,\n".
                        \ "   Esc = Abort  OR \n" .
                        \ "   type the directory name\n"
            let dest = svnj#utils#input(title, descr, "Args : "  )
            if dest != "\<Esc>" 
                try
                    let newurl = substitute(fnameescape(newurl), "/$", "", "g")
                    let cmd = "svn co --non-interactive " . newurl . " " . dest

                    echohl Title | echo "" | echon "Will execute : " 
                    echohl Search | echon cmd  | echohl None
                    echohl Question | echo "" | echon "y to continue, Any to cancel : " 
                    echohl None

                    if svnj#utils#getchar() ==? "y"
                        call svnj#utils#showConsoleMsg("Performing chekout, please wait ..", 0)
                        call svnj#utils#execShellCmd(cmd)
                        call svnj#utils#showConsoleMsg("Checked out", 1)
                    endif
                catch | call svnj#utils#showerr(v:exception) | endt
            endif
        else | call svnj#utils#showerr("Should be repository dir to checkout") | en
    catch | call svnj#utils#dbgMsg("At svnj#brwsr#checkout", v:exception) | endt
    retu svnj#passed()
endf

fun! s:selected(tourl)
    let entries = []
    for val in values(svnj#select#dict())
        call add(entries, val.path)
    endfor

    if len(entries) <= 0
        call svnj#utils#showerr("Nothing selected")
        return [svnj#failed(), []]
    endif

    if index(entries, a:tourl) >= 0
        call svnj#utils#showerr("Cannot copy to self")
        retu [svnj#failed(), []]
    endif

    return [svnj#passed(), entries]
endf

fun! s:normalizeTarget(tourl)
    if !svnj#svn#issvndir(a:tourl) 
        let tempurl = fnamemodify(a:tourl, ':p:h') 
        call svnj#utils#showConsoleMsg(a:tourl . " is not a versioned directory, copy to " .
                    \ tempurl . " ?", 0)
        echohl Question | echo "y : yes, Any key abort : " | echohl None
        retu svnj#utils#getchar() ==? 'y' ? [1, tempurl] : [0, a:tourl]
    endif
    retu [1, a:tourl]
endf

fun! svnj#brwsr#paste(argdict)
    try
        let [adict, aline] = [a:argdict.dict, a:argdict.line]
        let tourl = svnj#utils#joinPath(adict.bparent, aline)

        let[result, thelist] = s:selected(tourl)
        if result == svnj#failed() | retu svnj#failed() | en

        let [result, tourl] = s:normalizeTarget(tourl)
        if !result | retu svnj#failed() | en
        call add(thelist, tourl)

        let alllocals = filter(copy(thelist), 'svnj#utils#localFS(v:val) > 0')
        let is_local =  len(alllocals) == len(thelist) ? 1 : 0
        let is_repo = len(alllocals) == 0 ? 1 : 0

        if !is_local && !is_repo
            retu svnj#utils#showerr("Cannot paste from working copy to repo or vice-versa")
        endif

        if is_repo || is_local
            let [result, response] = call( is_repo ? 'svnj#cpy#repo' :
                        \ 'svnj#svn#copywc', [thelist])
            if result == svnj#passed()
                call svnj#select#clear()
                call svnj#select#resign(adict)
            endif
            return result
        endif
    catch 
        call svnj#utils#dbgMsg("At svnj#brwsr#paste", v:exception)
        retu svnj#failed()
    endt
    retu svnj#passed()
endf
"2}}}

"Browse BMarks {{{2
fun! svnj#brwsr#SVNBrowseMarked()
    call svnj#init()
    call svnj#brwsr#bmarked('winj#populateJWindow')
endf

fun! svnj#brwsr#browseBMarksMenuCb(...)
    retu svnj#brwsr#bmarked('winj#populate')
endf

fun! svnj#brwsr#bmarked(populateCb)
    try
        let bdict = svnj#dict#new("Bookmarks")
        let bdict.meta = svnj#svn#blankMeta()
        let entries = svnj#utils#formatBrowsedEntries(svnj#select#booked())
        call svnj#stack#push('svnj#brwsr#bmarked', ['winj#populate'])
        if empty(entries)
            call svnj#dict#addErrTop(bdict, "No Marked files", "")
        else
            call svnj#dict#addBrowseEntries(bdict, 'browsed', entries, s:browseops())
        endif
        unlet! entries
        call call(a:populateCb, [bdict])
        unlet! bdict
    catch | call svnj#utils#dbgMsg("At svnj#brwsr#bmarked", v:exception)
    endtry
    retu svnj#passed()
endf
"2}}}

"Browse MyList {{{2
fun! svnj#brwsr#SVNBrowseMyList()
    call svnj#init()
    call svnj#brwsr#brwsMyList('winj#populateJWindow')
endf

fun! svnj#brwsr#browseMyListMenuCb(...)
    call svnj#brwsr#brwsMyList('winj#populate')
endf

fun! svnj#brwsr#brwsMyList(populateCb)
    if len(g:p_browse_mylist) == 0 
        let edict = svnj#utils#errDict("BrowseMyList", 
                    \ "Please set g:svnj_browse_mylist " .
                    \ "at .vimrc see :help g:svnj_browse_mylist")
        call call(a:populateCb, [edict]) | unlet! edict | retu 1
    endif
    
    let bdict = svnj#dict#new("BrowseMyList")
    try
        let bdict.meta = svnj#svn#blankMeta()
        call svnj#stack#push('svnj#brwsr#brwsMyList', ['winj#populate'])
        if empty(g:p_browse_mylist)
            call svnj#dict#addErrUp(bdict, "No files", "")
        else
            let ops = s:browseops()
            call remove(ops, "\<C-u>")
            let entries = svnj#utils#formatBrowsedEntries(g:p_browse_mylist)
            call svnj#dict#addBrowseEntries(bdict, 'browsed', entries, ops)
        endif
        call call(a:populateCb, [bdict])
        unlet! bdict
    catch | call svnj#utils#dbgMsg("At svnj#brwsr#brwsMyList", v:exception) 
    endtry
    retu svnj#passed()
endf
"2}}}

"Browse Buffer {{{2
fun! svnj#brwsr#SVNBrowseBuffer()
    call svnj#init()
    let curbufname =  bufname("%")
    call svnj#brwsr#brwsBuffer('winj#populateJWindow', curbufname)
endf

fun! svnj#brwsr#browseBufferMenuCb(...)
    let curbufname =  bufname("%")
    call svnj#brwsr#brwsBuffer('winj#populate', curbufname)
endf

fun! svnj#brwsr#brwsBuffer(populateCb, curbufname)
    let bdict = svnj#dict#new("BrowseBuffer")
    try
        let bdict.meta = svnj#svn#blankMeta()
        call svnj#stack#push('svnj#brwsr#brwsBuffer', ['winj#populate', a:curbufname])
    
        let files = svnj#utils#buffiles(a:curbufname)
        if empty(files) 
            call svnj#dict#addErrUp(bdict, "No files", "")
        else
            let ops = s:browseops()

            call remove(ops, "\<C-u>")
            call remove(ops, "\<C-r>")
            call remove(ops, "\<Enter>")
            call remove(ops, "\<C-s>")

            call extend(ops, {"\<Enter>"  : {"bop":"<enter>", "dscr":'Ent:Opn', "fn":'svnj#brwsr#digin', "args":[0, 1]},})
            call extend(ops, {"\<C-r>"  : {"bop":"<c-r>", "dscr":'C-r:Refresh', "fn":'svnj#brwsr#browseBufferMenuCb', "args":[]},})
            call extend(ops, {"\<C-q>"  : {"bop":"<c-q>", "dscr":'C-q:Quit', "fn":'svnj#gopshdlr#closeBuffer', "args":[a:curbufname]},})

            let entries = svnj#utils#formatBrowsedEntries(files)
            call svnj#dict#addBrowseEntries(bdict, 'browsed', entries, ops)
        endif
        call call(a:populateCb, [bdict])
        call svnj#gopshdlr#removeSticky()
        unlet! bdict
    catch | call svnj#utils#dbgMsg("At svnj#brwsr#brwsMyList", v:exception) 
    endtry
    retu svnj#passed()
endf
"2}}}
"1}}}
