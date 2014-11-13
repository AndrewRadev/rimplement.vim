" In order to make the pattern of saving the cursor and restoring it
" afterwards easier, these functions implement a simple cursor stack. The
" basic usage is:
"
"   call rimplement#PushCursor()
"   " Do stuff that move the cursor around
"   call rimplement#PopCursor()
"
function! rimplement#PushCursor()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call add(b:cursor_position_stack, getpos('.'))
endfunction
function! rimplement#PopCursor()
  call setpos('.', remove(b:cursor_position_stack, -1))
endfunction
function! rimplement#DropCursor()
  call remove(b:cursor_position_stack, -1)
endfunction

" Execute the normal mode motion "motion" and return the text it marks.
"
" Note that the motion needs to include a visual mode key, like "V", "v" or
" "gv"
function! rimplement#GetMotion(motion)
  call rimplement#PushCursor()

  let saved_register_text = getreg('z', 1)
  let saved_register_type = getregtype('z')

  exec 'silent normal! '.a:motion.'"zy'
  let text = @z

  call setreg('z', saved_register_text, saved_register_type)
  call rimplement#PopCursor()

  return text
endfunction

" Extract the parent directory of the given filepath
function! rimplement#Dirname(file)
  return fnamemodify(a:file, ':h')
endfunction

" Capitalize first letter of argument:
" foo -> Foo
function! rimplement#Capitalize(word)
  return substitute(a:word, '^\w', '\U\0', 'g')
endfunction

" CamelCase underscored word:
" foo_bar_baz -> fooBarBaz
function! rimplement#CamelCase(word)
  return substitute(a:word, '_\(.\)', '\U\1', 'g')
endfunction

" CamelCase and Capitalize
" foo_bar_baz -> FooBarBaz
function! rimplement#CapitalCamelCase(word)
  return rimplement#Capitalize(rimplement#CamelCase(a:word))
endfunction

" Underscore CamelCased word:
" FooBarBaz -> foo_bar_baz
function! rimplement#Underscore(word)
  let result = rimplement#Lowercase(a:word)
  return substitute(result, '\([A-Z]\)', '_\l\1', 'g')
endfunction

" Lowercase first letter of argument:
" Foo -> foo
function! rimplement#Lowercase(word)
  return substitute(a:word, '^\w', '\l\0', 'g')
endfunction
