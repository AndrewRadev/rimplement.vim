if exists('g:loaded_rimplement') || &cp
  finish
endif

let g:loaded_rimplement = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

let s:implementation_types = ['class', 'route', 'method']

command! -nargs=1 -complete=custom,s:RimplementComplete Rimplement call s:Rimplement(<q-args>)
function! s:Rimplement(type)
  let cword = expand('<cword>')

  if index(s:implementation_types, a:type) < 0
    echomsg "Don't know how to implement: ".a:type.", try one of: ".join(s:implementation_types, ', ')
    return
  endif

  if cword == ''
    echomsg "Nothing under the cursor"
    return
  endif

  if a:type == 'route'
    call rimplement#route#Main()
  elseif a:type == 'class'
    call rimplement#class#Main(cword, "")
  elseif a:type == 'method'
    call rimplement#method#Main(cword)
  endif
endfunction

function! s:RimplementComplete(_a, _cl, _c)
  return join(s:implementation_types, "\n")
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
