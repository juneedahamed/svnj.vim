#svnj.vim
Vim (v7 and up) plugin for subversion (svn)

##Screen shots

![Alt text] (https://github.com/juneedahamed/screenshots/blob/master/screen1.png?raw=true)

![Alt text] (https://github.com/juneedahamed/screenshots/blob/master/svnstatus.png?raw=true)

##Supported OS
MacOSX/Linux

##Supported operations

1. **svn log**
2. **svn status**
3. **svn diff**
4. **svn blame**


##Installation

###Options 1:  (Pathogen Users)

1. cd ~/.vim/bundle
2. git clone git@github.com:juneedahamed/svnj.vim.git

###Option 2:

1. git clone git@github.com:juneedahamed/svnj.vim.git
2. copy files from svnj.vim/plugin to ~/.vim/plugin
3. copy files from svnj.vim/autoload to ~/vim/autoload
4. copy files from svnj.vim/doc to ~/vim/doc
5. Run at vim's command    :helptags doc

##Basic Usage

Run from vim commandline

1. `:SVNBlame`
2. `:SVNDiff`
3. `:SVNLog`
4. `:SVNStatus`
5. `:SVNCommits`
6. **`:help svn`**

##Settings .vimrc 

####To list all branches or trunk

    Optional settings when available will provide menu's to navigate available
    branches/trunk

1. At .vimrc add  `let g:svnj_branch_url = svn://127.0.0.1/Path/until/trunk`
2. At .vimrc add  `let g:svnj_branch_url = svn://127.0.0.1/Path/until/branches`

   For more info run `:help svnj-options`

####To allow default mappings
1. At .vimrc addd  `let g:svnj_allow_leader_mappings=1`

    For more info run at command line `:help svnj-mappings`
