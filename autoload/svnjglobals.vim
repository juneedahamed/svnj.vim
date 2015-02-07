" =============================================================================
" File:         autoload/svnjglobals.vim
" Description:  Handle all globals
" Author:       Juneed Ahamed
" =============================================================================

"global vars {{{2
"start init {{{3
fun! svnjglobals#init()
    try| call s:auth() | catch | endt
    try| call s:custom() | catch | endt
    try| call s:customize() | catch | endt
    try| call s:cache() | catch | endt
    try| call s:signs() | catch | endt
    try| call s:ignores() | catch | endt
    try| call s:fuzzy() | catch | endt
    try| call s:urls() | catch | endt
    
    let g:svnj_key_patt = '\v\c\d+:'
    "g:bmarks = { filepath : id }
    let g:bmarks = {}
    let g:bmarkssid = 1000
    
    return 1
endf
"3}}}

"auth info {{{3
fun! s:auth()
    let g:svnj_username = get(g:, 'svnj_username', "") 
    let g:svnj_password = get(g:, 'svnj_password', "") 
    let g:svnj_auth_errno = get(g:, 'svnj_auth_errno', "E170001") 
    let g:svnj_auth_errmsg = get(g:, 'svnj_auth_errmsg', '\cusername\|\cpassword') 
    let g:svnj_auth_disable = get(g:, 'svnj_auth_disable', 0) 
endf
"3}}}

"custom gvars {{{3
fun! s:custom()
    let g:svnj_max_logs = get(g:, 'svnj_max_logs', 50)
    let g:svnj_max_open_files = get(g:, 'svnj_max_open_files', 10)
    let g:svnj_max_diff = get(g:, 'svnj_max_diff', 2)
    let g:svnj_max_buf_lines = get(g:, 'svnj_max_buf_lines', 80)
    let g:svnj_window_max_size = get(g:, 'svnj_window_max_size', 20)
    let g:svnj_warn_branch_log = get(g:, 'svnj_warn_branch_log', 1)
    let g:svnj_enable_debug = get(g:, 'svnj_enable_debug', 0)
    let g:svnj_enable_extended_debug = get(g:, 'svnj_enable_extended_debug', 0)
    let g:svnj_browse_max_files_cnt= get(g:, 'svnj_browse_max_files_cnt', 10000)
    let g:svnj_browse_repo_max_files_cnt= get(g:, 'svnj_browse_repo_max_files_cnt', 1000)
    let g:svnj_sticky_on_start = get(g:, 'svnj_sticky_on_start', 0)
    let g:svnj_send_soc_command = get(g:, 'svnj_send_soc_command', 1)
endf
"3}}}

"customize gvars {{{3
fun! s:customize() 
    fun! s:get_hl(varname, defval)
        retu !exists(a:varname) || !hlexists(eval(a:varname)) ? a:defval : eval(a:varname)
    endf

    let g:svnj_custom_fuzzy_match_hl = s:get_hl('g:svnj_custom_fuzzy_match_hl', 'Directory')
    let g:svnj_custom_menu_color = s:get_hl('g:svnj_custom_menu_color', 'MoreMsg')
    let g:svnj_custom_error_color = s:get_hl('g:svnj_custom_error_color', 'Error')
    let g:svnj_custom_prompt_color = s:get_hl('g:svnj_custom_prompt_color', 'Title')
    let g:svnj_custom_statusbar_hl = s:get_hl('g:svnj_custom_statusbar_hl', 'Question')
    let g:svnj_custom_statusbar_title = s:get_hl('g:svnj_custom_statusbar_title', 'LineNr')
    let g:svnj_custom_statusbar_title = '%#' . g:svnj_custom_statusbar_title .'#'
    let g:svnj_custom_statusbar_ops_hl = s:get_hl('g:svnj_custom_statusbar_ops_hl', 'Search')
    let g:svnj_custom_statusbar_sel_hl = s:get_hl('g:svnj_custom_statusbar_sel_hl', 'Question')
    let g:svnj_custom_statusbar_ops_hide = get(g:, 'svnj_custom_statusbar_ops_hide', 1)
    let g:svnj_custom_sticky_hl = s:get_hl('g:svnj_custom_sticky_hl', 'Function')
    let g:svnj_custom_commit_files_hl = s:get_hl('g:svnj_custom_commit_files_hl', 'Directory')
    let g:svnj_custom_commit_header_hl = s:get_hl('g:svnj_custom_commit_header_hl', 'Comment')
endf
"3}}}
    
"cache gvars {{{3
fun! s:cache()
    fun! s:createdir(dirpath)
        if isdirectory(a:dirpath) | retu 1 | en
        if filereadable(a:dirpath) 
            retu s:showerr("Error " . a:dirpath . 
                        \ " already exist as a file expecting a directory")
        endif
        if exists("*mkdir")
            try | call mkdir(a:dirpath, "p")
            catch
                retu s:showerr("Error creating cache dir: " .
                            \ a:dirpath . " " .  v:exception)
            endtry
        endif
        return 1
    endf

    let g:svnj_browse_cache_all = get(g:, 'svnj_browse_cache_all', 0)
    let g:svnj_browse_bookmarks_cache = get(g:, 'svnj_browse_bookmarks_cache', 0)
    let g:svnj_browse_repo_cache = get(g:, 'svnj_browse_repo_cache', 0)
    let g:svnj_browse_workingcopy_cache = get(g:, 'svnj_browse_workingcopy_cache', 0)
    let g:svnj_browse_cache_max_cnt = get(g:, 'svnj_browse_cache_max_cnt', 20)

    let g:svnj_cache_dir = get(g:, 'svnj_cache_dir',
			    \ !has('win32') ? expand($HOME . "/" . ".cache") : "")

    "Create top dir
    if !s:createdir(g:svnj_cache_dir) | let g:svnj_cache_dir = "" | en
    let g:svnj_cache_dir = isdirectory(g:svnj_cache_dir) ? g:svnj_cache_dir . "/svnj" : ""
    "Create cache dir
    if g:svnj_cache_dir != "" && !s:createdir(g:svnj_cache_dir) 
        let g:svnj_cache_dir = ""
    endif

    let isdir = isdirectory(g:svnj_cache_dir)
    let g:svnj_browse_repo_cache = isdir && (g:svnj_browse_repo_cache || g:svnj_browse_cache_all)
    let g:svnj_browse_workingcopy_cache = isdir &&
                \ (g:svnj_browse_workingcopy_cache || g:svnj_browse_cache_all)
    let g:svnj_browse_bookmarks_cache = isdir &&
                \ (g:svnj_browse_bookmarks_cache || g:svnj_browse_cache_all)
    let g:svnj_logversions = []
endf
"3}}}

"signs gvars {{{3
fun! s:signs()
    if !exists('g:svnj_signs') | let g:svnj_signs = 1 | en
    if !has('signs') | let g:svnj_signs = 0 | en

    if g:svnj_signs | sign define svnjmark text=s> texthl=Question linehl=Question
    en
    if g:svnj_signs | sign define svnjbook text=b> texthl=Constant linehl=Constant
    en
endf
"3}}}

"ignore gvars{{{3
fun! s:ignores()
    let ign_files = ['\.bin', '\.zip', '\.bz2', '\.tar', '\.gz', 
                \ '\.egg', '\.pyc', '\.so', '\.git',
                \ '\.png', '\.gif', '\.jpg', '\.ico', '\.bmp', 
                \ '\.psd', '\.pdf']

    if exists('g:svnj_ignore_files') && type(g:svnj_ignore_files) == type([])
        for ig in g:svnj_ignore_files | call add(ign_files, ig) | endfor
    endif
    let g:p_ign_fpat = '\v('. join(ign_files, '|') .')'
endf
"3}}}

" fuzzy gvars {{{3
fun! s:fuzzy()
    let g:svnj_fuzzy_search = (!exists('g:svnj_fuzzy_search')) ||
                \ type(eval('g:svnj_fuzzy_search')) != type(0) ?
                \ 1 : eval('g:svnj_fuzzy_search')
    
    let g:svnj_fuzzy_search_result_max = (!exists('g:svnj_fuzzy_search_result_max'))  || 
                \ type(eval('g:svnj_fuzzy_search_result_max')) != type(0) ? 
                \ 100 : eval('g:svnj_fuzzy_search_result_max')

    let g:svnj_fuzzy_vim = get(g:, 'svnj_fuzzy_vim', 0) 
    "if g:svnj_fuzzy_search && !g:svnj_fuzzy_vim && v:version < 704 
    "    let g:svnj_fuzzy_vim = 0
    "endif
endf
"3}}}

fun! s:strip(input_string) "{{{3
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf
"3}}}

"urls {{{3
fun! s:urls()
    fun! s:initPathVariables(pathvar)
        return exists(a:pathvar) ? s:stripAddSlash(eval(a:pathvar)) : ''
    endf

    fun! s:stripAddSlash(var)
        let val = s:strip(a:var)
        if len(val) > 0 && val[len(val)-1] != '/'
            return val . '/'
        elseif len(val) > 0 | retu val | en
    endf

    fun! s:makelst(varname)
        if !exists(a:varname) | retu [] | en
        if type(eval(a:varname)) == type("")
            retu map(split(eval(a:varname), ","), 's:strip(v:val)')
        elseif type(eval(a:varname)) == type([])
            retu map(eval(a:varname), 's:strip(v:val)')
        else | retur [] | en
    endf

    fun! s:sortrev(a, b)
        retu len(a:a) < len(a:b)
    endf

    let g:p_browse_mylist = s:makelst('g:svnj_browse_mylist')
    let g:p_burls = map(s:makelst('g:svnj_branch_url'), 's:stripAddSlash(v:val)')
    let g:p_burls = sort(g:p_burls, "s:sortrev")
    let g:p_turl = s:initPathVariables('g:svnj_trunk_url')
    let g:p_wcrp = s:initPathVariables('g:svnj_working_copy_root_path')
endf
"3}}}

fun! s:showerr(msg) "{{{3
    echohl Error | echo a:msg | echohl None
    let ign = input('Press Enter to coninue :')
    retu 0
endf
"3}}}

"svnd reference {{{2
"svnd = {
"           idx     : 0
"           title   : str(SVNLog | SVNStatus | SVNCommits | svnurl)
"           meta    : metad ,
"           logd    : logdict
"           statusd : statusdict
"           commitsd : logdict
"           menud     : menudict
"           error     : errd
"           flistd : flistdict
"           browsed : browsedict 
"           bparent  : browse_rhs_path
"       }
"
"flistdict = {
"           contents { idx, flistentryd}
"           ops :
"}
"flistentryd = { line :fpath }
"
"metad = { origurl : svnurl, fpath : absfpath, url: svnurl, wrd: workingrootlocalpath}
"
"logdict = {
"          contents: {idx : logentryd},
"          ops    :
"        }
"logentryd = { line : str, revision : revision_number}
"
"statusdict = {
"          contents: {idx : statusentryd},
"          ops    :
"        }
"statusentryd = { line : str(modtype fpath)  modtype: str, fpath : modified_or_new_fpath}
"
"browsedict = {
"          contents: {idx : fpath},
"          ops    :
"}
"
"menudict = {
"          contents : {idx : menudentryd},
"          ops    :
"}
"menuentryd = {line: str, title: str, callack : funcref, convert:str }
"
"errd = { descr : str , msg: str, line :str, ops: op }
"2}}}

"selectd reference  {{{2
"selectd : {strtohighlight:cache}   log = revision:svnurl,
"selectdict = {
"        key : { line : line, path : path} 
"}
"}}}2
"2}}}
