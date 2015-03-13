" TODO (2015-03-13) Infer where in class to place the method
function! rimplement#method#Main(method_name, location)
  let method_name = a:method_name

  " Ensure it's underscored
  let method_name = rimplement#Underscore(method_name)

  if a:location == ''
    let location = input("Implement method '".method_name."' in which file? ", "", "file")
  else
    let location = a:location
  endif

  if location == ''
    return
  endif

  " TODO (2014-11-07) Infer class from context?
  let class_name = rimplement#CapitalCamelCase(fnamemodify(location, ':t:r'))

  call rimplement#class#Main(class_name, rimplement#Dirname(location))

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
