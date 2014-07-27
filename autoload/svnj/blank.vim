"===============================================================================
" File:         autoload/svnj/blank.vim
" Description:  SVNJ Blank window used by SVNAdd, SVNCommit, svn cp
" Author:       Juneed Ahamed
"===============================================================================

"svnj#blank.vim {{{1
let s:bwinname = 'svnj_bwindow'
let s:ops = {}

fun! svnj#blank#win(cmdsdict) "{{{2
    let s:ops = {}
    call winj#close()
    call svnj#blank#closeMe()
    noa call s:setup(a:cmdsdict)
endf
"2}}}

fun! s:setup(cmdsdict) "{{{2
    let jwinnr = bufwinnr(s:bwinname)
    silent! exe  jwinnr < 0 ? 'keepa botright 1new ' .
                \ fnameescape(s:bwinname) : jwinnr . 'wincmd w'
    setl nobuflisted noswapfile nowrap nonumber nocuc nomodeline nomore nolist wfh
	setl tw=0 bt=nofile bh=unload
    silent! exe 'resize ' . g:svnj_window_max_size 
    let idx = 0
    for [key, value] in items(a:cmdsdict)
        let idx += 1
        let s:ops[idx] = value
        exe 'nn <buffer> <silent>' key ":<c-u>call svnj#blank#callback(".idx.")<CR>"
    endfor
    
    exec 'syn match SVNJ /^SVNJ\:.*/'
    exec 'hi link SVNJ ' . g:svnj_custom_commit_header_hl

    exe 'syn match CommitFiles /^SVNJ\:+.*/'
    exec 'hi link CommitFiles ' . g:svnj_custom_commit_files_hl

    exe 'syn match CommitFiles /^SVNJ\:SOURCE\:.*/'
    exec 'hi link CommitFiles ' . g:svnj_custom_commit_files_hl

    exe 'syn match CommitFiles /^SVNJ\:DESTINATION\:.*/'
    exec 'hi link CommitFiles ' . g:svnj_custom_commit_files_hl
endf
"2}}}

fun! svnj#blank#callback(idx) "{{{2
    if has_key(s:ops, a:idx) 
        let cbdict = s:ops[a:idx]
        call call(cbdict.fn, [])
    endif
endf
"2}}}

fun! svnj#blank#closeMe(...) "{{{2
    let jwinnr = bufwinnr(s:bwinname)
    if jwinnr > 0
        silent! exe  jwinnr . 'wincmd w'
        silent! exe  jwinnr . 'wincmd c'
    endif
    echo "" | redr
    retu svnj#passed()
endf
"2}}}

"1}}}
