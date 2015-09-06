" ============================================================================
" File:         autoload/svnj/act.vim
" Description:  Callbacks
" Author:       Juneed Ahamed
" =============================================================================

"{{{1

"callback funs {{{2
fun! svnj#act#blame(svnurl, filepath)
    setlocal nowrap nofoldenable
    call winj#close()

    " Execute svn blame
    let cmd="svn blame -v -x-w " . fnameescape(a:filepath)
    let cmd="%!" . svnj#svn#fmt_auth_info(cmd)
    keepalt vnew | exec cmd

    " Strip source code from blame output
    %s/^\(\s*\S\+\s\+\S\+\) \(\S\+ \S\+\).*/\2 \1/
    nohlsearch

    " Fit blame output width
    let width=strlen(getline('.'))
    exec "setlocal winfixwidth winwidth=" . width
    exec "vertical resize " . width

    " Setup blame window
    setlocal filetype=svnjblame
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
    setlocal nowrap nofoldenable nonumber nomodified readonly
    setlocal scrollbind
    wincmd p " return to previous window
    setlocal scrollbind
    syncbind
    return svnj#passed()
endf

"fun! svnj#act#diff(revision, svnurl, force)
fun! svnj#act#diff(...)
    let arevision = a:1
    let asvnurl = a:2
    let aforce = len(a:000) > 2 ? a:3 : "noforce"

    call s:startOp()
    let filetype=&ft
    let revision = len(arevision) > 0 ? " -" . arevision : ""
    if arevision == "" && filereadable(svnj#utils#expand(fnameescape(asvnurl)))
        let cmd = "%!cat " . fnameescape(asvnurl)
        let fname =  svnj#utils#strip(asvnurl)
    else
        let cmd = "svn cat " . revision . ' '. fnameescape(asvnurl)
        let cmd = "%!". svnj#svn#fmt_auth_info(cmd)
        let fname =  svnj#utils#strip(arevision)."_".svnj#utils#strip(asvnurl)
    endif

    diffthis | exec 'vnew! ' fnameescape(fname)
    exec cmd |  diffthis

    exe 'silent! com! GoSVNJ call svnj#home()'
    exe 'map <buffer> <silent> <c-q>' '<esc>:diffoff!<cr>:bd!<cr>:GoSVNJ<cr>'
    let ops = "C-q:Quit"

    exe 'map <buffer> <silent> <c-n>' printf("<esc>:diffoff!<cr>:bd!<cr>:bn<cr>:SVNDiff%s <cr>:call winj#close()<cr>", aforce ==? "force" ? "!" : "")
    exe 'map <buffer> <silent> <c-p>' printf("<esc>:diffoff!<cr>:bd!<cr>:bp<cr>:SVNDiff%s <cr>:call winj#close()<cr>", aforce ==? "force" ? "!" : "")

    let ops = ops . " C-n:nBuf C-p:pBuf"
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype

    let [newrev, olderrev] = svnj#svn#oldandnewrevisions(arevision, asvnurl)
    if olderrev != ""
        exe 'com! -buffer SVNDiffOld' printf("call winj#close()|diffoff!|bd!|call svnj#act#diff('%s','%s','%s')", olderrev, asvnurl, aforce)
        exe 'map <buffer> <silent> <c-down> <esc> :SVNDiffOld<cr>'
        let ops = ops . " C-down:" . olderrev
    endif
    if newrev != ""
        exe 'command! -buffer SVNDiffNew' printf("call winj#close()|diffoff!|bd!|call svnj#act#diff('%s','%s','%s')", newrev, asvnurl, aforce)
        exe 'map <buffer> <silent> <c-up> <esc> :SVNDiffNew<cr>'
        let ops = ops . " C-up:". newrev
    endif

    if arevision != ""
        exe 'map <buffer> <silent> <c-i>' printf("<esc>:call svnj#gopshdlr#displayinfo('%s', '%s')<cr>", arevision, asvnurl)
        let ops = ops . " C-i:Info"
    endif

    let &l:stl = svnj#utils#stl(fname, ops)
    let result = s:endOp(0)
    let &l:stl = svnj#utils#stl(fname, ops)
    return result
endf

fun! svnj#act#efile(revision, url)
    call s:startOp()
    try
        let [revision, fname] = s:rev_fname(a:revision, a:url)
        if filereadable(svnj#utils#expand(fname))
            silent! exe 'e ' fnameescape(fname)
        else
            let cmd="svn cat " . revision . ' ' . fnameescape(a:url)
            let cmd="%!" . svnj#svn#fmt_auth_info(cmd)
            silent! exe 'e ' fnameescape(fname) | exe cmd
            exe "setl bt=nofile"
        endif
    catch | endtry
    retu s:endOp(1)
endf

fun! svnj#act#vs(revision, url)
    call s:startOp()
    let [revision, fname] = s:rev_fname(a:revision, a:url)
    if filereadable(svnj#utils#expand(fname))
        silent! exe 'vsplit ' fnameescape(fname)
    else
        let cmd="svn cat " . revision . ' ' . fnameescape(a:url)
        let cmd="%!" . svnj#svn#fmt_auth_info(cmd)
        silent! exe 'vsplit ' fnameescape(fname) | exe cmd
        exe "setl bt=nofile"
    endif
    retu s:endOp(1)
endf

fun! svnj#act#forceredr(...)
    redraw!
    call svnj#prompt#show()
endf

fun! svnj#act#help(...)
    echohl Title
    echo " ******* SVNJ Operations ******** "
    echohl Function
    for [key, thedict] in items(winj#dict().getAllOps())
        let [key, val] = split(thedict.dscr, ":")
        echo '         ' . key . ' ' . val
    endfor
    echohl Title
    echo " ******************************* "
    echohl Function
    let x = input("Press Enter to continue ")
    echohl None
    call svnj#prompt#show()
endf

"helpers funs {{{2
fun! s:rev_fname(revision, url)
    let revision = a:revision == "" ? "" : " -" .  a:revision
    let fname = a:revision == "" ? a:url : a:revision . '_' .
                \ svnj#utils#strip(a:url)
    retu [revision, fname]
endf

fun! s:startOp()
    if svnj#prompt#isploop()
        call winj#close()
        retu svnj#passed()
    endif
    call svnj#altwinnr()
    retu svnj#passed()
endf

fun! s:endOp(keep)
    let [athome, jwinnr] = svnj#home()
    if athome && !svnj#prompt#isploop()
        call svnj#select#clear()
        call svnj#syntax#highlight()
        call winj#stl()
        setl nomodifiable | redr!
    elseif athome && svnj#prompt#isploop()
        call winj#close()
    endif
    retu svnj#passed()
endf
"2}}}
"1}}}
