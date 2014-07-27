" ============================================================================
" File:         autoload/svnj/act.vim
" Description:  Callbacks
" Author:       Juneed Ahamed
" =============================================================================

"{{{1

"callback funs {{{2
fun! svnj#act#blame(svnurl, filepath)
    setlocal scrollbind nowrap nofoldenable 
    call winj#close()
    let filetype=&ft
    let cmd="%!svn blame " . fnameescape(a:filepath)
    let newfile = 'keepalt vnew '
    exec newfile | exec cmd
    exe "setl bt=nofile bh=wipe nobl noswf nowrap ro ft=" . filetype
    setlocal scrollbind nowrap nofoldenable
    retu svnj#passed()
endf

fun! svnj#act#diff(revision, svnurl)
    call s:startOp()
    let filetype=&ft
    let revision = len(a:revision) > 0 ? " -" . a:revision : ""
    if a:revision == "" && filereadable(svnj#utils#expand(fnameescape(a:svnurl)))
        let cmd = "%!cat " . fnameescape(a:svnurl)
        let fname =  svnj#utils#strip(a:svnurl)
    else
        let cmd = "%!svn cat " . revision . ' '. fnameescape(a:svnurl)
        let fname =  svnj#utils#strip(a:revision)."_".svnj#utils#strip(a:svnurl)
    endif
    diffthis | exec 'vnew! ' fnameescape(fname) 
    exec cmd |  diffthis
    exe 'silent! com! GoSVNJ call svnj#home()'
    exe 'map <buffer> <silent> <c-q>' '<esc>:diffoff!<cr>:bd!<cr>:GoSVNJ<cr>'
    exe 'map <buffer> <silent> <c-n>' '<esc>:diffoff!<cr>:bd!<cr>:bn<cr>:SVNDiff<cr>:call winj#close()<cr>'
    exe 'map <buffer> <silent> <c-p>' '<esc>:diffoff!<cr>:bd!<cr>:bp<cr>:SVNDiff<cr>:call winj#close()<cr>'
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype
    let &l:stl = svnj#utils#stl(fname, "C-q:Quit C-n:NextBuffer C-p:PrevBuffer")
    retu s:endOp(0)
endf

fun! svnj#act#efile(revision, url)
    call s:startOp()
    try
        let [revision, fname] = s:rev_fname(a:revision, a:url)
        if filereadable(svnj#utils#expand(fname))
            silent! exe 'e ' fnameescape(fname)
        else
            let cmd="%!svn cat " . revision . ' ' . fnameescape(a:url)
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
        let cmd="%!svn cat " . revision . ' ' . fnameescape(a:url)
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
    let x = input("Press key to continue ")
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
        if exists('g:svnj_a_winnr')
            try
                silent! exe  g:svnj_a_winnr . 'wincmd w'
            catch | endtry
        endif
        retu svnj#passed()
    endif
    let [athome, jwinnr] = svnj#home()
    if !athome | retu 0 | en
    let curwin = winnr()
    if curwin == jwinnr
        let altwin = winnr('#')
        silent! exe  altwin . 'wincmd w'
    endif
    retu svnj#passed()
endf

fun! s:endOp(keep)
    let [athome, jwinnr] = svnj#home()
    if athome && !svnj#prompt#isploop()
        call svnj#select#clear()
        call svnj#syntax#highlight()
        call winj#stl()
        setl nomodifiable | redr!
        try
            if !a:keep
                let altwin = winnr('#')
                silent! exe  altwin . 'wincmd w'
            endif
        catch | call svnj#utils#dbgMsg("s:endOp " . v:exception) | endt
    elseif athome && svnj#prompt#isploop()
        call winj#close()
    endif
    retu svnj#passed()
endf
"2}}}
"1}}}
