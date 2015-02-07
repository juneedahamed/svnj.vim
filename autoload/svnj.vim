" =============================================================================
" File:         autoload/svnj.vim
" Description:  Plugin for svn
" Author:       Juneed Ahamed
" =============================================================================

"autoload/svnj.vim {{{1
"script vars {{{2
let s:endnow = 0
"2}}}

"SVNDiff {{{2
fun! svnj#SVNDiff(bang, ...)
    try
        call svnj#init()
        let [force, diffwith] = ["noforce", ""]
        let url = svnj#svn#url(svnj#utils#bufFileAbsPath())
        let lcr = "r". svnj#svn#lastChngdRev(url)
        call svnj#svn#logs(g:svnj_max_logs, url)
        let diffwith = lcr
        if a:bang == "!"
            let diffwith = len(g:svnj_logversions) > 0 ? g:svnj_logversions[0] : ''
            if diffwith == lcr && len(g:svnj_logversions) > 1
                let diffwith = g:svnj_logversions[1]
                let force = "force"
            endif 
        endif
        call svnj#act#diff(diffwith, url, force)
    catch
        call svnj#utils#showErrJWindow("SVNDiff", v:exception)
    endtry
endf
"2}}}

"SVNBlame {{{2
fun! svnj#SVNBlame()
    try
        call svnj#init()
        call svnj#act#blame('', svnj#utils#bufFileAbsPath())
    catch
        call svnj#utils#showErrJWindow("SVNBlame", v:exception)
    endtry
endf
"2}}}

"SVNInfo {{{2
fun! svnj#SVNInfo(...)
    try
        let target = ""
        call svnj#init()
        if a:1 == ""
            let fileabspath = expand('%:p')
            if fileabspath != ''
                let target = fileabspath
            endif
        else
            let target = a:1
        endif
        call svnj#utils#showConsoleMsg(svnj#svn#info(target), 0)
    catch
        call svnj#utils#showErrJWindow("SVNInfo", v:exception)
    endtry
endf
"2}}}

fun! svnj#home() "{{{2
    let [athome, curwinnr, jwinnr] = [ 0, winnr(), bufwinnr('svnj_window')]
    if jwinnr > 0 && curwinnr != jwinnr
        silent! exe jwinnr . 'wincmd w'
    endif
    let atHome = jwinnr > 0 ? 1 : 0
    retu [atHome, jwinnr]
endf
"2}}}

"init/exit {{{2
fun! svnj#doexit() 
    retu s:endnow
endf

fun! svnj#prepexit()
    if svnj#prompt#isploop() 
        let s:endnow = 1
        call svnj#stack#clear()
        call svnj#select#clear()
    else
        call svnj#select#clear()
    endif
    return 1
endf

fun! svnj#init()
    let g:svnj_logversions = []
    call svnj#stack#clear()
    call svnj#select#clear()
    let s:endnow = 0
endf

fun! svnj#altwinnr()
    let altwin = winnr('#')
    let jwinnr = bufwinnr('svnj_window')
    let curwin = winnr()
    try
        if jwinnr > 0 && altwin > 0 && curwin != altwin && jwinnr != altwin
            silent! exe  altwin . 'wincmd w'
        endif
    catch | endtry
endf
"2}}}

"result returns {{{2
fun! svnj#failed()
    retu 0
endf

fun! svnj#passed()
    retu 1
endf

fun! svnj#nofltrclear()
    retu 2
endf

fun! svnj#cancel()
    retu 3
endf

fun! svnj#noPloop()
    retu 10
endf

fun! svnj#fltrclearandexit()
    retu 110
endf
"2}}}

"1}}}
