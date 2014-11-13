function rimplement#route#Main()
  if search('''[^'']*\%#[^'']*''', 'nbc', line('.')) > 0
    let description = rimplement#GetMotion("Vi'")
  elseif search('"[^"]*\%#[^"]*"', 'nbc', line('.')) > 0
    let description = rimplement#GetMotion('Vi"')
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
          \ 'class '.rimplement#CapitalCamelCase(controller).'Controller < ApplicationController',
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
