function! rimplement#partial#Main()
  if rimplement#SearchUnderCursor('render\s*[''"]\(\f\+\)[''"]') <= 0
    echoerr "Rimplement: Couldn't find partial under cursor"
    return
  endif

  if search('render\s*[''"]\S', 'e', line('.')) <= 0
    echoerr "Rimplement: Couldn't find partial under cursor"
    return
  endif

  let quote = getline('.')[col('.') - 2]
  let path = rimplement#GetMotion('vi'.quote)
  let extensions = substitute(expand('%'), '[^.]\+\.', '', '')

  if path =~ '/\S'
    " path is of the form folder/file
    let path = 'app/views/'.substitute(path, '\(.*\)/\(\w\+\)$', '\1/_\2', '')
  else
    let path = expand('%:h').'/_'.path
  endif

  let path = path.'.'.extensions
  exe 'edit '.path
endfunction
