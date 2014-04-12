" =============================================================================
" File:         autoload/winj.vim
" Description:  Simple plugin for svn
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" Credits:      Method pyMatch copied and modified from : Alexey Shevchenko
"               Userid FelikZ/ctrlp-py-matcher from github
"
" =============================================================================

"autoload/winj.vim {{{1
"vars "{{{2
let s:jwinname = 'svnj_window'
let s:jwinnr = -1
"let [s:winjhi, s:svnjhl] = ['%#LineNr#', "Question"]
let [s:winjhi, s:svnjhl] = [g:svnj_custom_statusbar_title, g:svnj_custom_statusbar_hl]
let [b:clines, b:flines] = [[], []]
let [b:slst,  s:fregex] = ["", ""]
"2}}}

"win handlers {{{2
fun! winj#JWindow()
    let s:fregex = ""
    call s:closeMe()
    let s:jwinnr = bufwinnr(s:jwinname)
    silent! exe  s:jwinnr < 0 ? 'botright new ' .
                \ fnameescape(s:jwinname) : s:jwinnr . 'wincmd w'
    setl buftype=nowrite bufhidden=wipe nobuflisted
    setl noswapfile nowrap nonumber cul nocuc nomodeline nomore nospell
    autocmd VimResized svnj_window call s:fakeKeys()
    let s:jwinnr = bufwinnr(s:jwinname)
endf

fun! s:fakeKeys()
    "let the getchar get a break with a key that is not handled
    call feedkeys("\<Left>")
    redraw!
endf

fun! s:setup()
    let [mstart, mend, menusyntax] = svnj#utils#getMenuSyn()
    let [estart, eend, errsyntax] = svnj#utils#getErrSyn()
    exec errsyntax | exec  menusyntax
    exec 'hi link SVNError ' . g:svnj_custom_error_color
    exec 'hi link SVNMenu ' . g:svnj_custom_menu_color
endf

fun! s:closeMe()
    let s:jwinnr = bufwinnr(s:jwinname)
    if s:jwinnr > 0
        silent! exe  s:jwinnr . 'wincmd w'
        silent! exe  s:jwinnr . 'wincmd c'
    endif
    return 0
endf
"2}}}

"populate {{{2
fun! winj#populateJWindow(cdict)
    try 
        call winj#JWindow()
        silent! exe s:jwinnr . 'wincmd w'
        call s:setup()
        call winj#populate(a:cdict) | call s:prompt()
    catch | call svnj#utils#dbgHld("populateJWindow", v:exception) | endt
endf

fun! winj#populate(cdict)
    silent! exe s:jwinnr . 'wincmd w'
    let s:cdict = a:cdict
    setl modifiable
    exec 'normal! ggdG'
    let linenum = 0
    let b:clines = []

    try
        let [b:clines, displaylines] = s:cdict.lines()
        call setline(1, displaylines)
    catch | call svnj#utils#dbgHld("At populate", v:exception) | endt
    
    let linenum = line('$') == 1 ? 1 : line('$') + 1 
    if s:cdict.hasError()
        call setline(linenum, s:cdict.error.line)
    endif

    if linenum == 0 | call s:setNoContents(1) | en
    silent! exe 'resize ' . line('$') + 40
    let s:fregex = ""
    call s:updateStatus((len(displaylines)) . '/'. len(b:clines))
    call s:resizewin()
    call s:dohighlights("")
    setl nomodifiable | redr!
endf

fun! s:resizewin()
    silent! exe s:jwinnr . 'wincmd w'
    silent! exe 'resize ' . (line('$') < g:svnj_window_max_size ? line('$') :
                \ g:svnj_window_max_size)
    silent! exe 'normal! gg'
endf

fun! s:setNoContents(linenum)
    call setline(a:linenum, '--ERROR-- No contents')
endf

fun! s:repopulate(fltr, incr)
    try
        if len(a:fltr)> 1 && a:incr && len(b:flines) == 0 | return | endif
        let b:flines = []
        silent! exe s:jwinnr . 'wincmd w'
        setl modifiable | exec 'normal! ggdG'
        call s:filterContents(b:clines, a:fltr, g:svnj_fuzzy_search_result_max)

        if len(b:flines) <= 0 | call s:setNoContents(1)
        else | call setline(1, b:flines) | en

        let tcnt = len(b:clines)
        call s:updateStatus(len(b:flines) . '/'. tcnt)
        call s:dohighlights(a:fltr)
        call s:resizewin()
    catch | call svnj#utils#dbgHld("At repopulate", v:exception) | endt
    setl nomodifiable | redr!
endf
"2}}}

"prompt {{{2
fun! s:prompt()
    let fltr = ""
    let dohl = 1
    while !svnj#doexit()
        try
            redr | exec 'echohl ' . g:svnj_custom_prompt_color
            echon "filter : " | echohl None | echon fltr
            "if dohl | call s:dohighlights(fltr) | en
            let dohl = 1
            let nr = getchar()
            let chr = !type(nr) ? nr2char(nr) : nr

            let key = s:extractkey()
            let opsd = s:cdict.getOps(key)
            if len(opsd) > 0 && has_key(opsd, chr)
                try
                    let fltr = ""
                    let args = [s:cdict, key]
                    call extend(args, opsd[chr][2:])
                    call call(opsd[chr][1], args) | redr! | cont
                catch 
                    call svnj#utils#dbgHld("At prompt", v:exception)
                    call svnj#utils#showErrorConsole("Oops error ") | cont
                endtry
            endif

            if chr ==# "\<BS>" || chr ==# '\<Del>'
                if len(fltr) <= 0  | cont | en
                let fltr = fltr[:-2]
                call s:repopulate(fltr, 0)
            elseif chr == "\<Esc>"
                call svnj#prepexit()
                call s:closeMe() | break
            elseif nr >=# 0x20
                if len(fltr)<=90
                    let fltr = fltr . chr
                    call s:repopulate(fltr, 1)
                endif
            else | let dohl = 0 | exec "normal!" . chr
            endif
        catch | call svnj#utils#dbgHld("At prompt", v:exception) | endt
    endwhile
    exe 'echo ""' |  redr
    call s:closeMe()
endf

fun! s:extractkey()
    let tokens = split(getline('.'), ':')
    if len(tokens) > 0 | retu tokens[0] | en
    return ""
    "let key = matchstr(getline('.'), g:svnj_key_patt)
    "let key = matchstr(key, '\v\c\d+')
    "return key
endf
"2}}}

"highlight {{{2
fun! s:dohighlights(fltr)
     try
        silent! exe s:jwinnr . 'wincmd w'
        call clearmatches()
        if s:fregex != "" | call matchadd(g:svnj_custom_fuzzy_match_hl, '\v\c' . s:fregex) | en
        if len(svnj#select#dict()) && !g:svnj_signs
            let patt = join(map(copy(keys(svnj#select#dict())),
                        \ '"\\<" . v:val . ": " . ""' ), "\\|")
            let patt = "/\\(" . patt . "\\)/"
            exec 'match ' . s:svnjhl . ' ' . patt
        endif
        call svnj#select#resign(s:cdict)
    catch | call svnj#utils#dbgHld("At dohighlights", v:exception) | endt
endf

fun! s:dohicurline()
    try
        "let key = split(getline('.'), ':')[0]
        let key = matchstr(getline('.'), g:svnj_key_patt)
        if key != "" | call matchadd('Directory', '\v\c^' . key) | en
    catch | call svnj#utils#dbgHld("At dohicurline", v:exception) | endt
endf
"2}}}

"open funs {{{2
fun! winj#blame(svnurl, filepath)
    call s:closeMe()
    let filetype=&ft
    let cmd="%!svn blame " . a:filepath
    let newfile = 'vnew '
    exec newfile | exec cmd
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype
    return 0
endf

fun! winj#diffFile(revision, svnurl)
    call s:closeMe()
    let filetype=&ft
    let revision = len(a:revision) > 0 ? " -" . a:revision : ""
    let cmd = "%!svn cat " . revision . ' '. a:svnurl
    diffthis | exec 'vnew '. a:revision | exec cmd |  diffthis
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype
    return 0
endf

fun! winj#openRepoFileVS(revision, url)
    call s:closeMe()
    let [revision, fname] = s:rev_fname(a:revision, a:url)
    let cmd="%!svn cat " . revision . ' ' . a:url
    exec 'vnew ' . fname | exec cmd
    exe "setl bt=nofile bh=wipe nobl noswf ro"
    return 0
endf

fun! winj#newBufOpen(revision, url)
    call s:closeMe()
    let [revision, fname] = s:rev_fname(a:revision, a:url)
    if filereadable(fname)
        let cmd = 'e ' . fname 
        silent! exe cmd |  retu 0
    else
        let cmd="%!svn cat " . revision . ' ' . a:url
        exe 'e ' . fname | exe cmd | retu 0
    endif
    return 0
endf

fun! s:rev_fname(revision, url)
    let revision = a:revision == "" ? "" : " -" .  a:revision 
    let fname = a:revision == "" ? a:url : a:url . "@" .  a:revision 
    return [revision, fname]
endf
"2}}}

"stl update {{{2
fu! s:updateStatus(filecount)
    let fcount = a:filecount
    echo " "
    if strlen(fcount) > 0
        let &l:stl = s:winjhi.s:cdict.title.'%= ' . '%#Search# ' . s:cdict.opdsc . 
                    \ s:winjhi . ' Entries:' . fcount
    else
        let &l:stl = s:winjhi.s:cdict.title.s:winjhi . '%= '. s:cdict.opdsc .
    endif
    redraws
endf
"2}}}

"python filterContents "{{{2
"sets b:slst and s:fregex
fun! s:pyMatch(items, str, limit)
python << EOF
import vim, re
vim.command("let b:slst = ''")
items = vim.eval('a:items')
astr = vim.eval('a:str')
lowAstr = astr.lower()
limit = int(vim.eval('a:limit'))
#rez = vim.bindeval('s:rez') #Oops supported after 7.3+ or something
rez = []

regex = ''
for c in lowAstr[:-1]:
    regex += c + '[^' + c + ']*'
else:
    regex += lowAstr[-1]

res = []
prog = re.compile(regex)
for line in items:
    result = prog.search(line.lower())
    if result:
        score = 1000.0 / ((1 + result.start()) * (result.end() - result.start() + 1))
        res.append((score, line))

sortedlist = sorted(res, key=lambda x: x[0], reverse=True)[:limit]
sortedlist = [x[1] for x in sortedlist]

rez.extend(sortedlist)
result = "\n".join(rez) 

vim.command("let s:fregex = '%s'" % regex)
vim.command("let b:slst = '%s'" % result)
EOF
endf

fun! s:filterContents(items, str, limit)
    let b:flines = []
    let s:fregex = ''
    let wchars = ['*', '\', '~', '@', '%', '(', ')', '[', ']', '{', '}', "\'"] 

    let str = ""
    for i in range(0, len(a:str)) "TODO convert to substitute regex :(
        let str = index(wchars, a:str[i]) < 0 ?  str . a:str[i] : str
    endfor

    if str == '' | let b:flines=a:items | return | en
    if (g:svnj_fuzzy_search == 1)
        call s:pyMatch(a:items, str, a:limit)
        let b:flines = split(b:slst, "\n")
        unlet! b:slst
    else
       call s:vimMatch(a:items, str, a:limit)
    endif
endf

fun! s:vimMatch(clines, fltr, limit)
    let b:flines = filter(copy(a:clines),
                \ 'strlen(a:fltr) > 0 ? stridx(v:val, a:fltr) >= 0 : 1')
    let s:fregex = ''
endf
"2}}}

"1}}}
