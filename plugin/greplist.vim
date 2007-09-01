"============================================================================"
"
"  This plugin helps to maintain a list of frequently used vimgrep locations.
"  It defines commands to edit a list and to perform a search in the selected
"  locations.
"
"  Copyright (c) Yuri Klubakov
"
"  Author:      Yuri Klubakov <yuri.mlists at gmail dot com>
"  Version:     1.0 (2007-08-30)
"  Requires:    Vim 7 (vimgrep)
"  License:     GPL
"
"  Description:
"
"    :GrepListConfig command loads a list for editing.  A list is kept in
"    "$HOME/_vimgrep" file or in "$VIM/_vimgrep" file if $HOME is not defined.
"    If "_vimgrep" file does not exist or empty, a sample list is created.
"    Status line shows useful normal mode mappings:
"      'q' - abandon any changes and wipe the buffer
"      's' - save the changes and wipe the buffer
"      ' ' - select/deselect current line (selected lines start with '+')
"
"    :GrepListFind(mode) command prompts for the string to find and starts
"    the vimgrep search in the selected locations.  The default value for the
"    search string is either the current selection (mode != 0) or the current
"    word (mode == 0).  Plugin automatically surrounds the search string with
"    '/' and adds 'j' option.
"
"============================================================================"

if v:version < 700 || exists('loaded_greplist')
	finish
endif
let loaded_greplist = 1

let s:save_cpo = &cpo
set cpo&vim

"============================================================================"

function! s:LoadConfigFile()
	if !exists("s:config_file")
		let path = ($HOME != '') ? $HOME : $VIM
		let s:config_file = expand(path . "/_vimgrep")
	endif
	execute 'silent! edit ' . s:config_file
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nowrap
	setlocal nobuflisted
endfunction

"============================================================================"

function! s:Find(mode)
	cgetexpr ''             " clear the quickfix window

	if !exists("s:active_list")
		let b_cur = winbufnr(0)
		call s:LoadConfigFile()
		call s:FillActiveList()
		execute b_cur . 'b'
	endif

	if empty(s:active_list)
		echoerr "Call GrepListConfig first to set up greplist locations"
		return
	endif

	" default search string is the current word or visual selection
	if a:mode == 0
		let s = expand("<cword>")
	else
		let s = escape(strpart(getline('.'), col("'<lt>") - 1, col("'>") - col("'<lt>") + 1), '\')
	endif
	let pattern = input("Enter a string to find: ", s)
	if pattern == ''
		copen
		return
	endif

	for path in s:active_list
		execute 'silent! vimgrepadd! /' . pattern . '/j ' . path
	endfor

	copen
endfunction

"============================================================================"

function! s:FillActiveList()
	let s:active_list = []
	for s in getline(1, '$')
		if s[0] == '+'
			call add(s:active_list, substitute(s, '+ *', '', ''))
		endif
	endfor
endfunction

"============================================================================"

function! s:ToggleLine()    " Select/deselect current line
	let s = getline('.')
	if s[0] == '+'
		execute 'normal 0r '
	elseif s[0] == ' '
		execute 'normal 0r+'
	endif
	if line('.') < line('$')
		normal j
	endif
endfunction

"============================================================================"

function! s:ExitConfig(save)
	if (a:save)
		silent! update!
		call s:FillActiveList()
	endif
	execute s:b_cur . 'b!'
endfunction

"============================================================================"

function! s:Config()
	let s:b_cur = winbufnr(0)
	call s:LoadConfigFile()
	nnoremap <buffer> <silent> q :call <SID>ExitConfig(0)<CR>
	nnoremap <buffer> <silent> s :call <SID>ExitConfig(1)<CR>
	nnoremap <buffer> <silent> <SPACE> :call <SID>ToggleLine()<CR>
	if line('$') == 1 && getline(1) == ''
		normal iThis is a sample greplist configuration file - edit and save.
		normal oThe plus sign in the first column marks selected lines.
		normal oSee status line for defined normal mode mappings.
		normal o<SPACE> works only on lines that start with ' ' or '+'.
		normal o
		normal o  ~/*
		normal o
		normal i+ **/*.cpp
		normal o+ **/*.h
		normal o+ c:/projects/common/*.h
		normal o  c:/Program\ Files/Microsoft\ Visual\ Studio\ 8/VC/include/**/*.h
		normal 0gg
	endif
	echon "'q' - close, 's' - save and close, <SPACE> - select/deselect line"
endfunction

"============================================================================"

command! -nargs=0 GrepListConfig call s:Config()
command! -nargs=1 GrepListFind call s:Find(<args>)

let &cpo = s:save_cpo

" vim: set ts=4 sw=4 noet :
