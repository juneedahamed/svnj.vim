" =============================================================================
" File:         autoload/winj.vim
" Description:  Simple plugin for svn
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" Credits:      Method pyMatch copied and modified from : Alexey Shevchenko
"               Userid FelikZ/ctrlp-py-matcher from github
" =============================================================================

"autoload/winj.vim {{{1
"vars "{{{2
let s:jwinname = 'svnj_window'
"let [s:winjhi, s:svnjhl] = ['%#LineNr#', "Question"]
let [s:winjhi, s:svnjhl] = [g:svnj_custom_statusbar_title, g:svnj_custom_statusbar_hl]
let [b:clines, b:flines] = [[], []]
let [b:slst,  s:fregex, s:fltr] = ["", "", ""]
let s:ploop = 1
let s:curbufmaps = {}
let s:rez = []
"2}}}

"win handlers {{{2
fun! winj#JWindow()
    let [s:fregex, s:fltr] = ["", ""]
    call s:closeMe()
    noa call s:setup()
endf

fun! s:fakeKeys()
    "let the getchar get a break with a key that is not handled
    if !s:ploop | retu s:promptMsg() | en
    call feedkeys("\<Left>")
    call s:updateStatus()
    redr
endf

fun! s:setup()
    let jwinnr = bufwinnr(s:jwinname)
    silent! exe  jwinnr < 0 ? 'keepa botright 1new ' .
                \ fnameescape(s:jwinname) : jwinnr . 'wincmd w'
    setl nobuflisted
    setl noswapfile nowrap nonumber cul nocuc nomodeline nomore nospell nolist wfh
	setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload
    try
        abc <buffer>
        let s:vim_tm = &tm | let &tm = 0
    catch|endt
    silent! exe 'resize ' . g:svnj_window_max_size 
    let [mstart, mend, menusyntax] = svnj#utils#getMenuSyn()
    let [estart, eend, errsyntax] = svnj#utils#getErrSyn()
    exec errsyntax | exec  menusyntax
    exec 'hi link SVNError ' . g:svnj_custom_error_color
    exec 'hi link SVNMenu ' . g:svnj_custom_menu_color
    
    exec 'syn match SVNHide ' . '/^\s*\d\+\:/'
    exec 'hi SVNHide guifg=bg'
    "exe "highlight SignColumn guibg=black"

	setl bt=nofile bh=unload
    call s:mapdflts()
endf
"2}}}

"closing and bufops {{{2
fun! winj#isploop()
    return s:ploop
endf

fun! winj#close()
    retu s:closeMe()
endf

fun! s:closeMe()
    let jwinnr = bufwinnr(s:jwinname)
    if jwinnr > 0
        silent! exe  jwinnr . 'wincmd w'
        silent! exe  jwinnr . 'wincmd c'
    endif
    try
        if exists('s:vim_tm') | let &tm = s:vim_tm | en
    catch|endt
    echo "" | redr
    return 0
endf

fun! s:startFileOps()
    if s:ploop | retu s:closeMe() | en
    let jwinnr = bufwinnr(s:jwinname)
    if jwinnr > 0
        silent! exe  jwinnr . 'wincmd w'
        let curwin = winnr()
        if curwin == jwinnr
            let altwin = winnr('#')
            silent! exe  altwin . 'wincmd w'
        endif
    endif
    return 0
endf

fun! s:endFileOps(keep)
    let jwinnr = bufwinnr(s:jwinname)
    if jwinnr > 0 && !s:ploop
        silent! exe  jwinnr . 'wincmd w'
        call svnj#select#clear()
        call s:dohighlights()
        call s:updateStatus()
        setl nomodifiable | redr!
        try
            if !a:keep
                let altwin = winnr('#')
                silent! exe  altwin . 'wincmd w'
            endif
        catch | endt
    elseif jwinnr > 0 && s:ploop
        call s:closeMe()
    endif
    return 1
endf
"2}}}

"mappings for buffer {{{2
fun! winj#bufop(...)
    try
        let [key, line] = svnj#utils#extractkey(getline('.'))
        let opsd = s:cdict.getOps(key)
        let chr = s:curbufmaps[a:000[0]][0]
        if len(opsd) > 0 && has_key(opsd, chr)
            let cbret = s:callback(opsd[chr].fn, get(opsd[chr], 'args', []))
            if cbret != 2 | let s:fltr = "" | en
            call s:updateStatus() 
            call call(s:cdict.hasbufops ? "s:promptMsg" : "winj#prompt", [])
        endif
    catch 
        call svnj#utils#dbgHld("At winj#bufop", v:exception)
        call svnj#utils#showErrorConsole("Oops error ")
    endtry
endf

fun! s:mapops()
    call s:unmap()
    let idx = 1
    for [ign, tdict] in items(s:cdict.getAllOps())
        if has_key(tdict, "bop")
            exe 'nn <buffer> <silent> ' . tdict.bop printf(":<c-u>call winj#bufop(%d)<cr>", idx)
            let s:curbufmaps[idx] = [ign, tdict.bop]
            let idx = idx + 1
        endif
    endfor
endf

fun! s:unmap()
    for [key, tlist] in items(s:curbufmaps)
        try 
            exe 'nunmap <buffer> <silent> ' . tlist[1]
        catch | call svnj#utils#dbgHld("unmap", v:exception) | endt
    endfor
    let s:curbufmaps = {}
endf

fun! s:mapdflts()
    autocmd VimResized svnj_window call s:fakeKeys()
    autocmd BufEnter svnj_window call s:fakeKeys()
    exe 'nn <buffer> <silent> <esc>'  ':<c-u>cal winj#close()'.'<cr>'
    exe 'nn <buffer> <silent> <c-s>'  ':<c-u>cal winj#prompt()'.'<cr>'
    for x in range(65, 90) + range(97, 122)
        let tc = nr2char(x)
        exe 'nn <buffer> <silent> ' . tc  ':<c-u>call ' . '<SID>feedkey("' . tc. '")' . '<cr>'
    endfor
    for x in range(0, 9)
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . '<SID>feedkey("' . x. '")' . '<cr>'
    endfor
    for x in [":", "/", "_", "-", "~", "#", "$", "=", "."]
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . '<SID>feedkey("' . x. '")' . '<cr>'
    endfor

    for x in ['(', ')', '\', '*', '+', '[', ']', '{', '}', '&', '@', '`', '?']
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . '<SID>ignore()' . '<cr>'
    endfor

    for x in ['<Down>']
        exe 'nn <buffer> <silent> ' . x ':normal! j <cr> :<c-u>call <SID>promptMsg()<cr>'
    endfor

    for x in ['<Up>']
        exe 'nn <buffer> <silent> ' . x ':normal! k <cr> :<c-u>call <SID>promptMsg()<cr>'
    endfor

    for x in ['<bs>', '<del>']
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . '<SID>delkey()' . '<cr>'
    endfor

    exe 'nn <buffer> <silent> <tab>' ':<c-u>call ' . '<SID>ignore()' . '<cr>'
    exe 'nn <buffer> <silent> <F5> :<c-u>call ' . 'winj#forceredr()' . '<cr>'
    exe 'nn <buffer> <silent> ?  :<c-u>call ' . 'winj#help()' . '<cr>'
endf

fun! winj#forceredr(...)
    redraw!
    if !s:ploop | call s:promptMsg() | en
endf

fun! winj#help(...)
    echohl Directory
    echo " ******* SVNJ Operations ******** "
    echohl Function
    for [key, thedict] in items(s:cdict.getAllOps())
        let [key, val] = split(thedict.dscr, ":")
        echo '         ' . key . ' ' . val
    endfor
    echohl Directory
    echo " ******************************* "
    echohl None | echohl Error
    let x = input("Press Key to continue")
    echohl None
    call s:promptMsg()
endf

fun! s:delkey()
    call s:delpromptchar()
    call s:promptMsg()
endf

fun! s:ignore()
    call s:promptMsg()
endf

fun! s:feedkey(achar)
    if len(s:fltr)<=90
        let s:fltr = s:fltr . a:achar
        call s:repopulate(s:fltr, 1)
    endif
    call s:promptMsg()
endf
"2}}}

"populate {{{2
fun! winj#populateJWindow(cdict)
    try 
        call winj#JWindow()
        let jwinnr = bufwinnr(s:jwinname)
        silent! exe jwinnr . 'wincmd w'
        let s:ploop = !(g:svnj_sticky_on_start && a:cdict.hasbufops)
        let s:ploop = has('gui_running') ? s:ploop : 1
        call winj#populate(a:cdict)
        call call(s:ploop ? "winj#prompt" : "s:promptMsg", [])
    catch | call svnj#utils#dbgHld("populateJWindow", v:exception) | endt
endf

fun! winj#populate(cdict)
    let jwinnr = bufwinnr(s:jwinname)
    silent! exe jwinnr . 'wincmd w'
    let s:cdict = a:cdict
    setl modifiable
    sil! exe '%d _ '
    let linenum = 0
    let b:clines = []

    try
        let [b:clines, displaylines] = s:cdict.lines()
        call s:setline(1, displaylines)
        unlet! displaylines
        call s:mapops()
    catch | call svnj#utils#dbgHld("At populate", v:exception) | endt
    
    let linenum = line('$') == 1 ? 1 : line('$') + 1 
    if s:cdict.hasError()
        call s:setline(linenum, s:cdict.error.line)
    endif

    if linenum == 0 | call s:setNoContents(1) | en
    let s:fregex = ""
    call s:resizewin()
    call s:dohighlights()
    call s:updateStatus()
    setl nomodifiable
endf

fun! s:resizewin()
    let jwinnr = bufwinnr(s:jwinname)
    silent! exe jwinnr . 'wincmd w'
    silent! exe 'resize ' . (line('$') < g:svnj_window_max_size ? line('$') :
                \ g:svnj_window_max_size)
    silent! exe 'normal! gg'
endf

fun! s:setNoContents(linenum)
    call s:setline(a:linenum, '--ERROR--: No contents')
endf

fun! s:repopulate(fltr, incr)
    try
        if len(a:fltr)>= 1 && a:incr && line('$') == 0 | return | endif
        let jwinnr = bufwinnr(s:jwinname)
        silent! exe jwinnr . 'wincmd w'
        setl modifiable  
	    sil! exe '%d _ '
        call s:filterContents(b:clines, a:fltr, g:svnj_fuzzy_search_result_max)

        if len(b:flines) <= 0 | call s:setNoContents(1)
        else | call s:setline(1, b:flines) | en
        unlet! b:flines

        call s:dohighlights()
        call s:resizewin()
        call s:updateStatus()
    catch | call svnj#utils#dbgHld("At repopulate", v:exception) | endt
    setl nomodifiable | redr
endf

"Doing something wrong, need a buffer with undo this just temp until its
"figured out
fun! s:setline(start, lines)
    try | let oul = &undolevels | catch | endt
    try | set undolevels=-1 
    catch | endt
    try | call setline(a:start, a:lines) | catch | endt
    try | exec 'set undolevels=' . oul | catch | endt
endf
"2}}}

"prompt {{{2
fun! winj#hidePrompt(argdict)
    return 10
endf

fun! winj#prompt()
    let s:ploop = 1
    call s:updateStatus()
    while !svnj#doexit()
        try
            call s:promptMsg()
            let nr = getchar()
            let chr = !type(nr) ? nr2char(nr) : nr
            if nr == 32 && s:fltr=="" | cont | en

            if chr == "?" | call winj#help() | cont | en

            let jwinnr = bufwinnr(s:jwinname)
            silent! exe jwinnr . 'wincmd w'
            let [key, line] = svnj#utils#extractkey(getline('.'))
            let opsd = s:cdict.getOps(key)
            if len(opsd) > 0 && has_key(opsd, chr)
                try
                    let cbret = s:callback(opsd[chr].fn, get(opsd[chr], 'args', []))
                    if cbret == 10 
                        redr! | let s:ploop = 0 | call s:updateStatus()
                        call s:promptMsg() | retu
                    endif
                    if cbret != 2 | let s:fltr = "" | en
                    call s:updateStatus() | redr! | cont
                catch 
                    call svnj#utils#dbgHld("At prompt", v:exception)
                    call svnj#utils#showErrorConsole("Oops error ") | cont
                endtry
            endif

            if chr ==# "\<BS>" || chr ==# '\<Del>'
                call s:delpromptchar()
            elseif chr == "\<Esc>"
                call svnj#prepexit()
                call s:closeMe() | break
            elseif nr >=# 0x20
                if len(s:fltr)<=90
                    let s:fltr = s:fltr . chr
                    call s:repopulate(s:fltr, 1)
                endif
            else | exec "normal!" . chr
            endif
        catch | call svnj#utils#dbgHld("At prompt", v:exception) | endt
    endwhile
    exe 'echo ""' |  redr
    call s:closeMe()
endf

fun! s:delpromptchar()
    if len(s:fltr) <= 0 | retu | en
    let s:fltr = s:fltr[:-2]
    call s:repopulate(s:fltr, 0)
endf

fun! s:promptMsg()
    redr | exec 'echohl ' . g:svnj_custom_prompt_color
    echon "filter :" | echohl None | echon s:fltr | echon s:ploop ? "" : "_"
endf

fun! s:callback(cbfn, optargs)
    let jwinnr = bufwinnr(s:jwinname)
    silent! exe jwinnr . 'wincmd w'
    let [key, line] = svnj#utils#extractkey(getline('.'))
    let result = 0
    try
        let argdict = { 
                    \ "dict" : s:cdict,
                    \ "key"  : key,
                    \ "line" : line,
                    \ "opt"  : a:optargs,
                    \ }
        let result = call(a:cbfn, [argdict]) 
    catch 
        call svnj#utils#dbgHld("At s:callbac", v:exception)
        call svnj#utils#showErrorConsole("Oops error ")
    endtry
    retu result
endf
"2}}}

"highlight {{{2
fun! s:dohighlights()
     try
        let jwinnr = bufwinnr(s:jwinname)
        silent! exe jwinnr . 'wincmd w'
        call clearmatches()

        if s:fregex != "" 
            let ignchars = "[\\(\\)\\<\\>\\{\\}\\\]"
            let s:fregex = substitute(s:fregex, ignchars, "", "g")
            try | call matchadd(g:svnj_custom_fuzzy_match_hl, '\v\c' . s:fregex)
            catch | endtry
        endif

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
    setlocal scrollbind nowrap nofoldenable 
    call s:closeMe()
    let filetype=&ft
    let cmd="%!svn blame " . fnameescape(a:filepath)
    let newfile = 'keepalt vnew '
    exec newfile | exec cmd
    exe "setl bt=nofile bh=wipe nobl noswf nowrap ro ft=" . filetype
    setlocal scrollbind nowrap nofoldenable
    return 0
endf

fun! winj#diffFile(revision, svnurl)
    call s:startFileOps()
    let filetype=&ft
    let revision = len(a:revision) > 0 ? " -" . a:revision : ""
    if a:revision == "" && filereadable(svnj#utils#expand(fnameescape(a:svnurl)))
        let cmd = "%!cat " . fnameescape(a:svnurl)
        let fname =  svnj#utils#strip(a:svnurl)
    else
        let cmd = "%!svn cat " . revision . ' '. fnameescape(a:svnurl)
        let fname =  svnj#utils#strip(a:revision)."_".svnj#utils#strip(a:svnurl)
    endif
    diffthis | exec 'vnew! ' fnameescape(fname) 
    exec cmd |  diffthis
    exe 'silent! com! GoSVNJ call svnj#home()'
    exe 'map <buffer> <silent> <c-q>' '<esc>:diffoff!<cr> :bd!<cr>:GoSVNJ<cr>'
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype
    let &l:stl = fname
    retu s:endFileOps(0)
endf

fun! winj#openVS(revision, url)
    call s:startFileOps()
    let [revision, fname] = s:rev_fname(a:revision, a:url)
    if filereadable(svnj#utils#expand(fname))
        silent! exe 'vsplit ' fnameescape(fname)
    else
        let cmd="%!svn cat " . revision . ' ' . fnameescape(a:url)
        silent! exe 'vsplit ' fnameescape(fname) | exe cmd 
        exe "setl bt=nofile"
    endif
    retu s:endFileOps(1)
endf


fun! winj#newBufOpen(revision, url)
    call s:startFileOps()
    try
        let [revision, fname] = s:rev_fname(a:revision, a:url)
        if filereadable(svnj#utils#expand(fname))
            silent! exe 'e ' fnameescape(fname)
        else
            let cmd="%!svn cat " . revision . ' ' . fnameescape(a:url)
            silent! exe 'e ' fnameescape(fname) | exe cmd 
            exe "setl bt=nofile"
        endif
    catch | endtry
    retu s:endFileOps(1)
endf

fun! s:rev_fname(revision, url)
    let revision = a:revision == "" ? "" : " -" .  a:revision 
    let fname = a:revision == "" ? a:url : a:revision . '_' . 
                \ svnj#utils#strip(a:url)
    return [revision, fname]
endf
"2}}}

"stl update {{{2
fu! s:updateStatus()
    try
        echo " "
        let selcnt = len(svnj#select#dict()) > 0 ? 
                    \ 's['. len(svnj#select#dict()) . ']' : ''
        let opsdsc = g:svnj_custom_statusbar_ops_hide ? ' ' :
                    \ ' %#'.g:svnj_custom_statusbar_ops_hl.'# ' . s:cdict.opdsc

        if opsdsc == ' ' | let opsdsc = ' %#'.g:svnj_custom_statusbar_ops_hl.'# ' 
                    \ . "?:Help " | en
        let title = s:winjhi.s:cdict.title 
        let alignright = '%='
        let selcnt = '%#' . g:svnj_custom_statusbar_sel_hl . '#' . selcnt
        let sticky = s:ploop ? "" : '%#' . g:svnj_custom_sticky_hl .'#' . "STICKY "
        let entries = s:winjhi . ' [' . '%L/' . len(b:clines) . ']'
        let &l:stl = title.alignright.opsdsc.sticky.selcnt.entries
    catch
        "call svnj#utils#dbgHld("At updateStatus", v:exception)
    endtry
    redraws
endf
"2}}}

"python filterContents "{{{2
fun! s:filterContents(items, str, limit)
    let b:flines = []
    let s:fregex = ""
    "TODO ignoring until i learn how to tackle this, move on for now REVISIT
    "let ignchars = "[\+|\\*|\\|\\~|\\@|\\%|\\(|\\)|\\[|\\]|\\{|\\}|\\']"
    let ignchars = "[\\+\\*\\\\~\\@\\%\\(\\)\\[\\]\\{\\}\\'\\&]"
    let str = substitute(a:str, ignchars, "", "g")
    "let str = escape(a:str, ignchars)
    let str = substitute(str, "\\.\\+", "", "g")
    if str == '' | let b:flines=a:items | return | en

    if (g:svnj_fuzzy_search == 1)
        if has('python') && !g:svnj_fuzzy_vim
            call s:pyMatch(a:items, str, a:limit)
            if len(s:rez) > 0
                let b:flines = s:rez[ : g:svnj_max_buf_lines]
                unlet! s:rez
                let s:rez = []
            else
                "for older vim versions not supporting bind
                let b:flines = split(b:slst, "\n")
                let b:flines = b:flines[ : g:svnj_max_buf_lines]
                unlet! b:slst
            endif
        else
            try | call s:vimMatch(a:items, str, a:limit) 
            catch | call s:vimMatch_old(a:items, str, a:limit) | endt
        endif
    else
        call s:vimMatch_old(a:items, str, a:limit)
    endif
endf

fun! s:pyMatch(items, str, limit)
python << EOF
import vim, re
import traceback
vim.command("let b:slst = ''")
items = vim.eval('a:items')
astr = vim.eval('a:str')
lowAstr = astr.lower()
limit = int(vim.eval('a:limit'))
hasbind = True
try:
    #Oops supported after 7.3+ or something
    rez = vim.bindeval('s:rez')
except:
    hasbind = False
    pass

regex = ''
fregex = ''
for c in lowAstr[:-1]:
    regex += c + '[^' + c + ']*?'
    fregex += c + '[^' + c + ']*'
else:
    regex += lowAstr[-1]
    fregex += lowAstr[-1]

try:
    matches = []
    res = []
    prog = re.compile(regex)
    for line in items:
        lowline = line.lower()
        result = prog.findall(lowline)
        if result:
            result = result[-1]
            mstart = lowline.rfind(result)
            mend = mstart + len(result)
            mlen = mend - mstart
            score = len(line) * (mlen)
            res.append((score, line, result))

    sortedlist = sorted(res, key=lambda x: x[0], reverse=False)[:limit]
    sortedlines = [x[1] for x in sortedlist]

    try:
        if not hasbind:
            result = "\n".join(sortedlines) 
            p = re.compile('\'|\"')
            result = p.sub("", result)
            vim.command("let b:slst = \'%s\'" % result)
        else:
            rez.extend(sortedlines)

        vim.command("let s:fregex = \'%s\'" % fregex)
    except:
        pass
except:
    pass

del sortedlist
del sortedlines
del res
del result
del items
EOF
endf

fun! s:vimMatch(clines, fltr, limit)
    let s:fregex = ""
    let ranked = {}
    for idx in range(0, len(a:fltr)-2)
        let s:fregex = s:fregex . a:fltr[idx]  . '[^'  . a:fltr[idx]  . ']*'
    endfor
    let s:fregex = s:fregex . a:fltr[len(a:fltr)-1]
    let s:fregex = '\v\c'.s:fregex
    for line in a:clines
        let matched = matchstr(line, s:fregex)
        if len(matched)
            let mstart = match(line, s:fregex)
            let mend = mstart + len(matched)
            let score = len(line) * (mend - mstart + 1)
            let rlines = get(ranked, score, [])
            call add(rlines, line)
            let ranked[score] = rlines
        endif
    endfor
    let b:flines = []
    for key in sort(keys(ranked), 'svnj#utils#sortConvInt')
        call extend(b:flines, ranked[key])
    endfor
    let b:flines = b:flines[:a:limit]
    unlet! ranked
endf

fun! s:vimMatch_old(clines, fltr, limit)
    let b:flines = filter(copy(a:clines),
                \ 'strlen(a:fltr) > 0 ? stridx(v:val, a:fltr) >= 0 : 1')
    let b:flines = b:flines[ : g:svnj_max_buf_lines]
    let s:fregex = ""
endf
"2}}}

"1}}}
