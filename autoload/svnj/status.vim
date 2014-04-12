"===============================================================================
" File:         autoload/svnj/status.vim
" Description:  SVN Status (svn st )
" Author:       Juneed Ahamed
"===============================================================================

"vars {{{2
if !exists('g:svnj_glb_init') | let g:svnj_glb_init = svnjglobals#init() | en
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
"2}}}

"Key mappings for svn status output statusops {{{2
fun! svnj#status#statusops()
   return {
               \ "\<Enter>"  : ['Ent:Open', 'svnj#gopshdlr#openFile', 'winj#newBufOpen'],
               \ "\<C-o>"    : ['C-o:OpenAll', 'svnj#gopshdlr#openAllFiles', 'winj#newBufOpen'],
               \ "\<C-w>"    : ['C-w:wrap!', 'svnj#gopshdlr#toggleWrap'],
                \ s:selectkey  : [s:selectdscr, 'svnj#gopshdlr#select'],
               \ }
endf
"2}}}

"SVNStatus {{{2
fun! svnj#status#SVNStatus(...)
    call svnj#init()
    let s:sdict = svnj#dict#new("SVN Status")
    try
        let choice = a:0 > 0 ? a:1 :
                    \ input('Status (q quiet|u updates| '. 
                    \ 'Enter for All|Space separated multiple grep args): ')

        let s:sdict.meta = svnj#svn#getMeta(getcwd())
        let cwd = s:sdict.meta.wrd
        let svncmd = strlen(choice) > 0 ? s:argsSVNStatus(choice, cwd) :
                    \ 'svn st --non-interactive ' . cwd
        let entries = svnj#svn#summary(svncmd, s:sdict.meta)
        if empty(entries)
            call svnj#dict#addErr(s:sdict, 'No Modified files ..', '' )
        else
            call svnj#dict#addEntries(s:sdict, 'statusd', entries, svnj#status#statusops())
        endif
    catch
        call svnj#dict#addErr(s:sdict, 'Failed ', v:exception)
    endtry
    call winj#populateJWindow(s:sdict)
    call s:sdict.clear()
endf
"2}}}

"SVNStatus helpers {{{2
fun! s:argsSVNStatus(choice, cwd)
    let quiet = 0
    let the_up = 0
    let thegrep_cands = []
    let cwd = a:cwd
    for token in split(a:choice)
        if token ==# '.' | let cwd = getcwd()
        elseif toupper(token) ==# 'Q' | let quiet = 1
        elseif toupper(token) ==# 'U' | let the_up = 1
        else | call add(thegrep_cands, token)
        endif
    endfor

    let svncmd = (the_up == 1 ) ? 'svn st --non-interactive -u ' :
                \ 'svn st --non-interactive '
    let svncmd = (quiet == 1 ) ? svncmd . ' -q ' . cwd : svncmd . cwd
    if len(thegrep_cands) > 0
        let thegrep_expr = '(' . join(thegrep_cands, '|') . ')'
        let svncmd = svncmd . " | grep -E \'" . thegrep_expr . "\'"
    endif
    return svncmd
endf
"2}}}

