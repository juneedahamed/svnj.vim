" =============================================================================
" File:         autoload/dict.vim
" Description:  The main dict used to populate contents
" Author:       Juneed Ahamed
" =============================================================================

"svnj#dict.vim {{{1

"script vars {{{2
let [s:metakey, s:logkey, s:statuskey, s:commitskey, s:browsekey, 
            \ s:menukey, s:errorkey] = svnj#utils#getkeys()
"2}}}

"dict proto {{{2
let s:entryd = {'contents':{}, 'ops':{}}
let s:dict = {}
fun! svnj#dict#new(...)
    call s:dict.discardEntries()
    let obj = copy(s:dict)
    let obj.title = a:0 >= 1 ? a:1 : ''
    let obj.idx = 0
    let obj.opdsc = ''
    let obj.bparent = ""
    let obj.brecursive = 0
    let obj.hasbufops = 0
    if a:0 >= 2 | call extend(obj, a:2) | en
    retu obj
endf

fun! s:dict.setMeta(meta) dict
    let self.meta = a:meta
endf

fun! s:dict.nextkey() dict
    let self.idx += 1
    retu self.idx
endf

fun! s:dict.lines() dict
    let [dislines, mlines, lines] = [[], [], []]
    if has_key(self, s:logkey) | call extend(lines, self[s:logkey].format()) | en
    if has_key(self, s:statuskey) | call extend(lines, self[s:statuskey].format()) | en
    if has_key(self, s:commitskey) | call extend(lines, self[s:commitskey].format()) | en
    if has_key(self, s:browsekey) | call extend(lines, self[s:browsekey].format_browsed()) | en
    call extend(dislines, lines[ : g:svnj_max_buf_lines])

    if has_key(self, s:menukey) | call extend(mlines, self[s:menukey].format()) | en
    call extend(dislines, mlines)
    call extend(lines, mlines)
    retur [lines, dislines]
endf

fun! s:dict.entries() dict
    let rlst = []
    if has_key(self, s:logkey) | call add(rlst, self.logd) | en
    if has_key(self, s:statuskey) | call add(rlst, self.statusd) | en
    if has_key(self, s:commitskey) | call add(rlst, self.commitsd) | en
    if has_key(self, s:browsekey) | call add(rlst, self.browsed) | en
    if has_key(self, s:menukey) | call add(rlst, self.menud) | en
    retu rlst
endf

fun! s:dict.discardEntries() dict
    for ekey in svnj#utils#getEntryKeys()
        if has_key(self, ekey) | call remove(self, ekey) | en
    endfor
    let self.opdsc = ""
endf

fun! s:dict.clear() dict
    call self.discardEntries()
    let self.idx = 0
    if has_key(self, s:metakey) | call remove(self, s:metakey) | en
endf

fun! s:dict.getOps(key) dict
    if a:key == "err" && self.hasError() && has_key(self.error, "ops") 
        retu self.error.ops
    endif
    for thedict in self.entries()
        if has_key(self, s:browsekey) | retu thedict.ops | en
        if has_key(thedict.contents, a:key) | retu thedict.ops | en
    endfor
    retu {}
endf

fun! s:dict.getAllOps() dict
    let allops = {}
    for thedict in self.entries()
        if has_key(thedict, 'ops') | call extend(allops, thedict.ops) | en
    endfor
    if self.hasError() && has_key(self.error, "ops") 
        call extend(allops, self.error.ops)
    endif
    retu allops
endf

fun! s:dict.setOpsDescr() dict
    let ops=""
    let hasbufops = 0
    for [key, thedict] in items(self.getAllOps())
        let ops = ops . thedict.dscr . ' '
        if has_key(thedict, "bop") | let hasbufops = 1 | en
    endfor
    let self.opdsc = ops
    let self.hasbufops = hasbufops
endf

fun! s:dict.hasError() dict
    retu has_key(self, s:errorkey)
endf

fun! s:dict.browseDict() dict
    if has_key(self, s:browsekey) 
        retu self[s:browsekey].contents
    endif
    retu {}
endf

fun! s:entryd.format() dict
    let lines = []
    for key in sort(keys(self.contents), 'svnj#utils#sortConvInt')
        let line = printf("%4d:%s", key, self.contents[key].line)
        call add(lines, line)
    endfor
    retu lines
endf
"2}}}

fun! svnj#dict#addBrowseEntries(dict, key, entries, ops)
    if !has_key(a:dict, a:key)
        let a:dict[a:key] = deepcopy(s:entryd)
    endif
    let a:dict[a:key].contents = a:entries
    call svnj#dict#addOps(a:dict, a:key, a:ops)
endf

fun! s:entryd.format_browsed() dict
    retu self.contents
endf

"Helpers {{{2
fun! svnj#dict#addErr(dict, descr, msg)
    let [estart, eend, errsyntax] = svnj#utils#getErrSyn()
    let a:dict.error = {}
    let a:dict.error.line = estart.a:descr . ' | ' . a:msg
endf

fun! svnj#dict#addErrUp(dict, descr, msg)
    call svnj#dict#addErr(a:dict, a:descr, a:msg)
    let a:dict.error.ops = svnj#utils#upop()
    call a:dict.setOpsDescr()
endf

fun! svnj#dict#addErrTop(dict, descr, msg)
    call svnj#dict#addErr(a:dict, a:descr, a:msg)
    let a:dict.error.ops = svnj#utils#topop()
    call a:dict.setOpsDescr()
endf

fun! svnj#dict#addOps(dict, key, ops)
    if !has('gui_running') && has_key(a:ops, "\<C-s>")
        call remove(a:ops, "\<C-s>")
    endif
    if !has_key(a:dict, a:key) | th a:key.' Not Present' | en
    if len(a:ops) > 0 | call extend(a:dict[a:key].ops, a:ops) | en
    call a:dict.setOpsDescr()
endf

fun! svnj#dict#addEntries(dict, key, entries, ops)
    if !has_key(a:dict, a:key)
        let a:dict[a:key] = deepcopy(s:entryd)
    endif

    for entry in a:entries
        let idx = a:dict.nextkey()
        let a:dict[a:key].contents[idx] = entry
    endfor
    call svnj#dict#addOps(a:dict, a:key, a:ops)
endf

"convert = branch2trunk | branch2branch | trunk2branch
fun! svnj#dict#menuItem(title, callback, convert)
    let [menustart, menuend, msyn] = svnj#utils#getMenuSyn()
    let menu_item = {}
    let menu_item.line = menustart.a:title.menuend
    let menu_item.title = a:title
    let menu_item.callback = a:callback
    let menu_item.convert = a:convert
    retu menu_item
endf
"2}}}
"1}}}
