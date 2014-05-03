"===============================================================================
" File:         autoload/svnj/status.vim
" Description:  SVN Status (svn st )
" Author:       Juneed Ahamed
"===============================================================================

"svnj/status.vim {{{1
"vars {{{2
if !exists('g:svnj_glb_init') | let g:svnj_glb_init = svnjglobals#init() | en
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
"2}}}

"Key mappings for svn status output statusops {{{2
fun! svnj#status#statusops()
   return {
               \ "\<Enter>"  : ['Ent:Open', 'svnj#gopshdlr#openFile', 'winj#newBufOpen'],
               \ "\<C-o>"    : ['C-o:OpenAll', 'svnj#gopshdlr#openFltrdFiles', 'winj#newBufOpen'],
               \ "\<C-d>"    : ['C-d:Diff', 'svnj#gopshdlr#openFile', 'winj#diffFile'],
               \ "\<C-i>"    : ['C-i:Info', 'svnj#gopshdlr#info'],
               \ "\<C-w>"    : ['C-w:Wrap!', 'svnj#gopshdlr#toggleWrap'],
               \ "\<C-y>"    : ['C-y:Cmd', 'svnj#gopshdlr#cmd'],
               \ s:selectkey  : [s:selectdscr, 'svnj#gopshdlr#select'],
               \ }
endf
"2}}}

"SVNStatus {{{2
fun! svnj#status#SVNStatus(...)
    let s:sdict = svnj#dict#new("SVN Status")
    try
        let [cargs, target] = ["", ""]
        for elem in a:000
            if elem == 'q' | let cargs = ' -q ' | cont | en
            if elem == 'u' | let cargs = cargs . ' -u ' | cont| en
            if elem == '.' | let target = getcwd() | cont | en
            if isdirectory(elem) | let target = expand(elem) | cont | en
        endfor

        if target == '' | let target = svnj#svn#workingRoot() | en
        let svncmd = 'svn st --non-interactive ' . cargs . ' ' . target

        call svnj#init()
        let s:sdict.title = "SVN Status :" . target

        let s:sdict.meta = svnj#svn#getMeta(target)
        let s:sdict.meta.cmd = svncmd
        let [entries, tdir] = svnj#svn#summary(svncmd)
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
"1}}}
