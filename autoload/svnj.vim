" =============================================================================
" File:         autoload/svnj.vim
" Description:  Simple plugin for svn
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" Credits:      strip expresion from DrAI(StackOverflow.com user)
" =============================================================================


if ! exists('g:svnj_max_logs')
    let g:svnj_max_logs = 10
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

let s:svnj_ignore_files = ['.pyc', '.bin', '.egg', '.so', '*.rpd']
if exists('g:svnj_ignore_files') && type(g:svnj_ignore_files) == type([])
    for ig in g:svnj_ignore_files
        call add(s:svnj_ignore_files, ig)
    endfor
endif

let s:svnj_ignore_files_pat = '\v('. join(s:svnj_ignore_files, '|') .')$'

" The main dict svnd structure "{{{
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
"       }
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
""}}}

"Key mappings for all ops"{{{1

let [s:selectkey, s:selectdscr] = ["\<C-Space>", 'C-space:Mark']
if !has('gui_running')
    let [s:selectkey, s:selectdscr] = ["\<C-l>", 'C-l:Mark']
endif

"Key mappings for svn log output logops"{{{2
let s:logops = {
            \ "\<Enter>"   : {'callback':'svnj#diffCurFile', 'descr': 'Ent:Diff'},
            \ "\<C-o>"     : {'callback':'svnj#openRevisionFile', 'descr':'C-o:Open'},
            \ "\<C-w>"     : {'callback':'svnj#toggleWrap', 'descr':'C-w:tooglewrap'},
            \ s:selectkey  : {'callback':'svnj#handleLogSelect', 'descr': s:selectdscr},
            \ }
"end "2}}}

"Key mappings for svn status output statusops"{{{2
let s:statusops = {
            \ "\<Enter>"  : {'callback':'svnj#openStatusFile', 'descr': 'Ent:Open'},
            \ "\<C-o>"    : {'callback':'svnj#openStatusFiles', 'descr': 'C-o:OpenAll'},
            \ "\<C-Enter>": {'callback':'svnj#openSelected', 'descr':'C-Ent:OpenSelected'},
            \ "\<C-w>"    : {'callback':'svnj#toggleWrap', 'descr':'C-w:tooglewrap'},
            \ s:selectkey : {'callback':'svnj#handleStatusSelect', 'descr': s:selectdscr},
            \ }
"end "2}}}
"
"Key mappings for svn list output listops"{{{2
let s:listops = {
            \ "\<Enter>"  : {'callback':'svnj#openListFile', 'descr': 'Ent:Open'},
            \ "\<C-o>"    : {'callback':'svnj#openListFiles', 'descr': 'C-o:OpenAll'},
            \ "\<C-Enter>": {'callback':'svnj#openSelected', 'descr':'C-Ent:OpenSelected'},
            \ s:selectkey : {'callback':'svnj#handleListSelect', 'descr': s:selectdscr},
            \ }
"end "2}}}

"Key mappings for svn log output on branch/trunk commitsop"{{{2
let s:commitops = {
            \ "\<Enter>"  : {'callback':'svnj#showCommitsHEAD', 'descr': 'Ent:HEAD'},
            \ "\<C-p>"    : {'callback':'svnj#showCommitsPREV', 'descr':'C-p:PREV'},
            \ "\<C-w>"    : {'callback':'svnj#toggleWrap', 'descr':'C-w:tooglewrap'},
            \ s:selectkey : {'callback':'svnj#handleCommitsSelect', 'descr': s:selectdscr},
            \ }
"end "2}}}

"Key mappings for svn menus, list trunks, list branches etc.,  menuops
let s:menuops = { "\<Enter>"  : {'callback':'svnj#handleMenuOps', 'descr': 'Enter:Open'}, }

"end Key mappins for all ops"1}}}

"Default empty dir for each operations with mandatory keys  entryd
let s:entryd = {'contents':{}, 'ops':{}}

let [s:logkey, s:statuskey, s:commitskey, s:listkey, s:menukey] = [
            \ 'logd', 'statusd', 'commitsd', 'listd', 'menud']

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

fun! svnj#setup()
    exec s:errsyntax | exec  s:menusyntax
    exec 'hi link SVNError' . ' Error '
    exec 'hi link SVNMenu' . ' MoreMsg '
endf

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

fun! svnj#SVNBlame()
    try
        call winj#blame('', s:getBufferFileAbsPath())
    catch
        let svnd = s:addErr(s:svnd.New('SVNBlame'), 'Failed ', v:exception)
        call winj#populateJWindow(svnd)
    endtry
    unlet! svnd
endf

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

fun! svnj#SVNList(...)
    let svnd = s:svnd.New('SVNList', {s:listkey : deepcopy(s:entryd)})
    try
        let thedir = a:0 > 0 ? a:1 : getcwd()
        let svnd.meta = s:getMeta(thedir)
        let svncmd = 'svn list --non-interactive ' . thedir
        let listentries = s:svnList(svncmd) 
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

fun! s:svnList(svncmd)
    let shellout = s:execShellCmd(a:svncmd)
    let shelloutlist = split(shellout, '\n')
    let listentries = []
    for line in  shelloutlist
        if len(matchstr(line, s:svnj_ignore_files_pat)) != 0
            continue
        endif
        let listentryd = {}
        let listentryd.line = line
        let listdict = {}
        call add(listentries, listentryd)
    endfor
    return listentries
endf

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

fun! svnj#openListFiles(svnd, key)
    for key in keys(a:svnd.listd.contents)
        call winj#openGivenFile(a:svnd.listd.contents[key].line)
    endfor
endf

fun! svnj#openListFile(svnd, key)
    return winj#openGivenFile(a:svnd.listd.contents[a:key].line)
endf

fun! svnj#openStatusFiles(svnd, key)
    for key in keys(a:svnd.statusd.contents)
        call winj#openGivenFile(a:svnd.statusd.contents[key].filepath)
    endfor
endf

fun! svnj#openStatusFile(svnd, key)
    return winj#openGivenFile(a:svnd.statusd.contents[a:key].filepath)
endf

fun! svnj#diffCurFile(svnd, key)
    let revision = a:svnd.logd.contents[a:key].revision
    return winj#diffCurFileWith(revision, a:svnd.meta.url)
endf

fun! svnj#openRevisionFile(svnd, key)
    let revision = a:svnd.logd.contents[a:key].revision
    return winj#openFile(revision, a:svnd.meta.url)
endf

fun! svnj#openSelected(svnd, key)
    for [thekey, filepath] in items(a:svnd.selectd)
        call winj#openGivenFile(filepath)
    endfor
endf

fun! svnj#toggleWrap(svnd, key)
    setl wrap!
    return 2
endf

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

    if len(a:svnd.selectd) < 1
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
        let svnd = s:addErr(svnd, 'Failed to construct svn url',
                    \ ' OR File does not exist' )
    endtry
    call winj#populateJWindow(svnd)
    unlet! svnd
endf

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

fun! s:getMeta(fileabspath)
    let url = s:svnURL(a:fileabspath)
    let metad = {}
    let metad.origurl = url
    let metad.url = url
    let metad.filepath = a:fileabspath
    let metad.workingrootdir=s:svnWorkingRoot()
    return metad
endf

fun! s:svnBranchURLFromTrunk(tURL, tobranchname)
    let thisbranchurl = s:svnj_branch_url . a:tobranchname
    let branchurl = substitute(a:tURL, s:svnj_trunk_url, thisbranchurl, '')
    return branchurl
endf

fun! s:svnBranchURLFromBranch(bURL, tobranchname)
    let frombranchname = s:svnBranchName(a:bURL)
    return substitute(a:bURL, frombranchname, a:tobranchname, '')
endf

fun! s:svnTrunkURLFromBranchURL(bURL)
    let branchname = s:svnBranchName(a:bURL)
    if strlen(branchname) > 0
        let currentbranchurl = s:svnj_branch_url . branchname
        return substitute(a:bURL, currentbranchurl, s:svnj_trunk_url, '')
    endif
    return ''
endf

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

fun! s:svnRootVersion(workingcopydir)
    let svncmd = 'svn log --non-interactive -l 1 ' . 
                \ a:workingcopydir . ' | grep ^r'
    let shellout = s:execShellCmd(svncmd)
    let revisionnum = s:strip(split(shellout, '|')[0])
    return revisionnum
endf

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
