if exists('g:loaded_rimplement') || &cp
  finish
endif

let g:loaded_rimplement = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

" TODO Implement utility functions to "inject" a method, create a class. Think
" well about the interface: flags, options, different functions for different
" cases?

let s:implementation_types = ['class', 'route', 'method', 'partial']

" :Rimplement <path> <type>
"
command! -nargs=* -complete=file Rimplement call s:Rimplement(<q-args>)
function! s:Rimplement(...)
  let cword = expand('<cword>')

  if cword == ''
    echomsg "Nothing under the cursor"
    return
  endif

  if a:0 >= 1
    let path = a:1
  else
    let path = ''
  endif

  if a:0 >= 2
    let type = a:2

    if index(s:implementation_types, type) < 0
      echomsg "Don't know how to implement: ".type.", try one of: ".join(s:implementation_types, ', ')
      return
    endif
  else
    let type = s:GuessImplementationType(cword)

    if type == ''
      echomsg "Don't know what implementation type to use for: ".cword.", specify one of: ".join(s:implementation_types, ', ')
      return
    endif
  endif

  if type == 'route'
    call rimplement#route#Main()
  elseif type == 'class'
    call rimplement#class#Main(cword, path)
  elseif type == 'method'
    call rimplement#method#Main(cword, path)
  elseif type == 'partial'
    call rimplement#partial#Main()
  else
    throw "Rimplement: Unknown implementation type: ".type
  endif
endfunction

" :RimplementClass <path>
"
command! -nargs=* -complete=dir RimplementClass call s:RimplementClass(<q-args>)
function! s:RimplementClass(...)
  let cword = expand('<cword>')

  if cword == ''
    echomsg "Nothing under the cursor"
    return
  endif

  if a:0 >= 1
    let path = a:1
  else
    let path = ''
  endif

  call rimplement#class#Main(cword, path)
endfunction

" :RimplementMethod <path>
"
command! -nargs=* -complete=file RimplementMethod call s:RimplementMethod(<q-args>)
function! s:RimplementMethod(...)
  let cword = expand('<cword>')

  if cword == ''
    echomsg "Nothing under the cursor"
    return
  endif

  if a:0 >= 1
    let path = a:1
  else
    let path = ''
  endif

  call rimplement#method#Main(cword, path)
endfunction

" :RimplementRoute <route>
"
command! RimplementRoute call s:RimplementRoute()
function! s:RimplementRoute(...)
  call rimplement#route#Main()
endfunction

function! s:GuessImplementationType(word)
  if expand('%:.') == 'config/routes.rb'
    return 'route'
  endif

  if rimplement#SearchUnderCursor('render\s*[''"]\(\f\+\)[''"]', 'n')
    return 'partial'
  endif

  if a:word =~ '^[a-z0-9_]\+$'
    return 'method'
  elseif a:word =~ '^[a-zA-Z0-9]\+$'
    return 'class'
  endif
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
