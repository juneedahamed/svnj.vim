#svnj.vim
VIM (VIM 7 and up) plugin for subversion (svn)
Support for browsing the repository, working copy, bookmarks.

##Screen shots

![svnbrowse][1]

![svnbrowserepo][2]

![svnlog][3]

![svnstatus][4]

![svnlog2][5]

![svnlogbranches][6]

##Supported OS
MacOSX/Linux

##Supported operations

 **svn log**, **svn status**, **svn diff**, **svn blame**, **svn list**

##Features
* <b>SVNBrowse</b>

    Browse the svn repository, working copy files from within vim. Provision to 
    bookmark files/directories for current vim session or provide permanent 
    bookmarks/favorites from .vimrc. Ability to open/openall/diff the browsed files.
    
    Available options for browsing are
    
        - SVNBrowse
        - SVNBrowseRepo
        - SVNBrowseWorkingCopy
        - SVNBrowseMyList
        - SVNBrowseBookMarks

    Some of the operations supported are
    
        - Open directory/files
        - Recursive list directories
        - Navigate up one dir
        - Go to Start/Top
        - Open all files
        - Display log of a file/dir
        - Diff the current file with the file in buffer
        - Mark for open/diff
        - Bookmark file for current session
    
* <b>SVNLog</b>

	Get the revisions of file in buffer. With the list of revisions from the output.
    
     - open/diff required file revision 
     - mark required revision to open/diff
     - list trunk
     - list branches
     - diff/open files across branches/trunk


*  <b>SVNStatus</b>

	Get the output of svn st. With the listed files
	
       - open any/all files
       - mark required files to open
       - pass q/u option to svn st
       - global option to ignore files

* <b>SVNComitts</b>

       Get the list of files checked in across project revision. This command lists the output of svn log of the project directory.  
     
     - list HEAD/PREV
     - mark revisions for comparing across marked revisions 
     - open any/all/marked files listed
     
     
* <b>SVNDiff</b>

      Immediate diff the file in buffer with the previous revision.<br/>
      For diff with selected revision use SVNLog


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
6. `:SVNList`
7. `:SVNListRec`
7. **`:help svn`**

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
    
[1]: http://i.imgur.com/GplIbo2.png
[2]: http://i.imgur.com/Vl9pmoI.png
[3]: http://i.imgur.com/oY6E2kP.png
[4]: http://i.imgur.com/I69Mny2.png
[5]: http://i.imgur.com/QskUigu.png
[6]: http://i.imgur.com/GTBhjVT.png

