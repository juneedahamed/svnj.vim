" ============================================================================
" File:         autoload/svnj/syntax.vim
" Description:  Syntax and highlights for svnj_window
" Author:       Juneed Ahamed
" =============================================================================

" syntax build and hl {{{1

fun! svnj#syntax#build() "{{{2
    setl nobuflisted
    setl noswapfile nowrap nonumber cul nocuc nomodeline nomore nospell nolist wfh
	setl fdc=0 fdl=99 tw=0 bt=nofile bh=unload

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
    abc <buffer>
endf
"2}}}

"highlight {{{2
fun! svnj#syntax#highlight()
     try
        call svnj#home()
        call clearmatches()

        let regex = winj#regex()
        if regex != "" 
            let ignchars = "[\\(\\)\\<\\>\\{\\}\\\]"
            let regex = substitute(regex, ignchars, "", "g")
            try 
                call matchadd(g:svnj_custom_fuzzy_match_hl, '\v\c' . regex)
            catch 
                call svnj#utils#dbgMsg("At highlight matchadd", v:exception)
            endtry
        endif

        if len(svnj#select#dict()) && !g:svnj_signs
            let patt = join(map(copy(keys(svnj#select#dict())),
                        \ '"\\<" . v:val . ": " . ""' ), "\\|")
            let patt = "/\\(" . patt . "\\)/"
            exec 'match ' . s:svnjhl . ' ' . patt
        endif

        call svnj#select#resign(winj#dict())

    catch 
        call svnj#utils#dbgMsg("At highlight", v:exception)
    endtry
endf

fun! s:dohicurline()
    try
        let key = matchstr(getline('.'), g:svnj_key_patt)
        if key != "" | call matchadd('Directory', '\v\c^' . key) | en
    catch 
        call svnj#utils#dbgMsg("At dohicurline", v:exception) 
    endtry
endf
"2}}}
"1}}}
