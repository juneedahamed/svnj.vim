#svnj.vim

#NOTE:  New and Improved version of the script with support for SVN, GIT, HG and BZR is now available at https://github.com/juneedahamed/vc.vim

Users of svnj.vim just need to change the .vimrc settings from svnj_ to vc_ after cloning the new script
 
  
VIM (VIM 7 and up) plugin for subversion (svn)
Support for browsing the repository, working copy, bookmarks.

Also at vim.org : http://www.vim.org/scripts/script.php?script_id=4888

##Screen shots

![svnbrowse][1]

![svnbrowserepo][2]

![svnlog][3]

![svnstatus][4]

![svnlog2][5]

![svnlogbranches][6]


##Supported operations

 **svn add**, **svn commit**, **svn checkout**, **svn cp**,
 **svn log**, **svn status**, **svn diff**, **svn blame**, **svn list**

##Features
* <b>SVNBrowse</b>

    Browse the svn repository, working copy files from within vim. Options to 
    bookmark files/directories for current vim session or provide permanent 
    bookmarks/favorites.
    
    Available options for browsing are
    
        - SVNBrowse - Provides a menu for the Browsing commands
        - SVNBrowseRepo  - Lists files from repository
        - SVNBrowseWorkingCopy - Lists files from current dir
        - SVNBrowseMyList  - Lists files specifies from g:svnj_browse_mylist
        - SVNBrowseBookMarks - Lists Bookmarked files/dirs
        - SVNBrowseBuffer - List Buffer files

    Some of the operations supported are
    
        - Open directory/files
        - Recursive list directories
        - Navigate up one dir
        - Go to Start/Top
        - Open all files
        - Diff the current file with the file in buffer
        - Mark for open/diff
        - Bookmark file/dir
        - SVN Add
        - SVN Commit
        - SVN Checkout 
        - SVN Log
    
* <b>SVNLog</b>

	Get the revisions of file in buffer. With the list of revisions from the output.
    
     - Open/diff required file revision (new buffer, vertical split)
     - Mark required revision to open/diff
     - List trunk
     - List branches
     - Diff/open files across branches/trunk
     - List affected files 
     - SVN Diff with options :HEAD or :PREV
     - SVN Info

*  <b>SVNStatus</b>

	Get the output of svn st. With the listed files
	
       - Open any/all files
       - Mark required files to open
       - Pass q/u option to svn st
       - Global option to ignore files
       - Diff files
       - SVN Info
       - SVN Add
       - SVN Commit


* <b>SVNCommit</b>

     Commits the current file in buffer when no arguments are passed, Applicable arguments are 
     file/directory to commit. A new buffer will be opened to accept commit comments. The
     buffer will list the files which are candidates for commit. Files/Directories can also be
     updated in this buffer. A commit can be forced with no comments with a bang.
     SVNCommit is supported as a command and also as an operation from the SVNStatus output 
     window. see :help SVNStatus
     
* <b>SVNBlame</b>
     
     Vertically splits the blame info for the file in bufffer. Scrollbinds to the file.
     Takes files as arguments

* <b>SVNDiff</b>

    Immediate diff the file in buffer with the previous revision. For diff with required/any
    revision use SVNLog. If there are more than one file in buffer Ctrl-n/Ctrl-p will
    close the current diff and move to the next/prev file in buffer and opens a diff for
    the said file

* <b>SVNClearCache</b>
     
    The cache / persistency is not enabled by default. please see help SVNClearCache for more info.

* <b>SVNInfo</b>
     
    Will display svn info for the file in buffer when no args, Accepts file/dirs as args

* <b>SVNCommits</b>

       Get the list of files checked in across project revision. This command lists the output of svn log of the project directory.  
     

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
5. `:SVNCommit`
6. `:SVNCommits`
7. `:SVNAdd`
8. `:SVNBrowse`
9. `:SVNBrowseWorkingCopy`
10. `:SVNBrowseRepo`
11. `:SVNBrowseBookMarks`
12. `:SVNBrowseMyList`
12. `:SVNBrowseBuffer`
13. **`:help svn`**

##Settings .vimrc 

####Custom settings

    `let g:svnj_custom_statusbar_ops_hide = 1`
    
    Supported operations are listed on the status line of the svnj_window. With growing support for
    many commands, recomend to hide it. You can still have a quick glance of supported operations by
    pressing ? (question-mark)

####Cache settings

    `let g:svnj_browse_cache_all = 1`

    This enables caching, Listing of files will be faster, On MAC/Unix the default location is $HOME/.cache.
    A new directory svnj will be created in the specified directory.

    For windows this option must be specified along with the cache dir
        `let g:svnj_cache_dir="C:/Users/user1"`

####To list all branches or trunk

   Optional settings when available will provide menu's to navigate available branches/trunk

   `let g:svnj_branch_url = ["svn://127.0.0.1/Path/until/branches/", "svn://127.0.0.1/Path/until/tags"]`

   `let g:svnj_trunk_url = "svn://127.0.0.1/Path/until/trunk"`

   For more info run `:help svnj-options`

####To allow default mappings
1. `let g:svnj_allow_leader_mappings=1`

    For more info run at command line `:help svnj-mappings`
    
[1]: http://i.imgur.com/GplIbo2.png
[2]: http://i.imgur.com/Vl9pmoI.png
[3]: http://i.imgur.com/oY6E2kP.png
[4]: http://i.imgur.com/I69Mny2.png
[5]: http://i.imgur.com/QskUigu.png
[6]: http://i.imgur.com/GTBhjVT.png

