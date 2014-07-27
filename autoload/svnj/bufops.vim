" ============================================================================
" File:         autoload/svnj/bufops
" Description:  Buffer mapping/operations for svnj_window
" Author:       Juneed Ahamed
" =============================================================================

"Buffer Mappings {{{1
fun! svnj#bufops#dflts() "{{{2
    autocmd VimResized svnj_window call s:fakeKeys()
    autocmd BufEnter svnj_window call s:fakeKeys()

    exe 'nn <buffer> <silent> <esc>'  ':<c-u>cal winj#close()'.'<cr>'
    exe 'nn <buffer> <silent> <c-s>'  ':<c-u>cal svnj#prompt#loop()'.'<cr>'

    for x in range(65, 90) + range(97, 122)
        let tc = nr2char(x)
        exe 'nn <buffer> <silent> ' . tc  ':<c-u>call ' . 'svnj#prompt#append("' . tc. '")' . '<cr>'
    endfor

    for x in range(0, 9)
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'svnj#prompt#append("' . x. '")' . '<cr>'
    endfor

    for x in [":", "/", "_", "-", "~", "#", "$", "=", "."]
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'svnj#prompt#append("' . x. '")' . '<cr>'
    endfor

    for x in ['(', ')', '\', '*', '+', '[', ']', '{', '}', '&', '@', '`', '?']
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'svnj#prompt#show()' . '<cr>'
    endfor

    for x in ['<Down>']
        exe 'nn <buffer> <silent> ' . x ':normal! j <cr> :<c-u>call svnj#prompt#show()<cr>'
    endfor

    for x in ['<Up>']
        exe 'nn <buffer> <silent> ' . x ':normal! k <cr> :<c-u>call svnj#prompt#show()<cr>'
    endfor

    for x in ['<bs>', '<del>']
        exe 'nn <buffer> <silent> ' . x  ':<c-u>call ' . 'svnj#prompt#del()' . '<cr>'
    endfor

    exe 'nn <buffer> <silent> <tab>' ':<c-u>call ' . 'svnj#prompt#show()' . '<cr>'
    exe 'nn <buffer> <silent> <F5> :<c-u>call ' . 'svnj#act#forceredr()' . '<cr>'
    exe 'nn <buffer> <silent> ?  :<c-u>call ' . 'svnj#act#help()' . '<cr>'
endf
"2}}}

fun! svnj#bufops#map(cdict) "{{{2
    let s:cdict = a:cdict
    let s:curbufmaps = {}

    call s:unmap()
    let idx = 1
    for [ign, tdict] in items(s:cdict.getAllOps())
        if has_key(tdict, "bop")
            exe 'nn <buffer> <silent> ' . tdict.bop printf(":<c-u>call svnj#bufops#op(%d)<cr>", idx)
            let s:curbufmaps[idx] = [ign, tdict.bop]
            let idx = idx + 1
        endif
    endfor
endf
"2}}}

fun! svnj#bufops#op(...) "{{{2
    try
        let [key, line] = svnj#utils#extractkey(getline('.'))
        let opsd = s:cdict.getOps(key)
        let chr = s:curbufmaps[a:000[0]][0]
        if len(opsd) > 0 && has_key(opsd, chr)
            let cbret = svnj#prompt#cb(opsd[chr].fn, get(opsd[chr], 'args', []))
            if cbret == svnj#fltrclearandexit() | call winj#close() | retu | en  "Feed esc example commit
            if cbret != svnj#nofltrclear() | call svnj#prompt#clear() | en
            call winj#stl() 
            call call(s:cdict.hasbufops ? "svnj#prompt#show" : "svnj#prompt#loop", [])
        endif
    catch 
        call svnj#utils#showerr("Oops error " . v:exception)
    endtry
endf
"2}}}

fun! s:fakeKeys() "{{{2
    "let the getchar get a break with a key that is not handled
    if !svnj#prompt#isploop() | retu svnj#prompt#show() | en
    call feedkeys("\<Left>")
    call winj#stl()
    redr
endf
"2}}}

fun! s:unmap() "{{{2
    for [key, tlist] in items(s:curbufmaps)
        try 
            exe 'nunmap <buffer> <silent> ' . tlist[1]
        catch 
            call svnj#utils#dbgHld("unmap", v:exception)
        endtry
    endfor
    let s:curbufmaps = {}
endf
"2}}}
"1}}}
