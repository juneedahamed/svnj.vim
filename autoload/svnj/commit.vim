"===============================================================================
" File:         autoload/svnj/commit.vim
" Description:  SVN Commit (svn ci)
" Author:       Juneed Ahamed
"===============================================================================

"svnj#commit.vim {{{1
"ops {{{2
fun! svnj#commit#ops(thefiles) 
    retu { "<c-z>": {"fn": "svnj#commit#commit", "args": a:thefiles, "dscr":"C-z:Commit"},
        \ "<c-q>": {"fn": "svnj#blank#closeMe", "args": [], "dscr":"C-q:Cancel"}, }
endf

fun! svnj#commit#opsdscr() 
    retu join(map(values(svnj#commit#ops([])), 'v:val.dscr'), " ")
endf
"2}}}

fun! svnj#commit#SVNCommit(bang, ...) "{{{2
    try
        call svnj#init()
        let thefiles = []
        if len(a:000) == 0 
            call add(thefiles, svnj#utils#bufFileAbsPath())
        else
            call extend(thefiles, a:000)
            call filter(thefiles, 'filereadable(v:val) || isdirectory(v:val)')
        endif
        retu a:bang == "!" ? s:commitNoComments(thefiles) : svnj#commit#prepCommit(thefiles)
    catch | retu svnj#utils#showerr(v:exception) | endt
endf
"2}}}

"callback handler
fun! svnj#commit#prepCommit(thefiles) "{{{2
    if len(a:thefiles) > 0
        call svnj#blank#win(svnj#commit#ops(a:thefiles))
        let hlines = svnj#utils#commitHeader(a:thefiles, svnj#commit#opsdscr())
        let result = svnj#utils#writeToBuffer("svnj_bwindow", hlines)
        let &l:stl = svnj#utils#stl("SVNJ Commit Log",  svnj#commit#opsdscr())
    endif
endf
"2}}}

fun! svnj#commit#commit(...) "{{{2
    let commitlog = ""
    try
        let [cfiles, comments] = svnj#commit#parseclog()
        if len(cfiles) <= 0 | retu svnj#utils#showerr("Will not commit no files") | en

        let result = len(comments) > 0 ? svnj#commit#docommit(cfiles, comments) : 
                    \ s:confirmNoComments(cfiles)

        if result != svnj#cancel() | call svnj#blank#closeMe() | en
    catch
        call svnj#utils#showerr(v:exception)
    finally
        if len(commitlog) > 0 | call delete(commitlog) | en
    endtry
    retu svnj#passed()
endf
"2}}}

"utils
fun! svnj#commit#parseclog() "{{{2
    let [cfiles, comments] = [[], []]

    for line in getline(1, line('$'))
        let line = svnj#utils#strip(line)
        if len(line) > 0 && matchstr(line, '^SVNJ:') == ""
            call add(comments , line) 
        elseif matchstr(line, '^SVNJ:+') != ""
            let line = svnj#utils#strip(substitute(line, '^SVNJ:+', "", ""))
            if index(cfiles, line) < 0 | call add(cfiles, line) | en
        endif
    endfor
    retu [cfiles, comments]
endf
"2}}}

fun! svnj#commit#docommit(cfiles, comments) "{{{2
    let commitlog = svnj#caop#commitlog()
    if filereadable(commitlog) | call delete(commitlog) | en
    call writefile(a:comments, commitlog)

    echohl Question | echo "Will commit following (" . len(a:cfiles) . ") files"
    echohl Directory | echo join(a:cfiles, "\n")
    echohl Question | echo "Y to Continue, Any key to cancel" | echohl None
    if svnj#utils#getchar() !=? 'y' | retu svnj#cancel() | en

    let result = svnj#svn#commit(commitlog, a:cfiles)
    if len(result) > 0
        call svnj#utils#showConsoleMsg(result, 1) 
    else
        call svnj#utils#showConsoleMsg("No output from svn", 1) 
    endif
    retu svnj#passed()
endf
"2}}}

fun! s:confirmNoComments(cfiles) "{{{2
    echohl Question | echo "No comments"
    echo "Press c to commit without comments, q to abort, Any key to edit : "
    echohl None
    let choice = svnj#utils#getchar()
    if choice ==? 'c' 
        retu s:commitNoComments(a:cfiles)
    endif
    retu choice !=? 'q' ? svnj#cancel() : svnj#failed()
endf
"2}}}

fun! s:commitNoComments(thefiles) "{{{2
    let result = svnj#svn#commit("!", a:thefiles)
    retu len(result) > 0 ? svnj#utils#showConsoleMsg(result, 1) :
                \ svnj#utils#showConsoleMsg("No output from svn", 1) 
endf
"2}}}
"1}}}
