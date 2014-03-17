" =============================================================================
" File:         plugin/svnj.vim
" Description:  Simple plugin for svn
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
com! SVNCommits call svnj#SVNCommits()
com! SVNLog     call svnj#SVNLog()
com! SVNDiff    call svnj#SVNDiff()
com! SVNBlame   call svnj#SVNBlame()

com! -n=? SVNStatus  call svnj#SVNStatus(<f-args>)
com! -n=? -com=dir SVNList    call svnj#SVNList(<q-args>)
"}}}

"leader mappings "{{{
if exists('g:svnj_allow_leader_mappings') && g:svnj_allow_leader_mappings == 1
    map <silent> <leader>b :SVNBlame<CR>
    map <silent> <leader>c :SVNCommits<CR>
    map <silent> <leader>d :SVNDiff<CR>
    map <silent> <leader>s :SVNStatus<CR>  
    map <silent> <leader>su :SVNStatus u<CR>  
    map <silent> <leader>sq :SVNStatus u q<CR>
    map <silent> <leader>sp :SVNStatus u py<CR>
    map <silent> <leader>l :SVNLog<CR>
    map <silent> <leader>L :SVNList<CR>
    map <silent> <leader>q :diffoff! <CR> :q<CR>
endif
"}}}

"}}}
