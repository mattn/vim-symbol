" Symbols.vim - Buffer-local symbol list
" Author: Matt Sacks <matt.s.sacks@gmail.com>

if exists('g:loaded_symbols') || v:version < 700
  finish
endif
let g:loaded_symbols = 1

" utilities {{{
function! s:gsub(str,pat,rep) abort
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

function! s:sortAlpha(thing, thang)
  return a:thing == a:thang ? 0 : a:thing > a:thang ? 1 : -1 
endfunction

function! s:sortShort(thing, thang)
  let thingLen = len(a:thing)
  let thangLen = len(a:thang)
  return thingLen == thangLen ? 0 :
       \ thingLen > thangLen ? 1 : -1 
endfunction

" sorts a dictionary based on the lower value of a key
function! s:sortLowest(thing, thang) dict
    return self[a:thing] - self[a:thang]
endfunction

function! s:fuzzysub(str)
  return s:gsub(s:gsub(a:str, '\w', '[&].*'), '^', '.*')
endfunction
" END utilities }}}

" current filetypes supported in the pattern dictionary
function! s:checkFiletype()
  return exists('g:symbol_patterns[&ft]')
endfunction

" gather symbols on bufread
function! s:GatherSymbols()
  " whether it's even supported
  if !s:checkFiletype()
    return ''
  endif

  " clear existing symbols
  if exists('b:symbols_gathered')
    unlet b:symbols_gathered
  endif

  let b:symbols_gathered = {}

  let patterns = g:symbol_patterns[&ft]

  " match all symbols
  for line in range(0, line('$'))
    let linestr = getline(line)

    for pattern in patterns
      if linestr =~ pattern
        " the symbol that matches the pattern is the key and the value is the
        " line number
        let b:symbols_gathered[matchstr(linestr, pattern)] = line
        " but don't match a single line more than once?
        break
      endif
    endfor
  endfor
endfunction

" has to return a list of completion candidates on <TAB>
function! s:SymbolGlob(arg,cmdline,cursorpos)
  if !s:checkFiletype()
    return ''
  endif

  " the symbols
  let symbols = keys(b:symbols_gathered)

  " if the user just hit tab with no symbol to search for
  if empty(a:arg)
    " sort the symbols by line number
    return sort(symbols, "s:sortLowest", b:symbols_gathered)
  endif

  " a fuzzy expression of the search
  let fuzzyArg = s:fuzzysub(a:arg)

  " filter the symbols based on the arg
  let symbols = filter(symbols, 'v:val =~ fuzzyArg')
  " return a sorted list with shortest symbol first
  return sort(copy(symbols), "s:sortShort")
endfunction

" gets passed the argument when executed
function! s:Symbol(symbol, ...)
  " nothing was passed
  if empty(a:symbol)
    return ''
  endif

  let symbols = s:SymbolGlob(a:symbol, '', '')

  " if no symbols found
  if empty(symbols)
    return ''
  endif

  " get the first one's line number
  call cursor(b:symbols_gathered[symbols[0]], 0)
  return ''
endfunction

" Symbol command
command! -nargs=? -complete=customlist,s:SymbolGlob Symbol
      \ execute s:Symbol(<f-args>)

" autoload that shit
augroup SymbolList
  autocmd!
  autocmd BufReadPost * call s:GatherSymbols()
  autocmd InsertLeave * call s:GatherSymbols()
augroup END

" vim:ft=vim:fdm=marker:
