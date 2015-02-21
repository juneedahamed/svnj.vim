"===============================================================================
" File:         autoload/svnj/status.vim
" Description:  SVN Status (svn st)
" Author:       Juneed Ahamed
"===============================================================================

"svnj/status.vim {{{1
"vars {{{2
let [s:selectkey, s:selectdscr] = svnj#utils#selkey()
"2}}}

"Key mappings for svn status output statusops {{{2
fun! svnj#status#statusops()
   return {
               \ "\<Enter>"  :{"bop":"<enter>", "dscr" :'Ent:Opn', "fn":'svnj#gopshdlr#openFile', "args":['svnj#act#efile']},
               \ "\<C-o>"    :{"bop":"<c-o>", "dscr" :'C-o:OpnAll', "fn":'svnj#gopshdlr#openFltrdFiles', "args":['svnj#act#efile']},
               \ "\<C-d>"    :{"bop":"<c-d>", "dscr" :'C-d:Diff', "fn":'svnj#gopshdlr#openFile', "args":['svnj#act#diff']},
               \ "\<C-i>"    :{"bop":"<c-i>", "dscr" :'C-i:Info', "fn":'svnj#gopshdlr#info'},
               \ "\<C-w>"    :{"bop":"<c-w>", "dscr" :'C-w:Wrap!', "fn":'svnj#gopshdlr#toggleWrap'},
               \ "\<C-y>"    :{"bop":"<c-y>", "dscr" :'C-y:Cmd', "fn":'svnj#gopshdlr#cmd'},
               \ "\<C-b>"     :{"bop":"<c-b>", "dscr" :'C-b:Book', "fn":'svnj#gopshdlr#book'},
               \ s:selectkey :{"bop":"<c-space>", "dscr" : s:selectdscr, "fn":'svnj#gopshdlr#select'},
               \ "\<C-e>"    : {"bop":"<c-e>", "dscr":'C-e:SelectAll', "fn":'svnj#gopshdlr#selectall'},
               \ "\<C-z>"    : {"bop":"<c-z>", "dscr":'C-z:Commit', "fn":'svnj#gopshdlr#commit'},
               \ "\<C-g>"    : {"bop":"<c-g>", "dscr":'C-g:Add', "fn":'svnj#gopshdlr#add'},
               \ "\<C-s>"    : {"dscr":'C-s:stick!', "fn":'svnj#prompt#setNoLoop'},
               \ "\<F5>"     : {"dscr":'F5:redr', "fn":'svnj#act#forceredr'},
               \ }
endf
"2}}}

"SVNStatus {{{2
fun! svnj#status#SVNStatus(...)
    let sdict = svnj#dict#new("SVN Status")
    try
        let [cargs, target] = ["", ""]
        for elem in a:000
            if elem == 'q' | let cargs = ' -q ' | cont | en
            if elem == 'u' | let cargs = cargs . ' -u ' | cont| en
            if elem == '.' | let target = getcwd() | cont | en
            if isdirectory(elem) | let target = svnj#utils#expand(elem) | cont | en
        endfor

        if target == '' | let target = svnj#svn#workingRoot() | en
        let svncmd = 'svn st --non-interactive ' . cargs . ' ' . fnameescape(svnj#utils#expand(target))

        call svnj#init()
        let sdict.title = "SVN Status :" . target

        let sdict.meta = svnj#svn#getMeta(target)
        let sdict.meta.cmd = svncmd
        let [entries, tdir] = svnj#svn#summary(svncmd)
        if empty(entries)
            call svnj#dict#addErr(sdict, 'No Modified files ..', '' )
        else
            call svnj#dict#addEntries(sdict, 'statusd', entries, svnj#status#statusops())
        endif
    catch
        call svnj#dict#addErr(sdict, 'Failed ', v:exception)
    endtry
    call winj#populateJWindow(sdict)
endf
"2}}}
"1}}}
