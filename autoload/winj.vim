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
"
"vars "{{{2
let s:jwinname = 'svnj_window'
let s:jwinnr = -1
let [s:winjhi, s:svnjhl] = ['%#LineNr#', "Question"]

let [s:leave, s:stay] = [0, 1]
let [b:curops, b:cdict] = [{}, {}]
let [b:clines, b:flines] = [[], []]
let [b:slst,  s:fregex] = ["", ""]
"2}}}

"win handlers {{{2
fun! winj#JWindow()
    call s:closeMe()
    let s:jwinnr = bufwinnr(s:jwinname)
    silent! exe  s:jwinnr < 0 ? 'botright new ' .
                \ fnameescape(s:jwinname) : s:jwinnr . 'wincmd w'
    setl buftype=nowrite bufhidden=wipe nobuflisted
    setl noswapfile nowrap nonumber cul nomodeline nomore nospell
    autocmd VimResized svnj_window call s:fakeKeys()
    let s:jwinnr = bufwinnr(s:jwinname)
endf

fun! s:fakeKeys()
    "let the getchar get a break with a key that is
    "not handled
    call feedkeys("\<Left>")
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
    call winj#JWindow()
    unlet! b:cdict
    let b:cdict= a:cdict
    silent! exe s:jwinnr . 'wincmd w'
    if has_key(b:cdict, "setup")
        call call(b:cdict.setup, [])
    endif
    call s:populate("")
    call s:prompt("")
endf

fun! s:populate(fltr)
    silent! exe s:jwinnr . 'wincmd w'
    setl modifiable
    exec 'normal! ggdG'
    let linenum = 1
    let [cnt, scnt] = [0, 0]
    let [s:theops, b:curops] = [{}, {}]
    let b:clines = []

    try
        for thedict in b:cdict.getEntries()
            let[tcnt, tscnt, tlines] = thedict.format(a:fltr)
            let cnt = cnt + tcnt
            let scnt = scnt + tscnt
            call extend(b:clines, tlines)
            if has_key(thedict, 'ops') && tscnt > 0
                for key in keys(thedict.contents)
                    for opkey in keys(thedict.ops)
                        let subdict = { opkey : thedict.ops[opkey].callback}
                        call extend(b:curops, { opkey : thedict.ops[opkey].descr})
                        if has_key(s:theops, key)
                            call extend(s:theops[key], subdict)
                        else
                            let s:theops[key] = subdict
                        endif
                    endfor
                endfor
            endif
        endfor
    catch
        echo v:exception
    endtry
    call setline(1, b:clines)
    let linenum = linenum + len(b:clines)

    if b:cdict.hasError()
        call setline(linenum, b:cdict.error.line)
        let linenum = linenum + 1
    endif
    if linenum ==# 1
        call setline(linenum, '--ERROR-- No contents')
    endif
    silent! exe 'resize ' . line('$')
    call s:updateStatus((scnt) . '/'. cnt)
    setl nomodifiable
    redr!
endf

fun! s:repopulate(fltr)
    call clearmatches()
    silent! exe s:jwinnr . 'wincmd w'
    setl modifiable
    exec 'normal! ggdG'
    let tcnt = len(b:clines)
    try
        "let flines = filter(copy(b:clines),
        "            \ 'strlen(a:fltr) > 0 ? stridx(v:val, a:fltr) >= 0 : 1')
        call s:filterContents(b:clines, a:fltr, g:svnj_fuzzy_search_result_max)
        if len(b:flines) <= 0
            call setline(1, '--ERROR-- No contents')
        else
            call setline(1, b:flines)
        endif
        call s:dohighlights(a:fltr)

        silent! exe 'resize ' . line('$')
        call s:updateStatus(len(b:flines) . '/'. tcnt)
        let b:flines = []
    catch
        echo v:exception
        let x = input("At repopulate")
    endtry
    setl nomod
    redr!
endf
"2}}}

"prompt {{{2
fun! s:prompt(fltr)
    let fltr = a:fltr
    while 1
        try
            redr
            echohl Title | echon "filter : " | echohl None | echon fltr
            let nr = getchar()
            let chr = !type(nr) ? nr2char(nr) : nr


            call s:dohighlights(fltr)
            let curbufname = bufname("%")
            if s:jwinname !=# curbufname
                call s:closeMe()
                break
            endif

            let cline = getline('.')
            let key = split(cline, ':')[0]

            let opsd = get(s:theops, key, {})
            if len(opsd) > 0 && has_key(opsd, chr)
                let cback = opsd[chr]
                let result = call(cback, [b:cdict, key])
                if result == 0
                    break
                elseif result == 1
                    call s:dohighlights(fltr)
                    continue
                elseif result == 2
                    redr!
                    continue
                endif
            endif

            if chr ==# "\<BS>" || chr ==# '\<Del>'
                if strlen(fltr) > 0
                    let fltr = strpart(fltr, 0, strlen(fltr) - 1)
                    call s:repopulate(fltr)
                endif
            elseif chr == "\<Esc>"
                call s:closeMe()
                break
            elseif nr >=# 0x20
                if len(fltr)<=90
                    let fltr = fltr . chr
                    call s:repopulate(fltr)
                endif
            else
                exec "normal! ". chr
            endif
        catch
            echo v:exception
        endtry
    endwhile
    exe 'echo ""' |  redr
endf
"2}}}

"highlight {{{2
fun! s:dohighlights(fltr)
     try
        silent! exe s:jwinnr . 'wincmd w'
        call clearmatches()
        if len(b:cdict.selectd)
            let patt = join(map(copy(
                        \ keys(b:cdict.selectd)), '"\\<" . v:val . ""' ), "\\|")
            let patt = "/\\(" . patt . "\\)/"
            exec 'match ' . s:svnjhl . ' ' . patt
        endif
        
        if s:fregex != ""    
            call matchadd('Directory', '\v\c' . s:fregex)
        endif
    catch
        echo v:exception
    endtry
endf
"2}}}

"open funs {{{2
fun! winj#diffCurFileWith(revision, svnurl)
    call s:closeMe()
    let filetype=&ft
    let revision = ""
    if len(a:revision) > 0
        let revision = " -" . a:revision
    endif
    let cmd = "%!svn cat " . revision . ' '. a:svnurl
    diffthis | exec 'vnew '. a:revision | exec cmd |  diffthis
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype
    return 0
endf

fun! winj#blame(svnurl, filepath)
    call s:closeMe()
    let filetype=&ft
    if a:filepath !=# ''
        let cmd="%!svn blame " . a:filepath
    endif
    let newfile = 'vnew '
    exec newfile | exec cmd
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype
    return 0
endf

fun! winj#openGivenFile(thefile)
    silent! call s:closeMe()
    if filereadable(a:thefile) || isdirectory(a:thefile)
        silent! exe 'e' a:thefile
        return s:leave
    endif
    return s:leave
endf

fun! winj#openFileRevision(revision, url)
    call s:closeMe()
    let filetype=&ft
    let cmd="%!svn cat -" . a:revision . ' ' . a:url
    let new_tab = ' e ' . a:revision
    exec new_tab | exec cmd
    exe "setl nomod noswf ft=" . filetype
    return s:leave
endf

fun! winj#openFile(revision, url)
    call s:closeMe()
    let filetype=&ft
    let cmd="%!svn cat -" . a:revision . ' ' . a:url
    let new_file = 'vnew '. a:revision
    exec new_file | exec cmd
    exe "setl bt=nofile bh=wipe nobl noswf ro ft=" . filetype
    return s:leave
endf
"2}}}

"stl update {{{2
fu! s:updateStatus(filecount)
    echo " "
    let ops=""
    for [key, descr] in items(b:curops)
        let ops = ops . descr . ' '
    endfor
    if strlen(a:filecount) > 0
        let &l:stl = s:winjhi.b:cdict.title.'%= ' . '%#Search# ' . ops . 
                    \ s:winjhi . ' Entries:' . a:filecount
    else
        let &l:stl = s:winjhi.b:cdict.title.s:winjhi . '%= '. ops .
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
    for i in range(0, len(a:str))
        if index(wchars, a:str[i]) < 0 
            let str = str . a:str[i]
        endif
    endfor

    if str == ''
        let b:flines=a:items
        return
    endif

    if (g:svnj_fuzzy_search == 1) && has('python') 
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
