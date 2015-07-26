" =============================================================================
" File:         autoload/svnj/utils.vim
" Description:  util functions
" Author:       Juneed Ahamed
" Credits:      strip expresion from DrAI(StackOverflow.com user)
" =============================================================================

"utils {{{1

"syntax {{{2
fun! svnj#utils#getMenuSyn()
    let [menustart, menuend] = ['>>>', '<<<']
    let menupatt = "/" . menustart . "\.\*/"
    let menusyntax = 'syn match SVNMenu ' . menupatt
    retu [menustart, menuend, menusyntax]
endf

fun! svnj#utils#getErrSyn()
    let [errstart, errend] = ['--ERROR--:', '']
    let errpatt = "/" . errstart . "/"
    let errsyntax = 'syn match SVNError ' . errpatt
    retu [errstart, errend, errsyntax]
endf

fun! svnj#utils#getSVNJSyn()
    retu 'syn match SVNJ /^SVNJ\:.*/'
endf
"2}}}

fun! svnj#utils#stl(title, ops) "{{{
    let [s:winjhi, s:svnjhl] = [g:svnj_custom_statusbar_title, g:svnj_custom_statusbar_hl]
    let title = s:winjhi . a:title
    let alignright = '%='
    let opshl = ' %#'.g:svnj_custom_statusbar_ops_hl.'# ' 
    let ops = opshl.a:ops
    retu title.alignright.opshl.ops
endf
"2}}}

fun! svnj#utils#keysCurBuffLines() "{{{2
    let keys = []
    for i in range(1, line('$'))
        let [key, value] = svnj#utils#extractkey(getline(i))
        if key != "" | call add(keys, key) | en
    endfor
    retu keys
endf
"2}}}

fun! svnj#utils#extractkey(line) "{{{2
    if matchstr(a:line, g:svnj_key_patt) != ""
        let tokens = split(a:line, ':')
        if len(tokens) > 1 
            retu [svnj#utils#strip(tokens[0]), svnj#utils#strip(join(tokens[1:], ":"))]
        endif
    elseif matchstr(a:line, '--ERROR--') != ""
        retu ['err', svnj#utils#strip(a:line)]
    endif
    retu [line("."), svnj#utils#strip(a:line)]
endf
"2}}}

fun! svnj#utils#bufFileAbsPath() "{{{2
    let fileabspath = expand('%:p')
    if fileabspath ==# ''
        throw 'Error No file in buffer'
    endif
    retu fileabspath
endf
"2}}}

fun! svnj#utils#expand(path) "{{{2
    let path = expand(a:path)
    if has('win32') | let path = substitute(path, '\\', '/', 'g') | en
    retu  path == ""? a:path : path
endf
"2}}}

fun! svnj#utils#isdir(path) "{{{2
    retu isdirectory(svnj#utils#expand(fnameescape(a:path)))
endf
"2}}}

fun! svnj#utils#localFS(fname) "{{{2
    retu filereadable(fnameescape(a:fname)) || svnj#utils#isdir(a:fname)
endf
"2}}}

fun! svnj#utils#joinPath(v1, v2) "{{{2
    let sep = ""
    if len(a:v1) == 0 | retu svnj#utils#strip(a:v2) | en
    if matchstr(a:v1, "/$") != '/' 
        let sep = "/"
    endif
    retu svnj#utils#strip(a:v1) . sep . svnj#utils#strip(a:v2)
endf
"2}}}

fun! svnj#utils#globpath(dir) "{{{2
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
    retu files
endf
"2}}}

fun! s:filedirs(flist, slinenum) "{{{2
    let [files, dirs] = [[], []]
    let linenum = a:slinenum
    let strip_pat = '^\./' 
    for entry in a:flist
        if len(matchstr(entry, g:p_ign_fpat)) != 0 | con | en
        let entry = substitute(entry, strip_pat, "", "")
        if svnj#utils#isdir(entry)
            let entry = entry . "/"
            call add(dirs, entry)
        endif
        let linenum += 1
        let entry = printf("%5d:%s", linenum, entry)
        call add(files, entry)
    endfor
    retu [files, dirs]
endf
"2}}}

fun! svnj#utils#buffiles(curbufname) "{{{2
    let bfiles = []
    try 
        let bfiles = sort(filter(range(1, bufnr('$')), 'getbufvar(v:val, "&bl") && bufname(v:val) != ""'))
        let bfiles =map(bfiles, 'bufname(v:val)')
    catch | call svnj#utils#dbgMsg("At svnj#utils#buffiles :", v:exception) | endt
    retu bfiles
endf
"2}}}

fun! svnj#utils#formatBrowsedEntries(entries) "{{{2
    let entries = []
    let linenum = 0
    for entry in a:entries
        let linenum += 1
        let entry = printf("%5d:%s", linenum, entry)
        call add(entries, entry)
    endfor
    retu entries
endf
"2}}}

fun! svnj#utils#parseTargetAndNumLogs(arglist) "{{{2
    let [target, numlogs] = ["", ""]
    try
        for thearg in a:arglist
            let thearg = svnj#utils#strip(thearg)
            let tnumlogs = matchstr(thearg, "^\\d\\+$")
            if tnumlogs != '' && numlogs == ""
                let numlogs = tnumlogs
                cont
            endif
            let target = thearg
        endfor
    catch 
        call svnj#utils#dbgMsg("svnj#utils#parseTargetAndNumLogs", v:exception) 
    endt
    try
        if target == "" | let target = svnj#utils#bufFileAbsPath() | en
    catch| let target = getcwd() | endt

    if numlogs == "" | let numlogs = g:svnj_max_logs | en
    retu [fnameescape(target), numlogs]
endf
"2}}}

fun! svnj#utils#strip(input_string) "{{{2
    retu substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf
"2}}}

fun! svnj#utils#getparent(url) "{{{2
    let url = matchstr(a:url, "/$") == '/' ? a:url[:-2] : a:url
    let url = fnamemodify(url, ":h")
    let url = url . "/"
    retu url
endf
"2}}}

fun! svnj#utils#isSvnDirReg(url) "{{{2
    let slash = matchstr(a:url, "/$")
    retu slash == "/" 
endf
"2}}}

fun! svnj#utils#sortConvInt(i1, i2) "{{{2
    retu a:i1 - a:i2
endf
"2}}}

fun! svnj#utils#sortftime(f1, f2) "{{{2
    retu getftime(a:f1) - getftime(a:f2)
endf
"2}}}

fun! svnj#utils#showErrJWindow(title, exception) "{{{2
    let edict = svnj#dict#new(a:title)
    call svnj#dict#addErr(edict, 'Failed ', a:exception)
    call winj#populateJWindow(edict)
    call edict.clear()
    unlet! edict
endf
"2}}}

fun! svnj#utils#showerr(msg) "{{{2
    echohl Error | echo a:msg | echohl None
    let ign = input('Press Enter to coninue :')
    retu svnj#failed()
endf
"2}}}

fun! svnj#utils#showConsoleMsg(msg, wait) "{{{2
    redr | echohl special | echon a:msg | echohl None
    if a:wait
        let x = input("Press Enter to continue :")
    endif
endf
"2}}}

fun! svnj#utils#errDict(title, emsg) "{{{2
    let edict = svnj#dict#new(a:title)
    let edict.meta = svnj#svn#blankMeta()
    call svnj#dict#addErr(edict, a:emsg, "")
    retu edict
endf
"2}}}

fun! svnj#utils#dbgMsg(title, args) "{{{2
    if g:svnj_enable_debug
        echo a:args
        let x = input(a:title)
    endif
endf
"2}}}

fun! svnj#utils#edbgmsg(title, args) "{{{2
    if g:svnj_enable_debug
        echo a:args
        let x = input(a:title)
    endif
endf
"2}}}

fun! svnj#utils#execShellCmd(cmd) "{{{2 
    let [cmd, status] = [a:cmd, svnj#failed()]

    if !g:svnj_auth_disable && strlen(g:svnj_username) > 0 && 
                \ strlen(g:svnj_password) > 0 && svnj#svn#is_cmd(a:cmd) 
        let cmd = svnj#svn#fmt_auth_info(cmd) 
    endif

    let shellout = system(cmd)
    if v:shell_error != 0 
        if !g:svnj_auth_disable && svnj#svn#is_auth_err(shellout) 
            let [status, shellout] = svnj#svn#exec_with_auth(cmd)
        endif

        if status == svnj#failed() 
            throw 'FAILED CMD: ' . shellout 
        endif
    endif
    retu shellout
endf
"2}}}

fun! svnj#utils#input(title, description, prompt) "{{{2
    let inputstr = ""
    while 1
        echohl Title | echo "" | echo a:title
        echohl Directory| echo "" | echo a:description 
        echohl Question | echon a:prompt | echohl None | echon inputstr
        let chr = svnj#utils#getchar()
        if chr == "\<Esc>"
            retu "\<Esc>"
        elseif chr == "\<Enter>"
            retu inputstr
        elseif chr ==# "\<BS>" || chr ==# '\<Del>'
            if len(inputstr) > 0 
                let inputstr = inputstr[:-2]
            endif
        else
            let inputstr = inputstr . chr
        endif
        redr
    endwhile
endf
"2}}}

fun! svnj#utils#inputsecret(title, prompt) "{{{2
    echohl Title | echo "" | echo a:title | echohl None
    let secret = inputsecret(a:prompt)
    redr | retu secret
endf
"2}}}

fun! svnj#utils#getchar() "{{{2
    let chr = getchar()
    retu !type(chr) ? nr2char(chr) : chr
endf
"2}}}

fun! svnj#utils#inputchoice(msg) "{{{2
    echohl Question | echon a:msg . " : " | echohl None 
    let choice = input("")
    retu choice
endf
"2}}}

"browse dirs {{{2
fun! svnj#utils#listFiles(url, rec, igndir)
    let cwd = getcwd()
    sil! exe 'lcd ' . fnameescape(a:url)
    let entries = a:rec ? svnj#utils#globpath(".") :
                \ s:lstNonRec(a:igndir)
    sil! exe 'lcd ' . fnameescape(cwd)
    retu entries
endf

fun! s:lstNonRec(igndir)
    let fileslst = split(globpath('.', "*"), '\n')
    let entries = []
    let strip_pat = '^\./' 
    let linenum = 1
    for line in  fileslst
        let linenum += 1
        if len(matchstr(line, g:p_ign_fpat)) != 0 | con | en
        if svnj#utils#isdir(line) | let line = line . "/"  | en
        let line = substitute(line, strip_pat, "", "")
        let line = printf("%5d:%s", linenum, line)
        call add(entries, line)
    endfor
    retu entries
endf
"2}}}

fun! svnj#utils#addHeader(thefiles, dscr) "{{{2
    let blines = []
    call add(blines, 'SVNJ: -----------------------------------------------------------------')
    call add(blines, "SVNJ: Following files will be Added")
    call add(blines, "SVNJ: ")
    for thefile in a:thefiles
        call add(blines, "SVNJ:+" . thefile)
    endfor
    call add(blines, "SVNJ: ")
    call add(blines, "SVNJ: The above listed files are chosen for svn add, You can delete/add")
    call add(blines, "SVNJ: files instead of repeating the operation, use same syntax")
    call add(blines, "SVNJ: Comments required to commit after adding")
    call add(blines, "SVNJ: Supported operations : " . a:dscr)
    call add(blines, 'SVNJ: --------Enter comments below this line for commit ---------------')
    call add(blines, '')
    retu blines
endf
"2}}}

fun! svnj#utils#commitHeader(thefiles, dscr) "{{{2
    let blines = []
    call add(blines, 'SVNJ: -----------------------------------------------------------------')
    call add(blines, "SVNJ: Following files will be committed")
    call add(blines, "SVNJ: ")
    for thefile in a:thefiles
        call add(blines, "SVNJ:+" . thefile)
    endfor
    call add(blines, "SVNJ: ")
    call add(blines, "SVNJ: The above listed files are chosen for commit, You can delete")
    call add(blines, "SVNJ: files by deleting the line listing the file if not to be")
    call add(blines, "SVNJ: commited instead of repeating the operation")
    call add(blines, "SVNJ: Lines started with SVNJ: will not be sent as comment")
    call add(blines, "SVNJ: Supported operations : " . a:dscr)
    call add(blines, 'SVNJ: ---------------Enter Comments below this line--------------------')
    call add(blines, '')
    retu blines
endf
"2}}}

fun! svnj#utils#copyHeader(urls, dscr) "{{{2
    let blines = []
    call add(blines, 'SVNJ: -----------------------------------------------------------------')
    call add(blines, "SVNJ: The copy operations ends with commit, Please provide comments")
    for idx in range(0, len(a:urls) - 2)
        call add(blines, "SVNJ:SOURCE: " . a:urls[idx])
    endfor
    call add(blines, "SVNJ:DESTINATION: " . a:urls[len(a:urls)-1])
    call add(blines, "SVNJ: Lines started with SVNJ: will not be sent as comment")
    call add(blines, "SVNJ: Supported operations : " . a:dscr)
    call add(blines, 'SVNJ: ---------------Enter Comments below this line--------------------')
    call add(blines, '')
    retu blines
endf
"2}}}

fun! svnj#utils#writeToBuffer(bname, lines) "{{{2 
    let bwinnr = bufwinnr(a:bname)
    if bwinnr == -1 | retu 0 | en
    silent! exe  bwinnr . 'wincmd w'
    call setline(1, a:lines)
    exec "normal! G"
    retu svnj#passed()
endf
"2}}}

"constants/keys/operations {{{2
fun! svnj#utils#getkeys()
   retu ['meta', 'logd', 'statusd', 'commitsd', 'browsed', 'menud', 'error']
endf

fun! svnj#utils#getEntryKeys()
    retu ['logd', 'statusd', 'commitsd', 'browsed', 'flistd', 'menud', 'error']
endf

fun! svnj#utils#selkey()
    retu has('gui_running') ? ["\<C-Space>", 'C-space:Sel'] :
                \ ["\<C-f>", 'C-f:Sel']
endf

fun! svnj#utils#topkey()
    retu has('gui_running') ? ["\<C-t>", 'C-t:Top'] :
                \ ["\<C-t>", 'C-t:Top']
endf

fun! svnj#utils#CtrlEntReplace(descr)
    retu has('gui_running') ? ["\<C-Enter>", 'C-Ent:' . a:descr] :
                \ ["\<C-x>", 'C-e:' . a:descr ]
endf

fun! svnj#utils#topop()
    let [topkey, topdscr] = svnj#utils#topkey()
    retu {topkey : {"bop":"<c-t>", "dscr":topdscr, "fn":'svnj#stack#top'}}
endf

fun! svnj#utils#upop()
    retu {"\<C-u>": {"bop":"<c-u>", "dscr":'C-u:Up', "fn":'svnj#stack#pop'}}
endf
"2}}}

"1}}}
