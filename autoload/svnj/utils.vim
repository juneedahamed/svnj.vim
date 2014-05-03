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

fun! svnj#utils#keysCurBuffLines()
    let keys = []
    for i in range(1, line('$'))
        let [key, value] = svnj#utils#extractkey(getline(i))
        if key != "" | call add(keys, key) | en
    endfor
    return keys
endf

fun! svnj#utils#extractkey(line)
    if matchstr(a:line, g:svnj_key_patt) != ""
        let tokens = split(a:line, ':')
        if len(tokens) > 1 
            retu [svnj#utils#strip(tokens[0]), svnj#utils#strip(join(tokens[1:], ":"))]
        endif
    elseif matchstr(a:line, '--ERROR--') != ""
        return ['err', svnj#utils#strip(a:line)]
    endif
    return [line("."), svnj#utils#strip(a:line)]
endf

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

fun! svnj#utils#globpath(dir)
    try 
        setl nomore
    catch | endt

    let cdir = (a:dir == "" || a:dir == ".") ? getcwd() : a:dir
    let [result, ffiles] = svnj#caop#fetch("wc", cdir)
    if result | retu ffiles | en

    let [files, tdirs] = [[], [a:dir]]
    while len(files) < g:svnj_browse_max_files_cnt && len(tdirs) > 0
        let curdir = svnj#utils#strip(remove(tdirs, 0))
        call svnj#utils#showConsoleMsg("Fetching files : " . curdir, 0)
        let flist = split(globpath(curdir, "*"), "\n")
        let [tfiles, tdirs2] =  s:filedirs(flist, len(files)+1)
        call extend(files, tfiles)
        call extend(tdirs, tdirs2)
        unlet! flist tfiles tdirs2 
    endwhile
    unlet! tdirs
    call svnj#caop#cache("wc", cdir, files)
    return files
endf

fun! s:filedirs(flist, slinenum)
    let [files, dirs] = [[], []]
    let linenum = a:slinenum
    let strip_pat = '^\./' 
    for entry in a:flist
        if len(matchstr(entry, g:p_ign_fpat)) != 0 | con | en
        let entry = substitute(entry, strip_pat, "", "")
        if isdirectory(entry)
            let entry = entry . "/"
            call add(dirs, entry)
        endif
        let linenum += 1
        let entry = printf("%5d:%s", linenum, entry)
        call add(files, entry)
    endfor
    return [files, dirs]
endf

fun! svnj#utils#formatBrowsedEntries(entries)
    let entries = []
    let linenum = 0
    for entry in a:entries
        let linenum += 1
        let entry = printf("%5d:%s", linenum, entry)
        call add(entries, entry)
    endfor
    return entries
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

fun! svnj#utils#isSvnDirReg(url)
    let slash = matchstr(a:url, "/$")
    return slash == "/" 
endf

fun! svnj#utils#sortConvInt(i1, i2)
    retu a:i1 - a:i2
endf

fun! svnj#utils#sortftime(f1, f2)
    retu getftime(a:f1) - getftime(a:f2)
endf

fun! svnj#utils#showErrorConsole(msg)
    echohl Error | echo a:msg | echohl None
    let ign = input('Press Enter to coninue :')
endf

fun! svnj#utils#showConsoleMsg(msg, wait)
    redr | echohl special | echon a:msg | echohl None
    if a:wait
        let x = input("Press Enter to continue :")
    endif
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
fun! svnj#utils#listFiles(url, rec, igndir)
    let cwd = getcwd()
    sil! exe 'lcd ' . a:url
    let entries = a:rec ? svnj#utils#globpath(".") :
                \ s:lstNonRec(a:url, a:igndir)
    sil! exe 'lcd ' . cwd
    return entries
endf

fun! s:lstNonRec(url, igndir)
    let fileslst = split(globpath('.', "*"), '\n')
    let entries = []
    let strip_pat = '^\./' 
    let linenum = 1
    for line in  fileslst
        let linenum += 1
        if len(matchstr(line, g:p_ign_fpat)) != 0 | con | en
        if isdirectory(line) | let line = line . "/"  | en
        let line = substitute(line, strip_pat, "", "")
        let line = printf("%5d:%s", linenum, line)
        call add(entries, line)
    endfor
    retu entries
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

fun! svnj#utils#topkey()
    return has('gui_running') ? ["\<C-t>", 'C-t:Top'] :
                \ ["\<C-t>", 'C-t:Top']
endf

fun! svnj#utils#CtrlEntReplace(descr)
    return has('gui_running') ? ["\<C-Enter>", 'C-Ent:' . a:descr] :
                \ ["\<C-e>", 'C-e:' . a:descr ]
endf

fun! svnj#utils#topop()
    let [topkey, topdscr] = svnj#utils#topkey()
    return {topkey : [topdscr, 'svnj#stack#top'],}
endf

fun! svnj#utils#upop()
    return {"\<C-u>": ['C-u:Up', 'svnj#stack#pop'],}
endf

fun! svnj#utils#cmdop()
    return {"\<C-y>": ['C-y:Cmd', 'svnj#gopshdlr#cmd'],}
endf
"2}}}
"1}}}
