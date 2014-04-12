" =============================================================================
" File:         autoload/svnj/utils.vim
" Description:  util functions
" Author:       Juneed Ahamed
" Credits:      strip expresion from DrAI(StackOverflow.com user)
" =============================================================================

if !exists('g:svnj_glb_init') | let g:svnj_glb_init = svnjglobals#init() | en

"utils {{{1

"syntax {{{2
fun! svnj#utils#getMenuSyn()
    let [menustart, menuend] = ['>>>', '<<<']
    let menupatt = "/" . menustart . "\.\*/"
    let menusyntax = 'syn match SVNMenu ' . menupatt
    return [menustart, menuend, menusyntax]
endf

fun! svnj#utils#getErrSyn()
    let [errstart, errend] = ['--ERROR--:', '']
    let errpatt = "/" . errstart . "/"
    let errsyntax = 'syn match SVNError ' . errpatt
    return [errstart, errend, errsyntax]
endf
"2}}}

fun! svnj#utils#bufFileAbsPath()
    let fileabspath = expand('%:p')
    if fileabspath ==# ''
        throw 'Error No file in buffer'
    endif
    return fileabspath
endf

fun! svnj#utils#joinPath(v1, v2)
    let sep = ""
    if len(a:v1) == 0 | retu a:v2 | en
    if matchstr(a:v1, "/$") != '/' 
        let sep = "/"
    endif
    return a:v1 . sep . a:v2
endf

fun! svnj#utils#strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf

fun! svnj#utils#getparent(url)
    let url = matchstr(a:url, "/$") == '/' ? a:url[:-2] : a:url
    let url = fnamemodify(url, ":h")
    let url = url . "/"
    return url
endf

fun! svnj#utils#isSvnDir(url)
    let slash = matchstr(a:url, "/$")
    return slash == "/" 
endf

fun! svnj#utils#sortConvInt(i1, i2)
    retu a:i1 - a:i2
endf

fun! svnj#utils#showErrorConsole(msg)
    echohl Error | echo a:msg | echohl None
    let ign = input('Press Enter to coninue :')
endf

fun! svnj#utils#errDict(title, emsg)
    let edict = svnj#dict#new(a:title)
    let edict.meta = svnj#svn#blankMeta()
    call svnj#dict#addErr(edict, a:emsg, "")
    retu edict
endf

fun! svnj#utils#dbgHld(title, args)
    if g:svnj_enable_debug
        echo a:args
        let x = input(a:title)
    endif
endf

fun! svnj#utils#execShellCmd(cmd)
    let shellout = system(a:cmd)
    if v:shell_error != 0
        throw 'FAILED CMD: ' . shellout
    endif
    return shellout
endf

"browse dirs {{{2
fun! svnj#utils#listFiles(url, rec, ignore_dirs)
    let cwd = getcwd()
    sil! exe 'lcd ' . a:url
    let patt = a:rec ? "**/*" : "*"
    let filesstr = globpath('.', patt)
    let fileslst = split(filesstr, '\n')
    let entries = []
    let strip_pat = '^\./' 
    for line in  fileslst
        if len(matchstr(line, g:p_ign_fpat)) != 0 | con | en
        if a:ignore_dirs == 1 && isdirectory(line) | con | en
        let listentryd = {}
        let line = substitute(line, strip_pat, "", "")
        let line = isdirectory(line)  ? line . "/" : line
        let listentryd.line = line
        call add(entries, listentryd)
    endfor
    sil! exe 'lcd ' . cwd
    return entries
endf
"2}}}

"constants/keys/operations {{{2
fun! svnj#utils#getkeys()
   retu ['meta', 'logd', 'statusd', 'commitsd', 'browsed', 'flistd', 'menud', 'error']
endf

fun! svnj#utils#getEntryKeys()
    return ['logd', 'statusd', 'commitsd', 'browsed', 'flistd', 'menud', 'error']
endf

fun! svnj#utils#selkey()
    return has('gui_running') ? ["\<C-Space>", 'C-space:Mark'] :
                \ ["\<C-H>", 'C-H:Mark']
endf

fun! svnj#utils#upop()
    return {"\<C-u>": ['C-u:up', 'svnj#stack#pop'],}
endf
"2}}}
"1}}}
