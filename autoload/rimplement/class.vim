" TODO (2014-10-23) Use projections if available -- for the template
function! rimplement#class#Main(class_name, location)
  let class_name = a:class_name

  " Ensure it's camelcased
  let class_name = rimplement#CapitalCamelCase(class_name)

  if a:location != ""
    let location = a:location
  else
    let location = input("Implement class '".class_name."' in which directory? ", "", "dir")
  endif

  if location == ''
    return
  endif

  let underscored_name = rimplement#Underscore(class_name)

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
