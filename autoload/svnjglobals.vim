" =============================================================================
" File:         autoload/svnjglobals.vim
" Description:  Handle all globals
" Author:       Juneed Ahamed
" =============================================================================

"global vars {{{2
fun! svnjglobals#init()
    "global customize {{{3
    fun! s:get_global_hl(varname, defval)
        if !exists(a:varname) || !hlexists(g:svnj_custom_fuzzy_match_hl)
            return a:defval
        else
            return eval(a:varname)
        endif
    endf

    let g:svnj_custom_fuzzy_match_hl = s:get_global_hl('g:svnj_custom_fuzzy_match_hl', 'Directory')
    let g:svnj_custom_menu_color = s:get_global_hl('g:svnj_custom_menu_color', 'MoreMsg')
    let g:svnj_custom_error_color = s:get_global_hl('g:svnj_custom_error_color', 'Error')
    let g:svnj_custom_prompt_color = s:get_global_hl('g:svnj_custom_prompt_color', 'Title')
    let g:svnj_custom_statusbar_title = s:get_global_hl('g:svnj_custom_statusbar_title', 'LineNr')
    let g:svnj_custom_statusbar_hl = s:get_global_hl('g:svnj_custom_statusbar_hl', 'Question')
    let g:svnj_custom_statusbar_title = s:get_global_hl('g:svnj_custom_statusbar_title', 'LineNr')
    let g:svnj_custom_statusbar_title = '%#' . g:svnj_custom_statusbar_title .'#'
    "3}}}

    "vars {{{3
    let g:svnj_max_logs = get(g:, 'svnj_max_logs', 10)
    let g:svnj_max_open_files = get(g:, 'svnj_max_open_files', 10)
    let g:svnj_max_diff = get(g:, 'svnj_max_diff', 2)
    let g:svnj_max_buf_lines = get(g:, 'svnj_max_buf_lines', 150)
    let g:svnj_window_max_size = get(g:, 'svnj_window_max_size', 25)
    let g:svnj_find_files = get(g:, 'svnj_find_files', 1)
    let g:svnj_warn_log = get(g:, 'svnj_warn_log', 1)
    let g:svnj_enable_debug = get(g:, 'svnj_enable_debug', 0)

    if !exists('g:svnj_signs') | let g:svnj_signs = 1 | en
    if !has('signs') | let g:svnj_signs = 0 | en

    let g:svnj_fuzzy_search = (!exists('g:svnj_fuzzy_search')) ||
                \ type(eval('g:svnj_fuzzy_search')) != type(0) ?
                \ 1 : eval('g:svnj_fuzzy_search')
    let g:svnj_fuzzy_search = g:svnj_fuzzy_search == 1 && has('python') ? 1 : 0 

    let g:svnj_fuzzy_search_result_max = (!exists('g:svnj_fuzzy_search_result_max'))  || 
                \ type(eval('g:svnj_fuzzy_search_result_max')) != type(0) ? 
                \ 50 : eval('g:svnj_fuzzy_search_result_max')

    fun! s:strip(input_string)
        return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
    endf

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

    let g:p_browse_mylist = s:makelst('g:svnj_browse_mylist')
    let g:p_burls = map(s:makelst('g:svnj_branch_url'), 's:stripAddSlash(v:val)')

    let g:p_turl = s:initPathVariables('g:svnj_trunk_url')
    let g:p_wcrp = s:initPathVariables('g:svnj_working_copy_root_path')

    let ign_files = ['.pyc', '.bin', '.zip', '.egg', '.so', '.rpd', '.git', '.png', '.psd', 
                \ '.gif', '.jpg', '.ico', '.pdf']
    if exists('g:svnj_ignore_files') && type(g:svnj_ignore_files) == type([])
        for ig in g:svnj_ignore_files | call add(ign_files, ig) | endfor
    endif
    let g:p_ign_fpat = '\v('. join(ign_files, '|') .')'

    let g:svnj_key_patt = '\v\c:\d+:$'
    "g:bmarks = { filepath : id }
    let g:bmarks = {}
    let g:bmarkssid = 1000

    if g:svnj_signs | sign define svnjmark text=s> texthl=Question linehl=Question
    en
    if g:svnj_signs | sign define svnjbook text=b> texthl=Constant linehl=Constant
    en
    return 1
    "3}}}
endf
"2}}}

"svnd reference {{{2
"svnd = {
"           idx     : 0
"           title   : str(SVNLog | SVNStatus | SVNCommits | svnurl)
"           meta    : metad ,
"           logd    : logdict
"           statusd : statusdict
"           browsed : browsedict 
"           commitsd : logdict
"           menud     : menudict
"           error     : errd
"           flistd : flistdict
"       }
"
"flistdict = {
"           contents { idx, flistentryd}
"           format : funcref,
"           ops :
"}
"flistentryd = { line :fpath }
"
"metad = { origurl : svnurl, fpath : absfpath, url: svnurl, wrd: workingrootlocalpath}
"
"logdict = {
"          contents: {idx : logentryd},
"          format:funcref,
"          select:funcref
"          ops    :
"        }
"logentryd = { line : str, revision : revision_number}
"
"statusdict = {
"          contents: {idx : statusentryd},
"          format:funcref,
"          select:funcref
"          ops    :
"        }
"statusentryd = { line : str(modtype fpath)  modtype: str, fpath : modified_or_new_fpath}
"
"browsedict = {
"          contents: {idx : listentryd},
"          format:funcref,
"          select:funcref
"          ops    :
"}
"listentryd = { line : fpath}
"
"menudict = {
"          contents : {idx : menudentryd},
"          format : funcref,
"          select : funcref,
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
