"===============================================================================
" File:         autoload/svnj/cpy.vim
" Description:  SVN Copy 
" Author:       Juneed Ahamed
"===============================================================================

"svnj#blank.vim {{{1
fun! svnj#cpy#ops(urllist) "ops {{{2
    retu { "<c-z>": {"fn": "svnj#cpy#doRepoCopy", "args": a:urllist, "dscr":"C-z:Commit"},
        \ "<c-q>": {"fn": "svnj#blank#closeMe", "args": [], "dscr":"C-q:Cancel"},
        \ }
endf

fun! svnj#cpy#opsdscr() 
    retu join(map(values(svnj#commit#ops([])), 'v:val.dscr'), " ")
endf
"2}}}

fun! svnj#cpy#repo(urllist) "callback from svnj#brwsr#paste {{{2
    try
        if len(a:urllist) < 2 | retu svnj#utils#showerr("Insufficient info") | en
        call svnj#blank#win(svnj#cpy#ops(a:urllist))
        let hlines = svnj#utils#copyHeader(a:urllist, svnj#cpy#opsdscr())
        let result = svnj#utils#writeToBuffer("svnj_bwindow", hlines)
        let &l:stl = svnj#utils#stl("SVNJ Copy Commit Log", svnj#cpy#opsdscr())
        retu [svnj#fltrclearandexit(), ""]
    catch 
        call svnj#utils#dbgMsg("At svnj#cpy#repo", v:exception)
        retu [svnj#failed(), ""]
    endtry
endf
"2}}}

fun! svnj#cpy#doRepoCopy(...) "callback from blank win {{{2 
    try
        let [commitlog, comments] = ["", []]
        let [srcurls, desturl] = [[], ""]
        let [source_reg, dest_reg] = ["SVNJ:SOURCE: ", "SVNJ:DESTINATION: "]

        for line in getline(1, line('$'))
            let line = svnj#utils#strip(line)
            if len(line) > 0 && matchstr(line, '^SVNJ:') == ""
                call add(comments , line) 
            elseif matchstr(line, source_reg) != ""
                let curl = svnj#utils#strip(substitute(line, source_reg, "", ""))
                if curl != "" && index(srcurls, curl) < 0
                    call add(srcurls, curl)
                else
                    call svnj#utils#showerr("Duplicate src ignoring " . curl)
                endif
            elseif matchstr(line, dest_reg) != "" 
                if desturl != ""
                    retu svnj#utils#showerr("Multiple destinations, Aborting")
                endif
                let curl = svnj#utils#strip(substitute(line, dest_reg, "", ""))
                if curl != "" 
                    let desturl = curl
                endif
            endif
        endfor

        if len(srcurls) <= 0
            retu svnj#utils#showerr("No src urls, Aborting")
        endif

        if len(desturl) <= 0
            retu svnj#utils#showerr("No dest urls, Aborting")
        endif

        call add(srcurls, desturl)
        retu s:doRepoCopy(comments, srcurls)
    catch
        call svnj#utils#showerr("Exception during doRepoCopy : " . v:exception)
    endtry
    retu
endf

fun! s:doRepoCopy(comments, urls)
    if len(a:comments) <= 0 
        echohl Question | echo "No comments"
        echo "Press c to commit without comments, q to abort, Any key to edit : "
        echohl None
        let choice = svnj#utils#getchar()
        if choice ==? 'c' | retu s:doSvnRepoCopy("!", a:urls) | en
        retu choice ==? 'q' ? svnj#blank#closeMe() : svnj#failed()
    else
        let commitlog = ""
        try
            let commitlog = svnj#caop#commitlog()
            if filereadable(commitlog) | call delete(commitlog) | en
            call writefile(a:comments, commitlog)
            retu s:doSvnRepoCopy(commitlog, a:urls)
        finally
            if len(commitlog) > 0 | call delete(commitlog) | en
        endtry
    endif
    retu svnj#failed()
endf

fun! s:doSvnRepoCopy(commitlog, urls)
    let [result, response] = svnj#svn#copyrepo(a:commitlog, a:urls)
     if len(response) > 0
        call svnj#utils#showConsoleMsg(response, 1) 
    else
        call svnj#utils#showConsoleMsg("No output from svn", 1) 
    endif
    call svnj#blank#closeMe()
    retu result
endf
"2}}}
"1}}}
