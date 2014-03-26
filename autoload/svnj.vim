" =============================================================================
" File:         autoload/svnj.vim
" Description:  Simple plugin for svn
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" Credits:      strip expresion from DrAI(StackOverflow.com user)
" =============================================================================

"autoload/svnj.vim {{{1

"global setting {{{2
if ! exists('g:svnj_max_logs')
    let g:svnj_max_logs = 10
endif

if ! exists('g:svnj_max_diff')
    let g:svnj_max_diff = 2
endif

if ! exists('g:svnj_find_files')
    let g:svnj_find_files = 1
endif

if ! exists('g:svnj_max_open_files')
    let g:svnj_max_open_files = 10
endif

if ! exists('g:svnj_fuzzy_search')
    let g:svnj_fuzzy_search = 1
elseif type(eval('g:svnj_fuzzy_search')) != type(0)
    let g:svnj_fuzzy_search = 1
endif

if ! exists('g:svnj_fuzzy_search_result_max')
    let g:svnj_fuzzy_search_result_max = 50
elseif type(eval('g:svnj_fuzzy_search_result_max')) != type(0)
    let g:svnj_fuzzy_search_result_max = 50
endif

let [s:menustart, s:menuend] = ['>>>', '<<<']
let s:menupatt = "/" . s:menustart . "\.\*/"
let s:menusyntax = 'syn match SVNMenu ' . s:menupatt

let [s:errstart, s:errend] = ['--ERROR--', '']
let s:errpatt = "/" . s:errstart . "/"
let s:errsyntax = 'syn match SVNError ' . s:errpatt

fun! s:initPathVariables(pathvar)
    if exists(a:pathvar)
        let val = eval(a:pathvar)
        if len(val) > 0 && val[len(val)-1] != '/'
            return val . '/'
        elseif len(val) > 0
            return val
        endif
    endif
    return ''
endf

let s:svnj_branch_url = s:initPathVariables('g:svnj_branch_url')
let s:svnj_trunk_url = s:initPathVariables('g:svnj_trunk_url')
let s:svnj_wcrp = s:initPathVariables('g:svnj_working_copy_root_path')

let s:svnj_ignore_files = ['.pyc', '.bin', '.egg', '.so', '.rpd', '.git']
if exists('g:svnj_ignore_files') && type(g:svnj_ignore_files) == type([])
    for ig in g:svnj_ignore_files
        call add(s:svnj_ignore_files, ig)
    endfor
endif

let s:svnj_ignore_files_pat = '\v('. join(s:svnj_ignore_files, '|') .')'
"2}}}

"The main dict svnd structure reference {{{2
"
"svnd = {
"           idx     : 0
"           title   : str(SVNLog | SVNStatus | SVNCommits | svnurl)
"           meta    : metad ,
"           logd    : logdict
"           statusd : statusdict
"           listd   : listdict 
"           commitsd : logdict
"           menud     : menudict
"           error     : errd
"           selectd : {strtohighlight:cache}   log = revision:svnurl,
"           flistd : flistdict
"       }
"
"flistdict = {
"           contents { idx, flistentryd}
"           format : funcref,
"           ops :
"}
"flistentryd = { line :filepath }
"
"metad = { origurl : svnurl, filepath : absfilepath, url: svnurl, workingrootdir: workingrootlocalpath}
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
"statusentryd = { line : str(modtype filepath)  modtype: str, filepath : modified_or_new_filepath}
"
"listdict = {
"          contents: {idx : listentryd},
"          format:funcref,
"          select:funcref
"          ops    :
"}
"listentryd = { line : filepath}
"
"menudict = {
"          contents : {idx : menudentryd},
"          format : funcref,
"          select : funcref,
"          ops    :
"}
"menuentryd = {line: str, title: str, callack : funcref, convert:str }
"
"errd = { descr : str , msg: str, line :str }
"
"
"2}}}

"Key mappings for all ops {{{2

let [s:selectkey, s:selectdscr] = ["\<C-Space>", 'C-space:Mark']
if !has('gui_running')
    let [s:selectkey, s:selectdscr] = ["\<C-l>", 'C-l:Mark']
endif

"Key mappings for svn log output logops {{{3
let s:logops = {
            \ "\<Enter>"   : {'callback':'svnj#diffFiles', 'descr': 'Ent:Diff'},
            \ "\<C-Enter>" : {'callback':'svnj#openRevNoSplit', 'descr':'C-Enter:NoSplit'},
            \ "\<C-o>"     : {'callback':'svnj#openRevisionFile', 'descr':'C-o:Open'},
            \ "\<C-w>"     : {'callback':'svnj#toggleWrap', 'descr':'C-w:wrap!'},
            \ s:selectkey  : {'callback':'svnj#handleLogSelect', 'descr': s:selectdscr},
            \ }
"3}}}

"Key mappings for svn status output statusops {{{3
let s:statusops = {
            \ "\<Enter>"  : {'callback':'svnj#openStatusFiles', 'descr': 'Ent:Open'},
            \ "\<C-o>"    : {'callback':'svnj#openAllStatusFiles', 'descr': 'C-o:OpenAll'},
            \ "\<C-w>"    : {'callback':'svnj#toggleWrap', 'descr':'C-w:wrap!'},
            \ s:selectkey : {'callback':'svnj#handleStatusSelect', 'descr': s:selectdscr},
            \ }
"3}}}

"Key mappings for svn list output listops {{{3
let s:listops = {
            \ "\<Enter>"  : {'callback':'svnj#openListFiles', 'descr': 'Ent:Open'},
            \ "\<C-o>"    : {'callback':'svnj#openAllListedFiles', 'descr': 'C-o:OpenAll'},
            \ s:selectkey : {'callback':'svnj#handleListSelect', 'descr': s:selectdscr},
            \ }
"3}}}

"Key mappings for svn log output on branch/trunk commitsop {{{3
let s:commitops = {
            \ "\<Enter>"  : {'callback':'svnj#showCommitsHEAD', 'descr': 'Ent:HEAD'},
            \ "\<C-p>"    : {'callback':'svnj#showCommitsPREV', 'descr':'C-p:PREV'},
            \ "\<C-w>"    : {'callback':'svnj#toggleWrap', 'descr':'C-w:wrap!'},
            \ s:selectkey : {'callback':'svnj#handleCommitsSelect', 'descr': s:selectdscr},
            \ }
"3}}}

"Key mappings for flist {{{3
let s:flistops = {
            \ "\<Enter>"  : {'callback':'svnj#flistSelected', 'descr': 'Ent:SELECT'},
            \ }
"3}}}


"Key mappings for svn menus, list trunks, list branches etc.,  menuops {{{3

let s:menuops = { "\<Enter>"  : {'callback':'svnj#handleMenuOps', 'descr': 'Enter:Open'}, }

"3}}}

"Default empty dir for each operations with mandatory keys  entryd
let s:entryd = {'contents':{}, 'ops':{}}

let [s:logkey, s:statuskey, s:commitskey, s:listkey, s:flistkey,  s:menukey] = [
            \ 'logd', 'statusd', 'commitsd', 'listd', 'flistd', 'menud']
"2}}}

"The svnd dict {{{2
let s:svnd = {}
fun! s:svnd.New(...) dict
    let obj = copy(self)
    let obj['selectd'] = {}
    let obj.title = a:0 >= 1 ? a:1 : ''
    let obj['idx'] = 0
    let obj['setup'] = 'svnj#setup'
    if a:0 >= 2
        call extend(obj, a:2)
    endif
    return obj
endf

fun! s:svnd.getEntries() dict
    let rlst = []
    if has_key(self, s:logkey)
        call add(rlst, self.logd)
    endif
    if has_key(self, s:statuskey)
        call add(rlst, self.statusd)
    endif
    if has_key(self, s:commitskey)
        call add(rlst, self.commitsd)
    endif
    if has_key(self, s:listkey)
        call add(rlst, self.listd)
    endif
    if has_key(self, s:flistkey)
        call add(rlst, self.flistd)
    endif
    if has_key(self, s:menukey)
        call add(rlst, self.menud)
    endif
    return rlst
endf

fun! s:svnd.hasError() dict
    return has_key(self, 'error')
endf

fun! s:svnd.addContents(key, entries, ops) dict
    if !has_key(self, a:key)
        throw a:key.' Not Present'
    endif
    for entry in a:entries
        let self.idx = self.idx + 1
        let self[a:key].contents[self.idx] = entry
    endfor
    if len(a:ops) > 0
        call extend(self[a:key].ops, a:ops)
    endif
endf

fun! s:svnd.addMenu(menu_item) dict
    if ! has_key(self, s:menukey)
        let self[s:menukey] = deepcopy(s:entryd)
    endif
    call self.addContents(s:menukey, [a:menu_item], s:menuops)
endf

fun! s:entryd.format(fltr) dict
    let linescount = len(keys(self.contents))
    let tmpd = filter(copy(self.contents),
                \ 'strlen(a:fltr) > 0 ? stridx(v:val.line, a:fltr) >= 0 : 1')
    let key_list = sort(keys(tmpd), 's:sortConvInt')
    let lines = []
    for key in key_list
        call add(lines, key. ': ' . tmpd[key].line)
    endfor
    return [linescount, len(lines), lines]
endf

fun! s:filterMe(val, fltr)
    return a:val =~? a:fltr
endf

"2}}}

"Highlight/setup {{{2
fun! svnj#setup()
    exec s:errsyntax | exec  s:menusyntax
    exec 'hi link SVNError' . ' Error '
    exec 'hi link SVNMenu' . ' MoreMsg '
endf
"2}}}

"SVNDiff {{{2
fun! svnj#SVNDiff()
    try
        let url = s:svnURL(s:getBufferFileAbsPath())
        call winj#diffCurFileWith('', url)
    catch
        let svnd = s:addErr(s:svnd.New('SVNDiff'), 'Failed ', v:exception)
        call winj#populateJWindow(svnd)
    endtry
    unlet! svnd
endf
"2}}}

"SVNBlame {{{2
fun! svnj#SVNBlame()
    try
        call winj#blame('', s:getBufferFileAbsPath())
    catch
        let svnd = s:addErr(s:svnd.New('SVNBlame'), 'Failed ', v:exception)
        call winj#populateJWindow(svnd)
    endtry
    unlet! svnd
endf
"2}}}

"SVNCommits {{{2
fun! svnj#SVNCommits()
    let svnd = s:svnd.New('SVNCommits', {s:commitskey : deepcopy(s:entryd)})
    try
        let wrd =s:svnWorkingRoot()
        let lastChngdRev = s:svnLastChangedRevision(wrd)
        let svnd.meta = s:getMeta(wrd)
        let svnd.title = 'SVNLog '. svnd.meta.url . '@' . lastChngdRev
        let loglst = s:svnLogs(svnd.meta.workingrootdir)
        call svnd.addContents(s:commitskey, loglst, s:commitops)
    catch
        let svnd = s:addErr(svnd, 'Failed ', v:exception)
    endtry
    call winj#populateJWindow(svnd)
    unlet! svnd
endf
"2}}}

"SVNLog {{{2
fun! svnj#SVNLog()
    let svnd = s:svnd.New('SVNLog', {s:logkey : deepcopy(s:entryd)})
    try
        let svnd.meta = s:getMeta(s:getBufferFileAbsPath())
        let lastChngdRev = s:svnLastChangedRevision(s:getBufferFileAbsPath())
        call svnd.addContents(s:logkey, s:svnLogs(svnd.meta.url), s:logops)
        let svnd = s:addMenusForUrl(svnd, svnd.meta.url)
        call s:addToTitle(svnd, svnd.meta.url . '@' . lastChngdRev, 0)
    catch
        let svnd = s:addErr(svnd, 'Failed ', v:exception)
    endtry
    call winj#populateJWindow(svnd)
    unlet! svnd
endf
"2}}}

"SVNStatus {{{2
fun! svnj#SVNStatus(...)
    let svnd = s:svnd.New('SVNStatus', {s:statuskey : deepcopy(s:entryd)})
    try
        let choice = a:0 > 0 ? a:1 :
                    \ input('Status (q quiet|u updates| '. 
                    \ 'Enter for All|Space separated multiple grep args): ')

        let svnd.meta = s:getMeta(getcwd())
        let cwd = svnd.meta.workingrootdir
        let svncmd = strlen(choice) > 0 ? s:argsSVNStatus(choice, cwd) :
                    \ 'svn st --non-interactive ' . cwd
        let statuslist = s:svnSummary(svncmd, svnd.meta)
        if empty(statuslist)
            let svnd = s:addErr(svnd, 'No Modified files ..', '' )
        else
            call svnd.addContents(s:statuskey, statuslist, s:statusops)
        endif
    catch
        let svnd = s:addErr(svnd, 'Failed ', v:exception)
    endtry
    call winj#populateJWindow(svnd)
    unlet! svnd
endf
"2}}}

"SVNList {{{2
fun! svnj#SVNList(...)
    let thedir = a:0 > 0 ? a:1 : getcwd()
    let svncmd = 'svn list --non-interactive ' . thedir
    call s:svnLists(svncmd, thedir, 0)
endf
"2}}}

"SVNListRec {{{2
fun! svnj#SVNListRec(...)
    let thedir = a:0 > 0 ? a:1 : getcwd()
    let svncmd = 'svn list --non-interactive -R ' . thedir
    echohl Question | echo "" | echon "Please wait, Listing files  : " 
                \ |  echohl None  | echon svncmd
    call s:svnLists(svncmd, thedir, 1)
endf
"2}}}

"svnSummary {{{2
fun! s:svnSummary(svncmd, meta)
    let shellout = s:execShellCmd(a:svncmd)
    let shelloutlist = split(shellout, '\n')
    let statuslist = []
    for line in shelloutlist
        let tokens = split(line)
        if len(matchstr(tokens[len(tokens)-1], s:svnj_ignore_files_pat)) != 0
            continue
        endif
        let statusentryd = {}
        let statusentryd.modtype = tokens[0]
        let statusentryd.filepath = tokens[len(tokens)-1]
        let statusentryd.line = line
        call add(statuslist, statusentryd)
    endfor
    return statuslist
endf
"2}}}

"SVNStatus helpers {{{2
fun! s:argsSVNStatus(choice, cwd)
    let quiet = 0
    let the_up = 0
    let thegrep_cands = []
    let cwd = a:cwd
    for token in split(a:choice)
        if token ==# '.'
            let cwd = getcwd()
        elseif toupper(token) ==# 'Q'
            let quiet = 1
        elseif toupper(token) ==# 'U'
            let the_up = 1
        else
            call add(thegrep_cands, token)
        endif
    endfor

    let svncmd = (the_up == 1 ) ? 'svn st --non-interactive -u ' :
                \ 'svn st --non-interactive '
    let svncmd = (quiet == 1 ) ? svncmd . ' -q ' . cwd : svncmd . cwd
    if len(thegrep_cands) > 0
        let thegrep_expr = '(' . join(thegrep_cands, '|') . ')'
        let svncmd = svncmd . " | grep -E \'" . thegrep_expr . "\'"
    endif
    return svncmd
endf

fun! svnj#openAllStatusFiles(svnd, key)
    let cnt = 0
    for key in keys(a:svnd.statusd.contents)
        if cnt == g:svnj_max_open_files
            break
        endif
        let cnt = cnt + 1
        call winj#openGivenFile(a:svnd.statusd.contents[key].filepath)
    endfor
    call s:errorNoFiles(cnt)
endf

fun! svnj#openStatusFiles(svnd, key)
    if !has_key(a:svnd.selectd, a:key.':')
        let a:svnd.selectd[a:key. ':'] = a:svnd.statusd.contents[a:key].filepath
    endif

    let cnt = 0
    for [thekey, filepath] in items(a:svnd.selectd)
        if cnt == g:svnj_max_open_files
            break
        endif
        let cnt = cnt + 1
        call winj#openGivenFile(filepath)
    endfor
    call s:errorNoFiles(cnt)
endf
"2}}}

"SVNLog helpers {{{2
fun! svnj#diffFiles(svnd, key)
    let revision = a:svnd.logd.contents[a:key].revision
    let a:svnd.selectd[revision] = a:svnd.meta.url
    let cnt = 0
    for [revision, url] in items(a:svnd.selectd)
        let cnt = cnt + 1
        call winj#diffCurFileWith(revision,url)
        if cnt == g:svnj_max_diff
            break
        endif
    endfor
endf

fun! svnj#diffCurFile(svnd, key)
    let revision = a:svnd.logd.contents[a:key].revision
    return winj#diffCurFileWith(revision, a:svnd.meta.url)
endf

fun! svnj#openRevNoSplit(svnd, key)
    let revision = a:svnd.logd.contents[a:key].revision
    let a:svnd.selectd[revision] = a:svnd.meta.url
    for [revision, url] in items(a:svnd.selectd)
        call winj#openFileRevision(revision, url)
    endfor
endf

fun! svnj#openRevisionFile(svnd, key)
    let revision = a:svnd.logd.contents[a:key].revision
    let a:svnd.selectd[revision] = a:svnd.meta.url
    "return winj#openFile(revision, a:svnd.meta.url)
    for [revision, url] in items(a:svnd.selectd)
        call winj#openFile(revision, url)
    endfor
endf
"2}}}

"handle Select/Mark {{{2
fun! svnj#handleCommitsSelect(svnd, key)
    let revision = a:svnd.commitsd.contents[a:key].revision
    if has_key(a:svnd.selectd, revision)
        call remove(a:svnd.selectd, revision)
        return 1
    endif
    if len(a:svnd.selectd) < 1
        let a:svnd.selectd[revision] = a:svnd.meta.url
        return 1
    else
        let revisionA = keys(a:svnd.selectd)[0]
        let revisionB = revision
        call s:showCommitsAcross(revisionA, revisionB, a:svnd.meta)
    endif
endf

fun! svnj#handleListSelect(svnd, key)
    if has_key(a:svnd.selectd, a:key.':')
        call remove(a:svnd.selectd, a:key.':')
        return 1
    endif
    let a:svnd.selectd[a:key. ':'] = a:svnd.listd.contents[a:key].line
    return 1
endf

fun! svnj#handleStatusSelect(svnd, key)
    if has_key(a:svnd.selectd, a:key.':')
        call remove(a:svnd.selectd, a:key.':')
        return 1
    endif
    let a:svnd.selectd[a:key. ':'] = a:svnd.statusd.contents[a:key].filepath
    return 1
endf

fun! svnj#handleLogSelect(svnd, key)
    let revision = a:svnd.logd.contents[a:key].revision
    if has_key(a:svnd.selectd, revision)
        call remove(a:svnd.selectd, revision)
        return 1
    endif

    if len(a:svnd.selectd) < 10
        let a:svnd.selectd[revision] = a:svnd.meta.url
        return 1
    else
        let a:svnd.selectd[revision] = a:svnd.meta.url
        for [revision, url] in items(a:svnd.selectd)
            call winj#diffCurFileWith(revision,url)
        endfor
    endif
endf

fun! svnj#handleMenuOps(svnd, key)
    return call(a:svnd.menud.contents[a:key].callback, [a:svnd, a:key])
endf
"2}}}

"SVNList helpers {{{2
fun! s:svnLists(svncmd, thedir, ignore_dirs)
    try
        let svnd = s:svnd.New('SVNList', {s:listkey : deepcopy(s:entryd)})
        let svnd.meta = s:getMeta(a:thedir)
        let listentries = s:svnList(a:svncmd, a:thedir, a:ignore_dirs) 
        if empty(listentries)
            let svnd = s:addErr(svnd, "No files listed for ", svnd.meta.workingrootdir)
        else
            call svnd.addContents(s:listkey, listentries, s:listops)
        endif
    catch
        let svnd = s:addErr(svnd, 'Failed ', v:exception)
    endtry
    call winj#populateJWindow(svnd)
    unlet! svnd
endf

fun! s:svnList(svncmd, thedir, ignore_dirs)
    let shellout = s:execShellCmd(a:svncmd)
    "let thedir = len(a:thedir) == 0 ? "." : a:thedir
    "let shellout = globpath(thedir , "**/*")
    let shelloutlist = split(shellout, '\n')
    let listentries = []
    for line in  shelloutlist
        if len(matchstr(line, s:svnj_ignore_files_pat)) != 0
            continue
        endif
        if a:ignore_dirs == 1 && isdirectory(line)
                continue
        endif
        let listentryd = {}
        let listentryd.line = line
        let listdict = {}
        call add(listentries, listentryd)
    endfor
    return listentries
endf

fun! svnj#openAllListedFiles(svnd, key)
    let cnt = 0
    for key in keys(a:svnd.listd.contents)
        let filepath = a:svnd.listd.contents[key].line
        let abspath = a:svnd.meta.filepath != "" ? 
                    \ a:svnd.meta.filepath . "/". filepath : filepath
        if cnt == g:svnj_max_open_files
            break
        endif
        let cnt = cnt + 1
        call winj#openGivenFile(abspath)
    endfor
    call s:errorNoFiles(cnt)
endf

fun! svnj#openListFiles(svnd, key)
    if !has_key(a:svnd.selectd, a:key.':')
        let a:svnd.selectd[a:key. ':'] = a:svnd.listd.contents[a:key].line
    endif

    let cnt = 0
    for [thekey, filepath] in items(a:svnd.selectd)
        let abspath = a:svnd.meta.filepath != "" ? 
                    \ a:svnd.meta.filepath . "/". filepath : filepath
        if cnt == g:svnj_max_open_files
            break
        endif
        let cnt = cnt + 1
        call winj#openGivenFile(abspath)
    endfor
    call s:errorNoFiles(cnt)
endf
"2}}}

"SVNCommits helpers {{{2
fun! svnj#showCommitsHEAD(svnd, key)
    call s:showCommits(a:svnd, a:key, ':HEAD')
endf

fun! svnj#showCommitsPREV(svnd, key)
    call s:showCommits(a:svnd, a:key, ':PREV')
endf

fun! s:showCommits(svnd, key, headOrPrev)
    let revision = a:svnd.commitsd.contents[a:key].revision
    let title = 'SVNDiff:' . revision . a:headOrPrev
    let svnd = s:svnd.New(title, {s:statuskey : deepcopy(s:entryd)})
    let svnd.meta = a:svnd.meta
    let svncmd = 'svn diff --non-interactive -' . revision . a:headOrPrev .
                \ ' --summarize '. svnd.meta.workingrootdir
    let statuslist = s:svnSummary(svncmd, svnd.meta)
    if empty(statuslist)
        let svnd = s:addErr(svnd, 'No Commits found ..' , '' )
    else
        call svnd.addContents(s:statuskey, statuslist, s:statusops)
    endif
    call winj#populateJWindow(svnd)
    unlet! svnd
endf

fun! s:showCommitsAcross(revisionA, revisionB, meta)
    let title = 'SVNDiff:' . a:revisionA . ':' . a:revisionB
    let svnd = s:svnd.New(title, {s:statuskey : deepcopy(s:entryd)})
    let svnd.meta = a:meta
    let revisiondiff = a:revisionA.':'.a:revisionB
    let svncmd = 'svn diff --non-interactive  -' . revisiondiff .
                \ ' --summarize '. svnd.meta.workingrootdir
    let statuslist = s:svnSummary(svncmd, svnd.meta)
    if empty(statuslist)
        let svnd = s:addErr(svnd, 'No Commits found ..' , '' )
    else
        call svnd.addContents(s:statuskey, statuslist, s:statusops)
    endif
    call winj#populateJWindow(svnd)
    unlet! svnd
endf
"2}}}

"SVN URL helpers {{{2
fun! s:validateSVNURLInteractive(sysURL)
    if !svnj#validSVNURL(a:sysURL)
        echohl WarningMsg | echo 'Failed to construct svn url: '
                    \ | echo a:sysURL | echohl None
        let inputurl = input('Enter URL : ')
        if len(inputurl) > 1 && svnj#validSVNURL(inputurl)
            return inputurl
        endif
    else
        return a:sysURL
    endif
    throw 'Invalid URL'
endf

fun! s:svnTrunkURL(URL)
    return s:svnj_trunk_url != '' && stridx(a:URL, s:svnj_trunk_url, 0) == 0
endf

fun! s:svnBranchURL(URL)
    return s:svnj_branch_url != '' && stridx(a:URL, s:svnj_branch_url, 0) == 0
endf

fun! s:svnBranchName(bURL)
    if s:svnj_branch_url != ''
        let sidx = len(s:svnj_branch_url)
        let eidx = stridx(a:bURL, '/', sidx)
        return  strpart(a:bURL, sidx, eidx - sidx) . '/'
    endif
    return ''
endf

fun! s:svnWorkingRoot()
    if len(s:svnj_wcrp) == 0 || isdirectory(s:svnj_wcrp) == 0
        return s:svnWorkingCopyRootPath()
    endif
    return s:svnj_wcrp
endf

fun! s:svnWorkingCopyRootPath()
    let svncmd = 'svn info --non-interactive ' . getcwd() .
                \ '| grep "^Working Copy Root Path"'
    try
        let svnout = s:execShellCmd(svncmd)
        let svnoutlist = split(svnout, '\n')
        if len(svnoutlist) >= 1
            let tokens = split(svnoutlist[0], ':')
            if len(tokens) >= 2
                let tmpworkingdir = s:strip(tokens[1])
                if isdirectory(tmpworkingdir)
                    return tmpworkingdir
                endif
            endif
        endif
    catch
    endtry
    return getcwd()
endf
"2}}}

"getMeta {{{2
fun! s:getMeta(fileabspath)
    let url = s:svnURL(a:fileabspath)
    let metad = {}
    let metad.origurl = url
    let metad.url = url
    let metad.filepath = a:fileabspath
    let metad.workingrootdir=s:svnWorkingRoot()
    return metad
endf
"2}}}

"flist functions findfiles, askUsr {{{2
fun! s:findFile(pURL, tfile)
    let shellist = []
    try
        let fname = fnamemodify(a:tfile, ":t")
        let svncmd = 'svn list -R --non-interactive ' . a:pURL . ' | grep ' . fname
        echohl Error | echo "" | echon "Please wait, Finding file  : " |  echohl None | echon fname
        let shellout = s:execShellCmd(svncmd)
        let shellist = split(shellout, '\n')

        "If shell returned one file we found the required one
        if len(shellist) == 1 
            let fURL = a:pURL . shellist[0]
            if svnj#validSVNURL(fURL)
                return [[fURL,] , 1]
            endif
        endif

        "If shell returned more than one file will have to narrow it down
        if len(shellist) > 0
            "if whole path matches we are done
            let found = index(shellist, a:tfile)
            if found != -1 
                let fURL = a:pURL . shellist[ found ]
                if svnj#validSVNURL(fURL)
                    return [[fURL,] , 1]
                endif
            endif
            
            "whole path did not match ask user for a file
            "lets try to narrow it down
            let expr = ".*".a:tfile
            let flist = filter(copy(shellist),  'v:val =~ expr' )
            if len(flist) == 1
                let fURL = a:pURL . flist[0]
                if svnj#validSVNURL(fURL)
                    return [[fURL,] , 1]
                endif
            elseif len(flist) > 1
                let shellist = flist
            endif

            let usrFile = s:askUsrForFile(shellist, a:tfile)
            if usrFile != ""
                let fURL = a:pURL . usrFile
                if svnj#validSVNURL(fURL)
                    return [[fURL,] , 1]
                endif
            endif
        endif
    catch
        "echo "Exception at findFile ." v:exception
    endtry
    return [shellist, 0]
endf

fun! s:askUsrForFile(files, lfile)
    let s:selectedFile = ""
    if len(a:files) > 0
        let qsvnd = s:svnd.New("Select for :" . a:lfile, 
                    \ {s:flistkey : deepcopy(s:entryd)})
        let flistentries = []
        for tfile in a:files
            let flistentryd = {}
            let flistentryd.line = tfile
            call add(flistentries, flistentryd)
        endfor
        call qsvnd.addContents(s:flistkey, flistentries, s:flistops)
        call winj#populateJWindow(qsvnd)
        if s:selectedFile != ""
            return s:selectedFile
        endif
    endif
endf

fun! svnj#flistSelected(qsvnd, key)
    let s:selectedFile = a:qsvnd.flistd.contents[a:key].line
endf
"2}}}

"URLs translaters branch2branch, branch2trunk etc., {{{2
fun! s:svnBranchURLFromTrunk(tURL, tbname)
    let bURL = s:svnj_branch_url . a:tbname
    let rbURL = substitute(a:tURL, s:svnj_trunk_url, bURL, '')

    if !svnj#validSVNURL(rbURL) && g:svnj_find_files == 1
        let tfile = substitute(a:tURL, s:svnj_trunk_url, "", "")
        let [ tbURLs, result] = s:findFile(bURL, tfile)
        if result 
            return tbURLs[0]
        endif
    endif
    return rbURL
endf

fun! s:svnBranchURLFromBranch(bURL, tbname)
    let fbname = s:svnBranchName(a:bURL)
    let rbURL = substitute(a:bURL, fbname, a:tbname, '')

    if !svnj#validSVNURL(rbURL) && g:svnj_find_files == 1
        let tfile = substitute(a:bURL, s:svnj_branch_url, "", "")
        let [ tbURLs, result] = s:findFile(s:svnj_branch_url . a:tbname, tfile)
        if result 
            return tbURLs[0]
        endif
    endif
    return rbURL
endf

fun! s:svnTrunkURLFromBranchURL(bURL)
    let branchname = s:svnBranchName(a:bURL)
    if strlen(branchname) > 0
        let currentbranchurl = s:svnj_branch_url . branchname
        let tURL = substitute(a:bURL, currentbranchurl, s:svnj_trunk_url, '')

        if !svnj#validSVNURL(tURL) && g:svnj_find_files == 1
            let tfile = substitute(a:bURL, currentbranchurl, "", "")
            let [ tURLs, result] = s:findFile(s:svnj_trunk_url, tfile)
            if result 
                return tURLs[0]
            endif
        endif
        return tURL
    endif
    return ''
endf
"2}}}

"svnLogs {{{2
fun! s:svnLogs(svnurl)
    let svncmd = 'svn log --non-interactive -l ' . g:svnj_max_logs . 
                \ ' ' . a:svnurl
    let shellout = s:execShellCmd(svncmd)
    let shellist = split(shellout, '\n')
    let logentries = []
    try
        for idx in range(0,  len(shellist)-1)
            let curline = shellist[idx]
            if len(matchstr(curline, '^--')) > 0
                let idx = idx + 1
                if idx < len(shellist)
                    let curline = shellist[idx]
                    if len(matchstr(curline, '^r')) > 0
                        let logentry = {}
                        let contents = split(curline, '|')
                        let revision = s:strip(contents[0])
                        let logentry.revision = revision
                        let logentry.line = revision . ' ' . join(contents[1:], '|')
                        let idx = idx + 1
                        while idx < len(shellist)
                            let curline = shellist[idx]
                            if len(matchstr(curline, '^--')) > 0
                                break
                            endif
                            let logentry.line = logentry.line . '|' . curline
                            let idx = idx + 1
                        endwhile
                        call add(logentries, logentry)
                    endif
                endif
            else
                let idx = idx + 1
            endif
        endfor
    catch
    endtry
    return logentries
endf
"2}}}

"back funs {{{2
fun! s:svnRootVersion(workingcopydir)
    let svncmd = 'svn log --non-interactive -l 1 ' . 
                \ a:workingcopydir . ' | grep ^r'
    let shellout = s:execShellCmd(svncmd)
    let revisionnum = s:strip(split(shellout, '|')[0])
    return revisionnum
endf
"2}}}

"svn helpers {{{2
fun! s:svnLastChangedRevision(svnurl)
    let lastChngdRev = ''
    try
        let svncmd = 'svn info --non-interactive ' . a:svnurl .
                    \ ' | grep "Last Changed Rev:" | cut -d ":" -f2 | tr -s ""'
        let svnout = s:execShellCmd(svncmd)
        if len(svnout) > 0
            let svnoutlist = split(svnout, '\n')
            let lastChngdRev = s:strip(svnoutlist[0])
        endif
    catch
    endtry
    return lastChngdRev
endf

fun! s:svnURL(absfilepath)
    let svncmd = 'svn info --non-interactive ' .
                \ a:absfilepath . ' | grep URL: '
    let svnout = s:execShellCmd(svncmd)
    let fileurl = substitute(svnout, 'URL: ', '', '')
    let fileurl = substitute(fileurl, '\n', '', '')
    return fileurl
endf

fun! svnj#validSVNURL(svnurl)
    let svncmd = 'svn info --non-interactive ' . a:svnurl
    try
        let shellout = s:execShellCmd(svncmd)
    catch
        return 0
    endtry
    return 1
endf
"2}}}

"menu helpers {{{2
"convert = branch2trunk | branch2branch | trunk2branch
fun! s:newMenuItem(title, callback, convert)
    let menu_item = {}
    let menu_item.line = s:menustart.a:title.s:menuend
    let menu_item.title = a:title
    let menu_item.callback = a:callback
    let menu_item.convert = a:convert
    return menu_item
endf

fun! s:addMenusForUrl(svnd, url)
    let svnd = a:svnd
    if s:svnBranchURL(a:url)
        if s:svnj_trunk_url != ''
            call svnd.addMenu(s:newMenuItem(
                        \ 'List Trunk Files', 
                        \ 'svnj#listFilesFrom',
                        \ 'branch2trunk'))
        endif
        call svnd.addMenu(s:newMenuItem(
                    \ 'List Branches', 
                    \ 'svnj#listBranches',
                    \ 'branch2branch'))

    elseif s:svnTrunkURL(a:url)
        call svnd.addMenu(s:newMenuItem(
                    \ 'List Branches',
                    \ 'svnj#listBranches',
                    \ 'trunk2branch'))

    elseif exists('s:svnj_branch_url') "TODO
        let svnd = s:addErr(svnd, 'Failed to get branches/trunk',
                    \ 'g:svnj_branch_url = '.s:svnj_branch_url)
    endif
    return svnd
endf

fun! svnj#listFilesFrom(svnd, key)
    let svnd = s:svnd.New('SVNLog', {s:logkey : deepcopy(s:entryd)})
    let svnd.meta = a:svnd.meta
    let fileurl = ''
    try
        let contents = a:svnd.menud.contents[a:key]
        if contents.convert ==# 'branch2branch'
            let fileurl = s:svnBranchURLFromBranch(a:svnd.meta.url, contents.title)
        elseif contents.convert ==# 'branch2trunk'
            let fileurl = s:svnTrunkURLFromBranchURL(a:svnd.meta.url)
        elseif contents.convert ==# 'trunk2branch'
            let fileurl = s:svnBranchURLFromTrunk(a:svnd.meta.url, contents.title)
        endif

        let fileurl = s:validateSVNURLInteractive(fileurl)
        let svnd.meta.url = fileurl
        let svnd.title = fileurl
        call svnd.addContents(s:logkey, s:svnLogs(svnd.meta.url), s:logops)
    catch
        echo v:exception
        let svnd = s:addErr(svnd, 'Failed to construct svn url',
                    \ ' OR File does not exist' )
    endtry
    call winj#populateJWindow(svnd)
    unlet! svnd
endf

fun! svnj#listBranches(svnd, key)
    let svnd = s:svnd.New(s:svnj_branch_url)
    let svnd.meta = a:svnd.meta
    let svncmd = 'svn ls --non-interactive ' . s:svnj_branch_url
    try
        let branches = s:execShellCmd(svncmd)
    catch
        let svnd = s:addErr(svnd, 'Failed ', v:exception)
        call winj#populateJWindow(svnd)
        return
    endtry
    let brancheslist = split(branches, '\n')
    let currentbranchname = s:svnBranchName(svnd.meta.url)
    for branch in brancheslist
        if currentbranchname != branch
            call svnd.addMenu(s:newMenuItem(branch,
                        \ 'svnj#listFilesFrom',
                        \  a:svnd.menud.contents[a:key].convert))
        endif
    endfor
    call winj#populateJWindow(svnd)
endf
"2}}}

"Util funs {{{2
fun! s:getBufferFileAbsPath()
    let fileabspath = expand('%:p')
    if fileabspath ==# ''
        throw 'Error No file in buffer'
    endif
    return fileabspath
endf

fun! s:addErr(svnd, descr, msg)
    let a:svnd.error = {}
    "let a:svnd.error.descr = a:descr
    "let a:svnd.error.msg = a:msg
    let a:svnd.error.line = s:errstart.a:descr . ' | ' . a:msg
    return a:svnd
endf

fun! s:addToTitle(svnd, msg, prefix)
    try
        if a:prefix == 1
            let a:svnd.title = a:msg. ' '. a:svnd.title
        else
            let a:svnd.title = a:svnd.title. ' ' . a:msg
        endif
    catch
    endtry
endf

fun! s:errorNoFiles(cnt)
    if a:cnt == 0 
        let svnd = s:addErr(s:svnd.New('Failed'), "No files to open", "")
        call winj#populateJWindow(svnd)
        unlet! svnd
    endif
endf

fun! svnj#toggleWrap(svnd, key)
    setl wrap!
    return 2
endf

fun! s:sortConvInt(i1, i2)
    return a:i1 - a:i2
endf

fun! s:strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf

fun! s:execShellCmd(cmd)
    let shellout = system(a:cmd)
    if v:shell_error != 0
        throw 'FAILED CMD: ' . shellout
    endif
    return shellout
endf
"2}}}

"1}}}
