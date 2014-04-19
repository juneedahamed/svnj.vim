"===============================================================================
" File:         autoload/svnj/brwsr.vim
" Description:  SVN Browser
" Author:       Juneed Ahamed
"===============================================================================

"svnj#brwsr.vim {{{1

"vars {{{2
if !exists('g:svnj_glb_init') | let g:svnj_glb_init = svnjglobals#init() | en
let s:bdict = svnj#dict#new("Browser")
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
let s:is_repo = 1
"2}}}

"Key mappings for browseops {{{3
fun! s:browseops()
   return { 
               \ "\<Enter>"  : ['Ent:Open', 'svnj#brwsr#digin', 0],
               \ "\<C-Enter>": ['C-Ent:Rec', 'svnj#brwsr#digin', 1],
               \ "\<C-u>"    : ['C-u:Up', 'svnj#brwsr#digout'],
               \ "\<C-o>"    : ['C-o:OpenAll', 'svnj#gopshdlr#openFltrdFiles', 'winj#newBufOpen'],
               \ "\<C-d>"    : ['C-d:Diff', 'svnj#gopshdlr#openFile', 'winj#diffFile'],
               \ "\<C-l>"    : ['C-l:Log', 'svnj#brwsr#fileLogs'],
               \ "\<C-b>"    : ['C-b:book', 'svnj#gopshdlr#book'],
               \ "\<C-t>"    : ['C-t:top', 'svnj#stack#top'],
               \ "\<C-i>"    : ['C-i:info', 'svnj#gopshdlr#info'],
               \ s:selectkey : [s:selectdscr, 'svnj#gopshdlr#select'],
               \ }
endf
"3}}}

"Browser {{{2
fun! svnj#brwsr#SVNBrowse()
    try
        call svnj#init()
        call svnj#brwsr#Menu('winj#populateJWindow')
        call s:bdict.clear()
        unlet! s:bdict
    catch 
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErrUp(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        call svnj#utils#dbgHld('At svnj#Browse', v:exception)
        call bdict.clear()
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#SVNBrowseRepo(...)
    try
        call svnj#init()
        let url = svnj#svn#url(a:0 > 0 ? a:1 : getcwd())
        let s:is_repo = 1
        call svnj#brwsr#svnBrowse(url, "", 0, 0, 'winj#populateJWindow')
        call s:bdict.clear()
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
        let url = (a:0 > 1  && isdirectory(a:2)) ? (a:2) : getcwd()
        let s:is_repo = 0
        call svnj#brwsr#svnBrowse(url, "", 0, recursive, 'winj#populateJWindow')
        call s:bdict.clear()
    catch
        let bdict = svnj#dict#new("Browser")
        call svnj#dict#addErr(bdict, 'Failed ', v:exception)
        call winj#populateJWindow(bdict)
        unlet! bdict
    endtry
endf

fun! svnj#brwsr#Menu(populatecb)
    unlet! s:bdict
    let s:bdict = svnj#dict#new("SVNJ Browser Menu")
    call s:bdict.setMeta(svnj#svn#blankMeta())

    call svnj#dict#addEntries(s:bdict, 'menud',
                \  [svnj#dict#menuItem('Repository', 'svnj#brwsr#browseRepoMenuCb', "")], {})
    call svnj#dict#addEntries(s:bdict, 'menud',
                \ [svnj#dict#menuItem('Working Copy/Current Dir', 'svnj#brwsr#browseWCMenuCb', "")], {})
    call svnj#dict#addEntries(s:bdict, 'menud',
                \ [svnj#dict#menuItem('MyList', 'svnj#brwsr#browseMyListMenuCb', "")], {})
    call svnj#dict#addEntries(s:bdict, 'menud',
                \ [svnj#dict#menuItem('BookMarks', 'svnj#brwsr#browseBMarksMenuCb', "")], {})
    
    let menuops = { 
                \ "\<Enter>": ['Enter:Open', 'svnj#brwsr#browseMenuHandler'],
                \ "\<C-Enter>" : ["C-Enter:Rec", 'svnj#brwsr#browseMenuHandler', "recursive"],
                \ "\<C-u>": ['C-u:up', 'svnj#stack#pop'],
                \ "\<C-t>": ['C-t:top', 'svnj#stack#top']
                \ }

    call svnj#dict#addOps(s:bdict, 'menud', menuops)
    call svnj#stack#push('svnj#brwsr#Menu', ['winj#populate'])

    call call(a:populatecb, [s:bdict])
endf

fun! svnj#brwsr#browseMenuHandler(dict, key, ...)
    let cbargs = [a:dict, a:key]
    call extend(cbargs, a:000)
    return call(a:dict.menud.contents[a:key].callback, cbargs)
endf

fun! svnj#brwsr#browseRepoMenuCb(dict, key, ...)
    try
        let s:is_repo = 1
        call a:dict.setMeta(svnj#svn#getMeta(getcwd()))
        let url = a:dict.meta.url
        let recursive = a:0 >= 1 && a:1 ==# 'recursive' ? 1 : 0
        let args = s:browsItArgs(url, "", 0, recursive, 'winj#populate')
        return svnj#brwsr#browseIt(args)
    catch
        call svnj#utils#showErrorConsole("Failed the current dir/file " .
                    \ "May not be a valid svn entity")
    endtry
endf

fun! svnj#brwsr#browseWCMenuCb(dict, key, ...)
    try
        let s:is_repo = 0
        call a:dict.setMeta(svnj#svn#getMetaFS(getcwd()))
        let url = a:dict.meta.fpath
        if url == "" | let url = getcwd() | en
        let recursive = a:0 >= 1 && a:1 ==# 'recursive' ? 1 : 0
        let args = s:browsItArgs(url, "", 0, recursive, 'winj#populate')
        return svnj#brwsr#browseIt(args)
    catch
        return svnj#utils#showErrorConsole("Failed the current dir/file " .
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
    try
        let url = a:args.url
        let s:bdict = svnj#dict#new("Browser")
        let s:bdict.meta = svnj#svn#getMetaURL(url)
        let s:bdict.title = s:bdict.meta.url
        let files_lister = s:is_repo ? 'svnj#svn#list' : 'svnj#utils#listFiles'
        let entries = call(files_lister, [url, a:args.recursive, a:args.igndirs])
        if empty(entries)
            if has_key(a:args, 'purl') && a:args.purl != ""
                let args = a:args
                let args.url = a:args.purl
                let args.purl = url
                let args.populatecb = 'winj#populate'
                call svnj#stack#push('svnj#brwsr#browseIt', [args])
                call svnj#dict#addErrUp(s:bdict, "No files listed for ", url)
            else
                call svnj#dict#addErrUp(s:bdict, "No files listed for ", url)
            endif
            let result = 0
        else
            call svnj#dict#addEntries(s:bdict, 'browsed', entries, s:browseops())
        endif
        unlet! entries
    catch
        call svnj#dict#addErrUp(s:bdict, 'Failed ', v:exception)
        call svnj#utils#dbgHld("At svnj#brwsr#browseIt", v:exception)
        let result = 0
    endtry
    call call(a:args.populatecb, [s:bdict])
    return result
endf
"2}}}

"callbacks from window {{{2
fun! svnj#brwsr#digin(adict, key, rec)
    try
        let newurl = svnj#utils#joinPath(s:bdict.meta.url,
                    \ s:bdict.browsed.contents[a:key].line)
        if (s:is_repo && isdirectory(newurl)) || svnj#utils#isSvnDirReg(newurl)
            let args = {'url' : newurl, 'purl': s:bdict.meta.url, 'igndirs' : 0,
                        \ 'recursive' : a:rec, 'populatecb' : 'winj#populate'}
            return svnj#brwsr#browseIt(args)
        else
            call svnj#select#add(a:key, s:bdict.browsed.contents[a:key].line, newurl, "")
            call svnj#select#openFiles('winj#newBufOpen', g:svnj_max_open_files)
            return 1
        endif
    catch | call svnj#utils#dbgHld("At s:digin", v:exception) | endt
    return 0
endf

fun! svnj#brwsr#digout(adict, key)
    try
        let newurl = svnj#utils#getparent(s:bdict.meta.url)
        if (s:is_repo && !svnj#svn#validURL(newurl)) || (!s:is_repo && newurl == "//")
            call svnj#dict#addErrUp(s:bdict, "Looks, like reached tip of the SVN/FS", "")
            call winj#populate(s:bdict) | retu 0
        endif
        let args = {'url' : newurl, 'purl': s:bdict.meta.url, 'igndirs' : 0,
                    \ 'recursive' : 0, 'populatecb' : 'winj#populate'}
        return svnj#brwsr#browseIt(args)
    catch | call svnj#utils#dbgHld("Exception at digout", v:exception)
    endtry
    return 0
endf

fun! svnj#brwsr#fileLogs(dict, key)
    try
        try
            let args = {'url' : s:bdict.meta.url, 'purl': '',
                        \  'igndirs' : 0, 'recursive' : 1,
                        \  'populatecb' : 'winj#populate'}
            call svnj#stack#push('svnj#brwsr#browseIt', [args])
        catch | call svnj#utils#dbgHld("Exception at svnj#brwsr#fileLogs", v:exception)
        endt

        let pathurl = svnj#utils#joinPath(s:bdict.meta.url,
                    \ s:bdict.browsed.contents[a:key].line)
        if svnj#svn#validURL(pathurl)
            call s:bdict.discardEntries()
            call svnj#log#logs(pathurl, 'winj#populate', 0)
        else 
            call svnj#utils#showErrorConsole("Failed, May not be a valid svn entity")
        endif
    catch | call svnj#utils#showErrorConsole("Failed, Exception") | endt
    return 1
endf
"2}}}

"Browse BMarks {{{2
fun! svnj#brwsr#SVNBrowseMarked()
    call svnj#init()
    call svnj#brwsr#bmarked('winj#populateJWindow')
    call s:bdict.clear()
endf

fun! svnj#brwsr#browseBMarksMenuCb(...)
    return svnj#brwsr#bmarked('winj#populate')
endf

fun! svnj#brwsr#bmarked(populateCb)
    try
        let s:bdict = svnj#dict#new("Browser")
        let s:bdict.meta = svnj#svn#blankMeta()
        let entries = svnj#select#booked()
        call svnj#stack#push('svnj#brwsr#bmarked', ['winj#populate'])
        if empty(entries)
            call svnj#dict#addErrTop(s:bdict, "No Marked files", "")
        else
            call svnj#dict#addEntries(s:bdict, 'browsed', entries, s:browseops())
        endif
        unlet! entries
        call call(a:populateCb, [s:bdict])
    catch | call svnj#utils#dbgHld("At svnj#brwsr#bmarked", v:exception)
    endtry
    return 1
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
    
    let s:bdict = svnj#dict#new("BrowseMyList")
    try
        let s:bdict.meta = svnj#svn#blankMeta()
        let entries = s:listMyList()
        call svnj#stack#push('svnj#brwsr#brwsMyList', ['winj#populate'])
        if empty(entries)
            call svnj#dict#addErrUp( s:bdict, "No files", "")
        else
            let ops = s:browseops()
            call remove(ops, "\<C-u>")
            call svnj#dict#addEntries(s:bdict, 'browsed', entries, ops)
        endif
        unlet! entries
        call call(a:populateCb, [s:bdict])
    catch | call svnj#utils#dbgHld("At svnj#brwsr#brwsMyList", v:exception) 
    endtry
    return 1
endf

fun! s:listMyList()
    let entries = []
    for url in g:p_browse_mylist
        let listentryd = {}
        let listentryd.line = url
        call add(entries, listentryd)
    endfor
    return entries
endf
"2}}}
"1}}}
