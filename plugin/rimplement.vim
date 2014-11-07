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
    call s:RimplementClass(cword, "")
  elseif a:type == 'method'
    call s:RimplementMethod(cword)
  endif
endfunction

function! s:RimplementComplete(_a, _cl, _c)
  return join(s:implementation_types, "\n")
endfunction

" TODO (2014-10-23) Use projections if available -- for the template
function! s:RimplementClass(class_name, location)
  let class_name = a:class_name

  if a:location != ""
    let location = a:location
  else
    let location = input("Implement Class in which directory: ", "", "dir")
  endif

  if location == ''
    return
  endif

  let underscored_name = s:Underscore(class_name)

  if isdirectory(location)
    let file_path = simplify(location.'/'.underscored_name.'.rb')
  else
    echoerr "Not a directory: ".location
    return
  endif

  if filereadable(file_path)
    exe 'edit '.file_path
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

function! s:RimplementMethod(method_name)
  let method_name = a:method_name
  let location = input("Implement Method in which file: ", "", "file")

  " TODO (2014-11-07) Infer class from context?
  let class_name = s:CapitalCamelCase(fnamemodify(location, ':t:r'))

  call s:RimplementClass(class_name, s:Dirname(location))

  " TODO (2014-11-07) Infer location of method based on class contents?
  " TODO (2014-11-07) Implement methods in the same class under the "private" label?
  "
  let class_line = search('class '.class_name, 'n')
  if class_line <= 0
    echomsg "Couldn't find the definition of the ".class_name." class"
    return
  endif

  call append(class_line, [
        \   '  def '.method_name,
        \   '  end',
        \   ''
        \ ])
endfunction

function! s:Dirname(file)
  return fnamemodify(a:file, ':h')
endfunction

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
          \ 'class '.s:CapitalCamelCase(controller).'Controller < ApplicationController',
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

" Capitalize first letter of argument:
" foo -> Foo
function! s:Capitalize(word)
  return substitute(a:word, '^\w', '\U\0', 'g')
endfunction

" CamelCase underscored word:
" foo_bar_baz -> fooBarBaz
function! s:CamelCase(word)
  return substitute(a:word, '_\(.\)', '\U\1', 'g')
endfunction

" CamelCase and Capitalize
" foo_bar_baz -> FooBarBaz
function! s:CapitalCamelCase(word)
  return s:Capitalize(s:CamelCase(a:word))
endfunction

" Underscore CamelCased word:
" FooBarBaz -> foo_bar_baz
function! s:Underscore(word)
  let result = s:Lowercase(a:word)
  return substitute(result, '\([A-Z]\)', '_\l\1', 'g')
endfunction

" Lowercase first letter of argument:
" Foo -> foo
function! s:Lowercase(word)
  return substitute(a:word, '^\w', '\l\0', 'g')
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
