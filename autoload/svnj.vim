" =============================================================================
" File:         autoload/svnj.vim
" Description:  Plugin for svn
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" =============================================================================

"autoload/svnj.vim {{{1
"global vars {{{2
if !exists('g:svnj_glb_init') | let g:svnj_glb_init = svnjglobals#init() | en
"2}}}

"script vars {{{2
let s:keyhidesyn = 'syn match SVNHide ' . '/:\d+:/'
"exe "highlight SignColumn guibg=black"
let s:endnow = 0
"2}}}

"SVNDiff {{{2
fun! svnj#SVNDiff()
    try
        call svnj#init()
        let url = svnj#svn#url(svnj#utils#bufFileAbsPath())
        call winj#diffFile('', url)
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
        call winj#blame('', svnj#utils#bufFileAbsPath())
    catch
        let edict = svnj#dict#new("SVNBlame")
        call svnj#dict#addErr(edict, 'Failed ', v:exception)
        call winj#populateJWindow(edict)
        call edict.clear()
        unlet! edict
    endtry
endf
"2}}}

"init/exit {{{2
fun! svnj#doexit() 
    retu s:endnow
endf

fun! svnj#prepexit()
    let s:endnow = 1
    call svnj#stack#clear()
    call svnj#select#clear()
    return 1
endf

fun! svnj#init()
    echo "Contacting the svn server please wait"
    call svnj#stack#clear()
    call svnj#select#clear()
    let s:endnow = 0
endf
"2}}}
"1}}}
