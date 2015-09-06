" Vim syntax file
" Language: SVNJ 'svn blame' output
"

if exists("b:current_syntax")
	finish
endif

syn match svnTimestamp /^\S\+ \S\+/ nextgroup=svnRevision skipwhite
syn match svnRevision /\S\+/ nextgroup=svnAuthor contained skipwhite
syn match svnAuthor /\S\+/ contained skipwhite

" Apply highlighting
let b:current_syntax = "svnjblame"

hi def link svnRevision Number
hi def link svnAuthor Operator
hi def link svnTimestamp Comment
