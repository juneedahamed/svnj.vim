"===============================================================================
" File:         autoload/svnj/svn.vim
" Description:  SVN Commands helpers
" Author:       Juneed Ahamed
"===============================================================================

"SVN command parsers {{{1

fun! svnj#svn#info(url) "{{{2
    let svncmd = 'svn info --non-interactive ' . a:url
    return svnj#utils#execShellCmd(svncmd)
endf
"2}}}

fun! svnj#svn#infolog(url) "{{{2
    let result = ""
    try
        let svncmd = 'svn info --non-interactive -' . a:url
        let result = result . svnj#utils#execShellCmd(svncmd)
        let svncmd = 'svn log --non-interactive -' . a:url
        let result = result . svnj#utils#execShellCmd(svncmd)
    catch
        call svnj#utils#dbgHld("svnj#svn#infolog", v:exception)
        let result = v:exception
    endtry
    return result
endf
"2}}}


fun! svnj#svn#url(absfpath) "{{{2
    let fileurl = a:absfpath
    let svncmd = 'svn info --non-interactive ' . fnameescape(svnj#utils#expand(a:absfpath))
    let urllines = s:matchShellOutput(svncmd, "^URL")
    if len(urllines) > 0
        let fileurl = substitute(urllines[0], 'URL: ', '', '')
        let fileurl = substitute(fileurl, '\n', '', '')
    endif
    return fileurl
endf
"2}}}

fun! svnj#svn#issvndir(absfpath) "{{{2
    try
        let svncmd = 'svn info --non-interactive ' . fnameescape(svnj#utils#expand(a:absfpath))
        let nodekindline = s:matchShellOutput(svncmd, "^Node Kind:")
        if len(nodekindline) > 0
            return matchstr(nodekindline, "directory") != ""
        endif
    catch | retu 0 | endtry
    return 0
endf
"2}}}

fun! svnj#svn#getMeta(fileabspath) "{{{2
    let url = svnj#svn#url(a:fileabspath)
    let metad = {}
    let metad.origurl = url
    let metad.url = url
    let metad.isdir = svnj#svn#issvndir(a:fileabspath)
    let metad.fpath = a:fileabspath == "" ? getcwd() : a:fileabspath
    let metad.wrd=svnj#svn#workingRoot()
    return metad
endf
"2}}}

fun! svnj#svn#getMetaFS(fileabspath) "{{{2
    let url = a:fileabspath
    let metad = {}
    let metad.origurl = url
    let metad.url = url
    let metad.isdir = 0
    let metad.fpath = a:fileabspath == "" ? getcwd() : a:fileabspath
    let metad.wrd="/"
    return metad
endf
"2}}}

fun! svnj#svn#blankMeta() "{{{2
    let metad = {}
    let metad.origurl = ""
    let metad.url = ""
    let metad.fpath = ""
    let metad.wrd=""
    return metad
endf
"2}}}

fun! svnj#svn#getMetaURL(url) "{{{2
    let metad = {}
    let metad.origurl = a:url
    let metad.url = a:url
    let metad.fpath = ""
    let metad.isdir = 0
    let metad.wrd=svnj#svn#workingRoot()
    return metad
endf
"2}}}

fun! svnj#svn#branchRoot(bURL) "{{{2
    for brnch in g:p_burls
        if stridx(a:bURL, brnch, 0) == 0  | return brnch | en
    endfor
    return ""
endf
"2}}}

fun! svnj#svn#branchName(bURL) "{{{2
    let baseURL = svnj#svn#branchRoot(a:bURL)
    if baseURL != ""
        let sidx = len(baseURL)
        let eidx = stridx(a:bURL, '/', sidx)
        return  strpart(a:bURL, sidx, eidx - sidx) . '/'
    endif
    return ''
endf
"2}}}

fun! svnj#svn#workingRoot() "{{{2
    return len(g:p_wcrp) == 0 || isdirectory(g:p_wcrp) == 0 ?
                \ svnj#svn#workingCopyRootPath() : g:p_wcrp
endf
"2}}}

fun! svnj#svn#workingCopyRootPath() "{{{2
    let svncmd = 'svn info --non-interactive ' . getcwd()
    try
        let svnout = svnj#utils#execShellCmd(svncmd)
        let lines = s:matchShellOutput(svncmd, "^Working Copy Root Path")
        if len(lines) >= 1
            let tokens = split(lines[0], ':')
            if len(tokens) >= 2
                let tmpworkingdir = svnj#utils#strip(tokens[1])
                if isdirectory(tmpworkingdir) | return tmpworkingdir | en
            endif
        endif
    catch
    endtry
    return getcwd()
endf
"2}}}

fun! svnj#svn#repoRoot() "{{{2
    let svncmd = 'svn info --non-interactive ' . getcwd()
    try
        let svnout = svnj#utils#execShellCmd(svncmd)
        let lines = s:matchShellOutput(svncmd, "^Repository Root:")
        if len(lines) >= 1
            let root = substitute(lines[0], "^Repository Root:", "", "")
            let root = svnj#utils#strip(root)
            return root
        endif
    catch
    endtry
    return getcwd()
endf
"2}}}

fun! svnj#svn#svnRootVersion(workingcopydir) "{{{2
    let svncmd = 'svn log --non-interactive -l 1 ' . 
                \ a:workingcopydir . ' | grep ^r'
    let shellout = svnj#utils#execShellCmd(svncmd)
    let revisionnum = svnj#utils#strip(split(shellout, '|')[0])
    return revisionnum
endf
"2}}}

fun! svnj#svn#validURL(svnurl) "{{{2
    let svncmd = 'svn info --non-interactive ' . a:svnurl
    try
        let shellout = svnj#utils#execShellCmd(svncmd)
    catch | retu 0 | endtry
    return 1
endf
"2}}}

fun! svnj#svn#validateSVNURLInteractive(sysURL) "{{{2
    if !svnj#svn#validURL(a:sysURL)
        echohl WarningMsg | echo 'Failed to construct svn url: '
                    \ | echo a:sysURL | echohl None
        let inputurl = input('Enter URL : ')
        if len(inputurl) > 1 && svnj#svn#validURL(inputurl)
            return inputurl
        endif
    else
        return a:sysURL
    endif
    throw 'Invalid URL'
endf 
"2}}}

fun! svnj#svn#isTrunk(URL) "{{{2
    return g:p_turl != '' && stridx(a:URL, g:p_turl, 0) == 0
endf
"2}}}

fun! svnj#svn#isBranch(URL) "{{{2
    return len(filter(copy(g:p_burls), 'stridx(a:URL, v:val,0) == 0')) > 0
endf
"2}}}

fun! svnj#svn#isWCDir() "{{{2
    let svncmd = 'svn info --non-interactive ' . getcwd()
    try
        let shellout = svnj#utils#execShellCmd(svncmd)
    catch | retu 0 | endtry
    return 1
endf
"2}}}

fun! svnj#svn#list(url, rec, ignore_dirs)  "{{{2
    let entries = []
    if a:rec
        let shelloutlist = s:globsvnrec(a:url)
    else
        let svncmd = 'svn list --non-interactive ' . fnameescape(svnj#utils#expand(a:url))
        let shellout = svnj#utils#execShellCmd(svncmd)
        let shelloutlist = split(shellout, '\n')
        unlet! shellout
    endif

    let linenum = 0
    for line in  shelloutlist
        if len(matchstr(line, g:p_ign_fpat)) != 0 | con | en
        if a:ignore_dirs == 1 && isdirectory(line) | con | en
        let linenum += 1
        let line = printf("%4d:%s", linenum, line)
        call add(entries, line)
    endfor
    unlet! shelloutlist
    return entries
endf

fun! s:globsvnrec(url)
    let leaf = substitute(a:url, svnj#utils#getparent(a:url), "", "")
    let burl = a:url

    let [result, ffiles] = svnj#caop#fetch("repo", burl)
    if result | retu ffiles | en

    let [files, tdirs] = [[], [""]]
    while len(files) < g:svnj_browse_repo_max_files_cnt && len(tdirs) > 0
        try
            let curdir = remove(tdirs, 0)
            call svnj#utils#showConsoleMsg("Fetching files from repo : " . curdir, 0)
            let furl = svnj#utils#joinPath(burl, curdir)
            let svncmd = 'svn list --non-interactive ' . fnameescape(svnj#utils#expand(furl))
            let flist = split(svnj#utils#execShellCmd(svncmd), "\n")
            let [tfiles, tdirs2] =  s:filedirs(curdir, flist)
            call extend(files, tfiles)
            call extend(files, tdirs2)
            call extend(tdirs, tdirs2)
            unlet! flist tfiles tdirs2 
        catch
            "call svnj#utils#dbgHld("At globsvnrec", v:exception)
        endt
    endwhile
    unlet! tdirs

    call svnj#caop#cache("repo", burl, files)
    return files
endf

fun! s:filedirs(curdir, flist)
    let [files, dirs] = [[], []]
    for entry in a:flist
        if len(matchstr(entry, g:p_ign_fpat)) != 0 | con | en
        call call('add', [svnj#utils#isSvnDirReg(entry) ? dirs : files, 
                    \ svnj#utils#joinPath(a:curdir,entry)])
    endfor
    return [files, dirs]
endf
"2}}}

fun! svnj#svn#logs(maxlogs, svnurl) "{{{2
    let svncmd = 'svn log --non-interactive -l ' . a:maxlogs .
                \ ' ' . fnameescape(svnj#utils#expand(a:svnurl))
    let shellout = svnj#utils#execShellCmd(svncmd)
    let shellist = split(shellout, '\n')
    unlet! shellout
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
                        let revision = svnj#utils#strip(contents[0])
                        let logentry.revision = revision
                        let logentry.line = revision . ' ' . join(contents[1:], '|')
                        let idx = idx + 1
                        while idx < len(shellist)
                            let curline = shellist[idx]
                            if len(matchstr(curline, '^--')) > 0 | break | en
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
        unlet! shellist
    catch | endtry
    return [logentries, svncmd]
endf
"2}}}

fun! svnj#svn#summary(svncmd) "{{{2
    let shellout = svnj#utils#execShellCmd(a:svncmd)
    let shelloutlist = split(shellout, '\n')
    unlet! shellout
    let statuslist = []
    for line in shelloutlist
        let tokens = split(line)
        if len(matchstr(tokens[len(tokens)-1], g:p_ign_fpat)) != 0 | cont | en
        let statusentryd = {}
        let statusentryd.modtype = tokens[0]
        let statusentryd.fpath = tokens[len(tokens)-1]
        let statusentryd.line = line
        call add(statuslist, statusentryd)
    endfor
    unlet! shelloutlist
    return [statuslist, a:svncmd]
endf
"2}}}

fun! svnj#svn#affectedfilesAcross(url, revisionA, revisionB) "{{{2
    let revisiondiff = a:revisionA.':'.a:revisionB
    let svncmd = 'svn diff --summarize --non-interactive  -' . 
                \ revisiondiff . ' '. a:url
    return svnj#svn#summary(svncmd)
endf
"2}}}

fun! svnj#svn#affectedfiles(url, revision) "{{{2
    let revision = matchstr(a:revision, "\\d\\+")
    let svncmd = 'svn diff --summarize --non-interactive -c' .
                \ revision . ' ' . a:url
    return svnj#svn#summary(svncmd)
endf
"2}}}

fun! svnj#svn#currentRevision(svnurl) "{{{2
    let revision = ''
    try
        let svncmd = 'svn info --non-interactive ' . a:svnurl
        let find = '^Revision:'
        let lines = s:matchShellOutput(svncmd, find)
        let revision = svnj#utils#strip(substitute(lines[0], find, '', ''))
    catch | endtry
    return revision
endf
"2}}}

fun! svnj#svn#lastChngdRev(svnurl) "{{{2
    let lastChngdRev = ''
    try
        let svncmd = 'svn info --non-interactive ' . a:svnurl
        let find = '^Last Changed Rev:'
        let lines = s:matchShellOutput(svncmd, find)
        let lastChngdRev = svnj#utils#strip(substitute(lines[0], find, '', ''))
    catch | endtry
    return lastChngdRev
endf
"2}}}

fun! s:matchShellOutput(svncmd, patt) "{{{2
    let svnout = svnj#utils#execShellCmd(a:svncmd)
    retu filter(split(svnout, "\n"), 'matchstr( v:val, a:patt) != ""')
endf
"2}}}
"1}}}
