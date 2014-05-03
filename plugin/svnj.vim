" =============================================================================
" File:         plugin/svnj.vim
" Description:  Plugin for svn
" Author:       Juneed Ahamed
" License:      Distributed under the same terms as Vim itself. See :help license.
" =============================================================================

"plugin/svnj.vim "{{{

"init "{{{
if ( exists('g:loaded_svnj') && g:loaded_svnj ) || v:version < 700 || &cp
	fini
en
let g:loaded_svnj = 1
"}}}

"command mappings "{{{
com! SVNDiff    call svnj#SVNDiff()
com! SVNBlame   call svnj#SVNBlame()
com! SVNInfo   call svnj#SVNInfo()
com! SVNClearCache call svnj#caop#ClearAll()

com! SVNBrowse call svnj#brwsr#SVNBrowse()
com! SVNBrowseMyList call svnj#brwsr#SVNBrowseMyList()
com! SVNBrowseBookMarks call svnj#brwsr#SVNBrowseMarked()

com! -n=* -com=dir SVNStatus  call svnj#status#SVNStatus(<f-args>)

com! -n=? -com=file SVNLog  call svnj#log#SVNLog(<q-args>)
com! -n=? -com=dir SVNCommits call svnj#cmmit#SVNCommits(<q-args>)
com! -n=? -com=dir SVNBrowseRepo call svnj#brwsr#SVNBrowseRepo(<q-args>)
com! -n=? -com=dir SVNBrowseWorkingCopy call svnj#brwsr#SVNBrowseWC(0, <q-args>)
com! -n=? -com=dir SVNBrowseWorkingCopyRec call svnj#brwsr#SVNBrowseWC(1, <q-args>)
"}}}

"leader mappings "{{{
if exists('g:svnj_allow_leader_mappings') && g:svnj_allow_leader_mappings == 1
    map <silent> <leader>B :SVNBlame<CR>
    map <silent> <leader>c :SVNCommits<CR>
    map <silent> <leader>d :SVNDiff<CR>
    map <silent> <leader>s :SVNStatus<CR>  
    map <silent> <leader>su :SVNStatus u<CR>
    map <silent> <leader>sq :SVNStatus u q<CR>
    map <silent> <leader>sc :SVNStatus .<CR>
    map <silent> <leader>l :SVNLog<CR>
    map <silent> <leader>b :SVNBrowse<CR>
    map <silent> <leader>bl :SVNBrowseMyList<CR>
    map <silent> <leader>br :SVNBrowseRepo<CR>
    map <silent> <leader>bw :SVNBrowseWorkingCopy<CR>
    map <silent> <leader>bb :SVNBrowseBookMarks<CR>
    map <silent> <leader>bm :SVNBrowse<CR>
    map <silent> <leader>q :diffoff! <CR> :q<CR>
endif
"}}}

"}}}
