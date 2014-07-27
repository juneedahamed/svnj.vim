"===============================================================================
" File:         autoload/svnj/svnadd.vim
" Description:  SVN Add (svn add) and then svn ci
" Author:       Juneed Ahamed
"===============================================================================

"svnj#svnadd.vim {{{1
"ops {{{2
fun! svnj#svnadd#ops(thefiles) 
    retu { "<c-g>": {"fn": "svnj#svnadd#add", "args": a:thefiles, "dscr":"C-g:Add"},
        \ "<c-z>": {"fn": "svnj#svnadd#commit", "args": a:thefiles, "dscr":"C-z:AddAndCommit"},
        \ "<c-q>": {"fn": "svnj#blank#closeMe", "args": [], "dscr":"C-q:Cancel"}, }
endf

fun! svnj#svnadd#opsdscr() 
    retu join(map(values(svnj#svnadd#ops([])), 'v:val.dscr'), " ")
endf
"2}}}

fun! svnj#svnadd#Add(...) "{{{2
    try
        call svnj#init()
        let thefiles = []
        if len(a:000) == 0 
            call add(thefiles, svnj#utils#bufFileAbsPath())
        else
            call extend(thefiles, a:000)
            call filter(thefiles, 'filereadable(v:val) || isdirectory(v:val)')
        endif
        retu svnj#svnadd#prepAdd(thefiles)
    catch | retu svnj#utils#showerr(v:exception) | endt
endf
"2}}}

fun! svnj#svnadd#prepAdd(thefiles) "{{{2
    if len(a:thefiles) > 0 
        call svnj#blank#win(svnj#svnadd#ops(a:thefiles))
        let hlines = svnj#utils#addHeader(a:thefiles, svnj#svnadd#opsdscr())
        let result = svnj#utils#writeToBuffer("svnj_bwindow", hlines)
        let &l:stl = svnj#utils#stl("SVNJ Add ",  svnj#svnadd#opsdscr())
    endif
endf
"2}}}

fun! svnj#svnadd#commit(...) "{{{2
    try
        let [afiles, comments] = svnj#commit#parseclog()
        if len(afiles) <= 0 | retu svnj#utils#showerr("No files") | en

        if len(comments) <= 0
            retu svnj#utils#showerr("Please provide comments for commit")
        endif

        if svnj#svnadd#doAdd(afiles) == svnj#passed()
            call svnj#commit#docommit(afiles, comments)
            retu svnj#blank#closeMe()
        endif
    catch
        call svnj#utils#showerr(v:exception)
    endtry
    retu svnj#passed()
endf
"2}}}

fun! svnj#svnadd#add(...) "{{{2
    try
        let [afiles, comments] = svnj#commit#parseclog()
        if svnj#svnadd#doAdd(afiles) == svnj#passed()
            call svnj#blank#closeMe()
        endif
    catch
        call svnj#utils#showerr(v:exception)
    endtry
    retu svnj#passed()
endf
"2}}}

fun! svnj#svnadd#doAdd(thefiles) "{{{2
    if len(a:thefiles) <=0 
        retu svnj#utils#showerr("Failed, No files")
    endif
    try
        let result = svnj#svn#add(a:thefiles)
        call svnj#utils#showConsoleMsg(result, 1)
    catch
        call svnj#utils#showerr("While SVNAdd " . v:exception)
        retu svnj#failed()
    endtry
    if result == "Aborted" | retu svnj#failed() | en
    retu svnj#passed()
endf
"2}}}
"1}}}
