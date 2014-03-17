" =============================================================================
" File:         autoload/winj.vim
" Description:  Simple plugin for svn
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" =============================================================================

"autoload/winj.vim {{{1

"vars "{{{2
let s:jwinname = 'svnj_window'
let s:jwinnr = -1
let s:cdict = {}
let s:winjhi = '%#LineNr#'

let s:svnjhl = "Question"

let s:leave = 0
let s:stay = 1
let s:curops = {}
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
    unlet! s:cdict
    let s:cdict= a:cdict
    silent! exe s:jwinnr . 'wincmd w'
    if has_key(s:cdict, "setup")
        call call(s:cdict.setup, [])
    endif
    call s:populate("")
    call s:prompt("")
endf

fun! s:populate(fltr)
    silent! exe s:jwinnr . 'wincmd w'
    setl modifiable
    exec 'normal! ggdG'
    let linenum = 1
    let cnt = 0
    let scnt = 0
    let lines = []
    let s:theops = {}
    let s:curops = {}
    try
        for thedict in s:cdict.getEntries()
            let[tcnt, tscnt, tlines] = thedict.format(a:fltr)
            let cnt = cnt + tcnt
            let scnt = scnt + tscnt
            call extend(lines, tlines)
            if has_key(thedict, 'ops') && tscnt > 0
                for key in keys(thedict.contents)
                    for opkey in keys(thedict.ops)
                        let subdict = { opkey : thedict.ops[opkey].callback}
                        call extend(s:curops, { opkey : thedict.ops[opkey].descr})
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
        let x = input("Exception at populate")
    endtry
    call setline(1, lines)
    let linenum = linenum + len(lines)

    if s:cdict.hasError()
        call setline(linenum, s:cdict.error.line)
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
                let result = call(cback, [s:cdict, key])
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
                    call s:populate(fltr)
                endif
            elseif chr == "\<Esc>"
                call s:closeMe()
                break
            elseif nr >=# 0x20
                if len(fltr)<=90
                    let fltr = fltr . chr
                    call s:populate(fltr)
                endif
            else
                exec "normal! ". chr
            endif
        catch
            echo v:exception
            let x = input("Exception at prompt")
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
        if len(s:cdict.selectd)
            "let patt = join(copy(keys(s:cdict.selectd)), "\\|")
            "let patt = "/\\(r17\\|r16\\)/"
            "let patt = "/\\(" . patt . "\\)/"

            let patt = join(map(copy(
                        \ keys(s:cdict.selectd)), '"\\<" . v:val . ""' ), "\\|")
            let patt = "/\\(" . patt . "\\)/"
            exec 'match ' . s:svnjhl . ' ' . patt
        endif
    catch
        echo v:exception
        let x = input('Exception at dohighlight')
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
    for [key, descr] in items(s:curops)
        let ops = ops . descr . ' '
    endfor
    if strlen(a:filecount) > 0
        let &l:stl = s:winjhi.s:cdict.title.'%= ' . '%#Search# ' . ops . 
                    \ s:winjhi . ' Entries:' . a:filecount
    else
        let &l:stl = s:winjhi.s:cdict.title.s:winjhi . '%= '. ops .
    endif
    redraws
endf
"2}}}

"1}}}
