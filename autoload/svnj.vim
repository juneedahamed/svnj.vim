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
fun! svnj#SVNDiff()
    try
        call svnj#init()
        let url = svnj#svn#url(svnj#utils#bufFileAbsPath())
        call svnj#act#diff('', url)
    catch
        let edict = svnj#dict#new("SVNDiff")
        call svnj#dict#addErr(edict, 'Failed ', v:exception)
        call winj#populateJWindow(edict)
        call edict.clear()
        unlet! edict
    endtry
endf
"2}}}

"SVNBlame {{{2
fun! svnj#SVNBlame()
    try
        call svnj#init()
        call svnj#act#blame('', svnj#utils#bufFileAbsPath())
    catch
        let edict = svnj#dict#new("SVNBlame")
        call svnj#dict#addErr(edict, 'Failed ', v:exception)
        call winj#populateJWindow(edict)
        call edict.clear()
        unlet! edict
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
        let edict = svnj#dict#new("SVNInfo")
        call svnj#dict#addErr(edict, 'Failed ', v:exception)
        call winj#populateJWindow(edict)
        call edict.clear()
        unlet! edict
    endtry
endf
"2}}}

fun! svnj#home() "{{{2
    let [atHome, jwinnr] = [0, bufwinnr('svnj_window')]
    if jwinnr > 0
        silent! exe  jwinnr . 'wincmd w'
        let atHome = 1
    endif
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
    let g:svnj_a_winnr = winnr()
    call svnj#stack#clear()
    call svnj#select#clear()
    let s:endnow = 0
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
