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
    call s:RimplementRoute()
  elseif a:type == 'class'
    call s:RimplementClass(cword)
  elseif a:type == 'method'
    call s:RimplementMethod(cword)
  endif
endfunction

function! s:RimplementComplete(_a, _cl, _c)
  return join(s:implementation_types, "\n")
endfunction

" TODO (2014-10-23) Use projections if available -- for the template
function! s:RimplementClass(class_name)
  let class_name = a:class_name
  let location = input("Rimplement Class in which directory: ", "", "dir")
  let underscored_name = lib#Underscore(class_name)

  if isdirectory(location)
    let file_path = simplify(location.'/'.underscored_name.'.rb')
  else
    echoerr "Not a directory: ".location
    return
  endif

  if filereadable(file_path)
    exe 'edit '.file_path
    echomsg "File already exists"
    return
  else
    exe 'edit '.file_path
    call append(0, [
          \ 'class '.class_name,
          \ 'end',
          \ ])
    $delete _
    normal! gg
  endif
endfunction

" TODO (2014-10-23) Rimplement method
" function! s:RimplementMethod(method_name)
"   let method_name = a:method_name
"   let location = input("Rimplement Method where: ", "", "file")

"   if filereadable(file_path)
"     echoerr "File already exists: ".file_path
"     return
"   else
"     exe 'edit '.file_path
"     call append(0, [
"           \ 'class '.class_name,
"           \ 'end',
"           \ ])
"     $delete _
"     normal! gg
"   endif
" endfunction

function s:RimplementRoute()
  if search('''[^'']*\%#[^'']*''', 'nbc', line('.')) > 0
    let description = sj#GetMotion("Vi'")
  elseif search('"[^"]*\%#[^"]*"', 'nbc', line('.')) > 0
    let description = sj#GetMotion('Vi"')
  else
    echomsg "Couldn't find string description"
    return
  endif

  if description !~ '^\k\+#\k\+$'
    echomsg "Description doesn't look like controller#action: ".description
    return
  endif

  let [controller, action] = split(description, '#')
  let filename = 'app/controllers/'.controller.'_controller.rb'
  exe 'edit '.filename

  if !filereadable(filename)
    " then it doesn't exist yet, fill it in
    call append(0, [
          \ 'class '.lib#CapitalCamelCase(controller).'Controller < ApplicationController',
          \ '  def '.action,
          \ '  end',
          \ 'end',
          \ ])
    $delete _
    exe 2
  else
    let class_line = search('^\s*class\>')

    if class_line < 0
      echoerr "Class line not found"
      return
    endif

    if search('^\s*def \zs'.action)
      return
    endif

    let indent = repeat(' ', indent(class_line))

    call append(class_line, [
          \ indent.'  def '.action,
          \ indent.'  end',
          \ '',
          \ ])
  endif

  write
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
