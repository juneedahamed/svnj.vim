"===============================================================================
" File:         autoload/svnj/svn.vim
" Description:  SVN Commands helpers
" Author:       Juneed Ahamed
"===============================================================================

"SVN command parsers {{{1
fun! svnj#svn#is_cmd(cmd) "{{{2
    return len(matchstr(a:cmd, "^svn ")) > 3
endf
"2}}}

fun! svnj#svn#is_auth_err(response) "{{{2
    return matchstr(a:response, g:svnj_auth_errno) == g:svnj_auth_errno || 
                \ match(a:response, g:svnj_auth_errmsg) > 0 
endf
"2}}}

fun! svnj#svn#fmt_auth_info(cmd) "{{{2
    if g:svnj_auth_disable | retu a:cmd | en

    if len(g:svnj_username) == 0 || len(g:svnj_password) == 0
        let shellout = system(a:cmd)
        if v:shell_error != 0 && svnj#svn#is_auth_err(shellout)
            let [status, shellout] = svnj#svn#exec_with_auth(a:cmd)
        else
            retu a:cmd
        endif
        if status == svnj#failed() | retu a:cmd | en
    endif
        let repstr = "svn --username=". g:svnj_username . " --password=" . g:svnj_password . " "
    retu substitute(a:cmd, "^svn ", repstr, "")
endf
"2}}}

fun! svnj#svn#exec_with_auth(cmd) "{{{2
    let [cmd, status] = [a:cmd, svnj#failed()]
    while 1
        redr
        let g:svnj_username = svnj#utils#input("Username for repository", "", "> ") | redr
        let g:svnj_password = svnj#utils#inputsecret("Password for repository", "> ")
        let repstr = "svn --username=". g:svnj_username . " --password=" . g:svnj_password . " "
        let cmd = substitute(a:cmd, "^svn ", repstr, "")
        let shellout = system(cmd)
        if v:shell_error != 0 && svnj#svn#is_auth_err(shellout)
            let [g:svnj_username, g:svnj_password]= ["",""]
            call svnj#utils#showConsoleMsg("Failed authentication, try again[y/n] : ", 0)
            if svnj#utils#getchar() ==? "y"  | cont | en
        else
            let status = svnj#passed()
        endif
        break
    endwhile
    retu [status, shellout]
endf
"2}}}

fun! svnj#svn#info(url) "{{{2
    let svncmd = 'svn info --non-interactive ' . fnameescape(a:url)
    retu svnj#utils#execShellCmd(svncmd)
endf
"2}}}

fun! svnj#svn#infolog(url) "{{{2
    let result = ""
    try
        let svncmd = 'svn info --non-interactive -' . a:url
        let result = result . svnj#utils#execShellCmd(svncmd)
        let svncmd = 'svn log -v --non-interactive -' . a:url
        let result = result . svnj#utils#execShellCmd(svncmd)
    catch
        call svnj#utils#dbgMsg("svnj#svn#infolog", v:exception)
        let result = v:exception
    endtry
    retu result
endf
"2}}}

fun! svnj#svn#log_stoponcopy(url) "{{{2
    try
        let svncmd = 'svn log --non-interactive --stop-on-copy -q ' .
                \ fnameescape(svnj#utils#expand(a:url))

        let shellout = svnj#utils#execShellCmd(svncmd)
        let shellist = reverse(split(shellout, '\n'))
        for i in range(0, len(shellist)-1)
            let curline = shellist[i]
            if len(matchstr(curline, '^r')) > 0 
                let contents = split(curline, '|')
                let revision = svnj#utils#strip(contents[0])
                retu revision
            endif
        endfor
    catch:
        call svnj#utils#dbgMsg("svnj#svn#log_stoponcopy", v:exception)
    endtry
    retu ""
endf
"2}}}

fun! svnj#svn#add(addfileslist) "{{{2
    let addfileslist = map(a:addfileslist, 'fnameescape(v:val)')
    let filestoadd = join(addfileslist, " ")

    echohl Title | echo "Will add " . len(a:addfileslist) . " files"
    echohl Directory | echo join(addfileslist, "\n")
    echohl Question | echo "y to continue Any key to cancel" | echohl None

    if svnj#utils#getchar() !=? 'y' | retu "Aborted" | en
    if filestoadd != ""
        let svncmd = "svn add --non-interactive " . filestoadd
        retu svnj#utils#execShellCmd(svncmd)
    endif
    retu ""
endf
"2}}}

fun! svnj#svn#commit(commitlog, commitfileslist) "{{{2
    let commitfileslist = map(a:commitfileslist, 'fnameescape(v:val)')
    let filestocommit = join(commitfileslist, " ")
    if a:commitlog == "!"
        let svncmd = "svn ci --non-interactive -m \"\" " . filestocommit
    else
        let svncmd = "svn ci --non-interactive -F " . a:commitlog . " " . filestocommit
    endif
    echo "Please wait sent command waiting for response ..."
    retu svnj#utils#execShellCmd(svncmd)
endf
"2}}}

fun! svnj#svn#copyrepo(commitlog, urls) "{{{2
    let urls = map(a:urls, 'fnameescape(v:val)')
    let urlstr = join(urls, " ")
    if a:commitlog == "!"
        let svncmd = "svn cp --non-interactive -m \"\" " . urlstr
    else
        let svncmd = "svn cp --non-interactive -F " . a:commitlog . " " . urlstr
    endif
    echo "Please wait sent command waiting for response ..."
    retu [svnj#passed(), svnj#utils#execShellCmd(svncmd)]
endf
"2}}}

fun! svnj#svn#copywc(urls) "{{{2
    let urls = map(a:urls, 'fnameescape(v:val)')
    let urlstr = join(urls, " ")
    let svncmd = "svn cp --non-interactive " . urlstr
    echohl Title | echo "Will execute the following command"
    echohl Directory | echo svncmd
    echohl Question | echo "Press y to continue, enter to cancel" 
    echohl None
    let choice = input("Enter choice: ")
    if choice ==? "y"
        echo "Please wait sent command waiting for response ..."
        retu [svnj#passed(), svnj#utils#execShellCmd(svncmd)]
    else
        retu [svnj#failed(), "Aborted"]
    endif
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
    retu fileurl
endf
"2}}}

fun! svnj#svn#issvndir(absfpath) "{{{2
    try
        let svncmd = 'svn info --non-interactive ' . fnameescape(svnj#utils#expand(a:absfpath))
        let nodekindline = s:matchShellOutput(svncmd, "^Node Kind:")
        if len(nodekindline) > 0
            retu matchstr(nodekindline, "directory") != ""
        endif
    catch | retu svnj#failed() | endtry
    retu svnj#failed()
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
    retu metad
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
    retu metad
endf
"2}}}

fun! svnj#svn#blankMeta() "{{{2
    let metad = {}
    let metad.origurl = ""
    let metad.url = ""
    let metad.fpath = ""
    let metad.wrd=""
    retu metad
endf
"2}}}

fun! svnj#svn#getMetaURL(url) "{{{2
    let metad = {}
    let metad.origurl = a:url
    let metad.url = a:url
    let metad.fpath = ""
    let metad.isdir = 0
    let metad.wrd=svnj#svn#workingRoot()
    retu metad
endf
"2}}}

fun! svnj#svn#workingRoot() "{{{2
    retu len(g:p_wcrp) == 0 || svnj#utils#isdir(g:p_wcrp) == 0 ?
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
                let tmpworkingdir = svnj#utils#strip(join(tokens[1:], ':'))
                if svnj#utils#isdir(tmpworkingdir) | retu tmpworkingdir | en
            endif
        endif
    catch
    endtry
    retu getcwd()
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
                retu root
        endif
    catch
    endtry
    retu getcwd()
endf
"2}}}

fun! svnj#svn#svnRootVersion(workingcopydir) "{{{2
    let svncmd = 'svn log --non-interactive -l 1 ' . 
                \ a:workingcopydir . ' | grep ^r'
    let shellout = svnj#utils#execShellCmd(svncmd)
    let revisionnum = svnj#utils#strip(split(shellout, '|')[0])
    retu revisionnum
endf
"2}}}

fun! svnj#svn#validURL(svnurl) "{{{2
    let svncmd = 'svn info --non-interactive ' . a:svnurl
    try
        let shellout = svnj#utils#execShellCmd(svncmd)
    catch | retu svnj#failed() | endtry
    retu svnj#passed()
endf
"2}}}

fun! svnj#svn#validateSVNURLInteractive(sysURL) "{{{2
    if len(a:sysURL) == 0 || !svnj#svn#validURL(a:sysURL)
        echohl WarningMsg | echo 'Failed to construct svn url: '
                    \ | echo a:sysURL | echohl None
        let inputurl = input('Enter URL : ')
        if len(inputurl) > 1 && svnj#svn#validURL(inputurl)
            retu inputurl
        endif
    else
        retu a:sysURL
    endif
    throw 'Invalid URL'
endf 
"2}}}

fun! svnj#svn#isTrunk(URL) "{{{2
    if svnj#svn#isBranch(a:URL) | retu 0 | en
    retu g:p_turl != '' && stridx(a:URL, g:p_turl, 0) == 0
endf
"2}}}

fun! svnj#svn#isBranch(URL) "{{{2
    retu len(filter(copy(g:p_burls), 'stridx(a:URL, v:val,0) == 0')) > 0
endf
"2}}}

fun! svnj#svn#isWCDir() "{{{2
    let svncmd = 'svn info --non-interactive ' . getcwd()
    try
        let shellout = svnj#utils#execShellCmd(svncmd)
    catch | retu svnj#failed() | endtry
    retu svnj#passed()
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
        if a:ignore_dirs == 1 && svnj#utils#isdir(line) | con | en
        let linenum += 1
        let line = printf("%4d:%s", linenum, line)
        call add(entries, line)
    endfor
    unlet! shelloutlist
    retu entries
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
            "call svnj#utils#dbgMsg("At globsvnrec", v:exception)
        endt
    endwhile
    unlet! tdirs

    call svnj#caop#cache("repo", burl, files)
    retu files
endf

fun! s:filedirs(curdir, flist)
    let [files, dirs] = [[], []]
    for entry in a:flist
        if len(matchstr(entry, g:p_ign_fpat)) != 0 | con | en
        call call('add', [svnj#utils#isSvnDirReg(entry) ? dirs : files, 
                    \ svnj#utils#joinPath(a:curdir,entry)])
    endfor
    retu [files, dirs]
endf
"2}}}

fun! svnj#svn#logs(maxlogs, svnurl) "{{{2
    let svncmd = 'svn log --non-interactive -l ' . a:maxlogs .
                \ ' ' . fnameescape(svnj#utils#expand(a:svnurl))
    let shellout = svnj#utils#execShellCmd(svncmd)
    let shellist = split(shellout, '\n')
    unlet! shellout
    let logentries = []
    let g:svnj_logversions = []
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
                        call add(g:svnj_logversions, revision)
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
    retu [logentries, svncmd]
endf
"2}}}

fun! svnj#svn#oldandnewrevisions(revision, svnurl) "{{{2
    let [newrev, olderrev] = ["", ""]
    try
        let idxcurrev = index(g:svnj_logversions, a:revision)
        if idxcurrev != -1
            let newrev = idxcurrev > 0 ? g:svnj_logversions[idxcurrev - 1] : ""
            let olderrev = idxcurrev <= len(g:svnj_logversions) - 2 ? g:svnj_logversions[idxcurrev + 1] : ""
        endif
    catch
        call svnj#utils#dbgMsg("At svnj#svn#oldandnewrevisions", v:exception)
    endtry
    retu [newrev, olderrev]
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
    retu [statuslist, a:svncmd]
endf
"2}}}

fun! svnj#svn#affectedfilesAcross(url, revisionA, revisionB) "{{{2
    let revisiondiff = a:revisionA.':'.a:revisionB
    let svncmd = 'svn diff --summarize --non-interactive  -' . 
                \ revisiondiff . ' '. a:url
    retu svnj#svn#summary(svncmd)
endf
"2}}}

fun! svnj#svn#affectedfiles(url, revision) "{{{2
    let revision = matchstr(a:revision, "\\d\\+")
    let svncmd = 'svn diff --summarize --non-interactive -c' .
                \ revision . ' ' . a:url
    retu svnj#svn#summary(svncmd)
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
    retu revision
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
    retu lastChngdRev
endf
"2}}}

fun! s:matchShellOutput(svncmd, patt) "{{{2
    let svnout = svnj#utils#execShellCmd(a:svncmd)
    retu filter(split(svnout, "\n"), 'matchstr( v:val, a:patt) != ""')
endf
"2}}}
"1}}}
