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

" Searching for patterns {{{1
"
" function! rimplement#SearchUnderCursor(pattern, flags, skip) {{{2
"
" Searches for a match for the given pattern under the cursor. Returns the
" result of the |search()| call if a match was found, 0 otherwise.
"
" Moves the cursor unless the 'n' flag is given.
"
" The a:flags parameter can include one of "e", "p", "s", "n", which work the
" same way as the built-in |search()| call. Any other flags will be ignored.
"
function! rimplement#SearchUnderCursor(pattern, ...)
  let [match_start, match_end] = call('rimplement#SearchposUnderCursor', [a:pattern] + a:000)
  if match_start > 0
    return match_start
  else
    return 0
  endif
endfunction

" function! rimplement#SearchposUnderCursor(pattern, flags, skip) {{{2
"
" Searches for a match for the given pattern under the cursor. Returns the
" start and (end + 1) column positions of the match. If nothing was found,
" returns [0, 0].
"
" Moves the cursor unless the 'n' flag is given.
"
" Respects the skip expression if it's given.
"
" See rimplement#SearchUnderCursor for the behaviour of a:flags
"
function! rimplement#SearchposUnderCursor(pattern, ...)
  if a:0 >= 1
    let given_flags = a:1
  else
    let given_flags = ''
  endif

  if a:0 >= 2
    let skip = a:2
  else
    let skip = ''
  endif

  let lnum        = line('.')
  let col         = col('.')
  let pattern     = a:pattern
  let extra_flags = ''

  " handle any extra flags provided by the user
  for char in ['e', 'p', 's']
    if stridx(given_flags, char) >= 0
      let extra_flags .= char
    endif
  endfor

  try
    call rimplement#PushCursor()

    " find the start of the pattern
    call search(pattern, 'bcW', lnum)
    let search_result = rimplement#SearchSkip(pattern, skip, 'cW'.extra_flags, lnum)
    if search_result <= 0
      return [0, 0]
    endif
    let match_start = col('.')

    " find the end of the pattern
    call rimplement#PushCursor()
    call rimplement#SearchSkip(pattern, skip, 'cWe', lnum)
    let match_end = col('.')

    " set the end of the pattern to the next character, or EOL. Extra logic
    " is for multibyte characters.
    if col('.') + 1 > match_end
      " no movement, we must be at the end
      let match_end = col('$')
    else
      let match_end = col('.') + 1
    endif
    call rimplement#PopCursor()

    if !rimplement#ColBetween(col, match_start, match_end)
      " then the cursor is not in the pattern
      return [0, 0]
    else
      " a match has been found
      return [match_start, match_end]
    endif
  finally
    if stridx(given_flags, 'n') >= 0
      call rimplement#PopCursor()
    else
      call rimplement#DropCursor()
    endif
  endtry
endfunction

" function! rimplement#SearchSkip(pattern, skip, ...) {{{2
" A partial replacement to search() that consults a skip pattern when
" performing a search, just like searchpair().
"
" Note that it doesn't accept the "n" and "c" flags due to implementation
" difficulties.
function! rimplement#SearchSkip(pattern, skip, ...)
  " collect all of our arguments
  let pattern = a:pattern
  let skip    = a:skip

  if a:0 >= 1
    let flags = a:1
  else
    let flags = ''
  endif

  if stridx(flags, 'n') > -1
    echoerr "Doesn't work with 'n' flag, was given: ".flags
    return
  endif

  let stopline = (a:0 >= 2) ? a:2 : 0
  let timeout  = (a:0 >= 3) ? a:3 : 0

  " just delegate to search() directly if no skip expression was given
  if skip == ''
    return search(pattern, flags, stopline, timeout)
  endif

  " search for the pattern, skipping a match if necessary
  let skip_match = 1
  while skip_match
    let match = search(pattern, flags, stopline, timeout)

    " remove 'c' flag for any run after the first
    let flags = substitute(flags, 'c', '', 'g')

    if match && eval(skip)
      let skip_match = 1
    else
      let skip_match = 0
    endif
  endwhile

  return match
endfunction

function! rimplement#SkipSyntax(...)
  let syntax_groups = a:000
  let skip_pattern  = '\%('.join(syntax_groups, '\|').'\)'

  return "synIDattr(synID(line('.'),col('.'),1),'name') =~ '".skip_pattern."'"
endfunction

" Checks if the current position of the cursor is within the given limits.
"
function! rimplement#CursorBetween(start, end)
  return rimplement#ColBetween(col('.'), a:start, a:end)
endfunction

" Checks if the given column is within the given limits.
"
function! rimplement#ColBetween(col, start, end)
  return a:start <= a:col && a:end > a:col
endfunction
