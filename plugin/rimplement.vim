if exists('g:loaded_rimplement') || &cp
  finish
endif

let g:loaded_rimplement = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

let s:implementation_types = ['class', 'route', 'method']

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
  endif
endfunction

function! s:GuessImplementationType(word)
  if expand('%:.') == 'config/routes.rb'
    return 'route'
  elseif a:word =~ '^[a-z0-9_]\+$'
    return 'method'
  elseif a:word =~ '^[a-zA-Z0-9]\+$'
    return 'class'
  endif
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
