" =============================================================================
" File:         autoload/svnj/caop.vim
" Description:  Handle all caching/persistency
" Author:       Juneed Ahamed
" =============================================================================

"script vars and init {{{2
if !exists('g:svnj_glb_init') | let g:svnj_glb_init = svnjglobals#init() | en
let s:bmarks_cache_name = "svnj_bmarks"
"2}}}

" cache read/write {{{2
fun! svnj#caop#fetch(type, path)
    if a:type == "repo" && !g:svnj_browse_repo_cache | retu [0,[]] | en
    if a:type == "wc" && !g:svnj_browse_workingcopy_cache | retu [0,[]] | en

    let fname = svnj#caop#fname(a:path)
    if !filereadable(fname) | retu [0, []] | en
    let lines = readfile(fname)
    retu [1, lines]
endf

fun! svnj#caop#cache(type, path, entries)
    if a:type == "repo" && !g:svnj_browse_repo_cache | retu 1 | en
    if a:type == "wc" && !g:svnj_browse_workingcopy_cache | retu 1 | en
    if a:type == "bm" && !g:svnj_browse_bookmarks_cache | retu 1 | en

    try | call writefile(a:entries, svnj#caop#fname(a:path)) | retu 1
    catch | call svnj#utils#dbgHld("At writecache:", v:exception) | endt
    call svnj#caop#purge()
    retu 0
endf
"2}}}

"bmarks {{{2
fun! svnj#caop#fetchbmarks()
    if !g:svnj_browse_bookmarks_cache | retu g:bmarks | en
    let fname = svnj#caop#fname(s:bmarks_cache_name)
    if filereadable(fname)
        let lines = readfile(fname)
        let g:bmarkssid = 1000
        let g:bmarks = {}
        for line in lines
            let g:bmarkssid += 1
            let g:bmarks[line] = g:bmarkssid
        endfor
    endif
    return g:bmarks
endf

fun! svnj#caop#cachebmarks()
    let lines = []
    for [line, val] in items(g:bmarks)
        call add(lines, line)
    endfor
    retu svnj#caop#cache("bm", s:bmarks_cache_name, lines)
endf
"2}}}

"helpers {{{2
fun! svnj#caop#fname(path)
    let path = a:path
    if matchstr(path, "/$") == ""
        let path = path . "/" 
    endif
    retu g:svnj_cache_dir . "/" . substitute(path, "[\\:|\\/|\\.]", "_", "g") . "svnj_cache.txt"
endf

fun! svnj#caop#cls(path)
    try
        call s:delfile(svnj#caop#fname(a:path))
    catch | call svnj#utils#dbgHld("At svnj#caop#cls:", v:exception) | endt
endf

fun! s:delfile(fname)
    try 
        if matchstr(a:fname, "svnj_cache.txt$") != "" 
            call delete(a:fname) | retu 1
        endif
    catch | call svnj#utils#dbgHld("At delfile:", v:exception) | endt
    retu 0
endf

fun! svnj#caop#purge()
    try
        if g:svnj_cache_dir == "" || !isdirectory(g:svnj_cache_dir) | retu | en
        let files = sort(split(globpath(g:svnj_cache_dir, "*"), "\n"), 'svnj#utils#sortftime')
        let fcnt = len(files)
        if fcnt > g:svnj_browse_cache_max_cnt 
            let delfiles = files[ :fcnt - g:svnj_browse_cache_max_cnt - 1]
            call map(delfiles, 's:delfile(v:val)')
        endif
    catch | call svnj#utils#dbgHld("At svnj#caop#purge:", v:exception) | endt
endf
"2}}}

"clear cache handler ClearAll {{{2
fun! svnj#caop#ClearAll()
    try 
        if g:svnj_cache_dir == "" || !isdirectory(g:svnj_cache_dir) | retu | en
        let files = split(globpath(g:svnj_cache_dir, "*"), "\n")
        call map(files, 's:delfile(v:val)')
        call svnj#utils#showConsoleMsg("Cleared cache", 1)
    catch | call svnj#utils#dbgHld("At svnj#caop#cls:", v:exception) | endt
endf
"2}}}
