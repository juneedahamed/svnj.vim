" =============================================================================
" File:         autoload/svnj/caop.vim
" Description:  Handle all caching/persistency
" Author:       Juneed Ahamed
" =============================================================================

"Caching ops {{{1
"script vars and init {{{2
let s:bmarks_cache_name = "svnj_bmarks"
let s:commit_log_name = "svnj_commit"
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
    if a:type == "repo" && !g:svnj_browse_repo_cache | retu svnj#passed() | en
    if a:type == "wc" && !g:svnj_browse_workingcopy_cache | retu svnj#passed() | en
    if a:type == "bm" && !g:svnj_browse_bookmarks_cache | retu svnj#passed() | en

    try 
        let fname = svnj#caop#fname(a:path)
        call writefile(a:entries, fname)
        retu svnj#passed()
    catch  | call svnj#utils#dbgMsg("At writecache:", v:exception) | retu svnj#failed()
    finally | call svnj#caop#purge() | endt
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
    retu g:bmarks
endf

fun! svnj#caop#cachebmarks()
    retu svnj#caop#cache("bm", s:bmarks_cache_name, keys(g:bmarks))
endf
"2}}}

"helpers {{{2
fun! svnj#caop#fname(path)
    let path = a:path
    let path = (matchstr(path, "/$") == '') ? (path . '/') : path
    retu g:svnj_cache_dir . "/" . substitute(path, "[\\:|\\/|\\.]", "_", "g") . "svnj_cache.txt"
endf

fun! svnj#caop#cls(path)
    try
        call s:delfile(svnj#caop#fname(a:path), 1)
    catch | call svnj#utils#dbgMsg("At svnj#caop#cls:", v:exception) | endt
endf

fun! s:delfile(fname, forceall)
    try 
        if !a:forceall && (matchstr(a:fname, s:bmarks_cache_name) != "" ||
                    \ matchstr(a:fname, s:commit_log_name) != "" )
            retu svnj#passed() "Donot delete these files unless forced
        endif

        if matchstr(a:fname, "svnj_cache.txt$") != "" 
            call delete(a:fname) | retu svnj#passed()
        endif
    catch | call svnj#utils#dbgMsg("At delfile:", v:exception) | endt
    retu svnj#passed()
endf

fun! svnj#caop#purge()
    try
        if g:svnj_cache_dir == "" || !svnj#utils#isdir(g:svnj_cache_dir) | retu | en
        let files = sort(split(globpath(g:svnj_cache_dir, "*"), "\n"), 'svnj#utils#sortftime')
        let fcnt = len(files)
        if fcnt > g:svnj_browse_cache_max_cnt + 1
            let delfiles = files[ :fcnt - g:svnj_browse_cache_max_cnt - 1]
            call map(delfiles, 's:delfile(v:val, 0)')
        endif
    catch | call svnj#utils#dbgMsg("At svnj#caop#purge:", v:exception) | endt
endf
"2}}}

"clear cache handler ClearAll {{{2
fun! svnj#caop#ClearAll()
    try 
        if g:svnj_cache_dir == "" || !svnj#utils#isdir(g:svnj_cache_dir) | retu | en
        let files = split(globpath(g:svnj_cache_dir, "*"), "\n")
        call map(files, 's:delfile(v:val, 1)')
        call svnj#utils#showConsoleMsg("Cleared cache", 1)
    catch | call svnj#utils#dbgMsg("At svnj#caop#ClearAll:", v:exception) | endt
endf
"2}}}

fun! svnj#caop#commitlog() "{{{2
    retu svnj#utils#isdir(g:svnj_cache_dir) ? 
                \ svnj#caop#fname(s:commit_log_name) : tempname()
endf
"2}}}
"1}}}
