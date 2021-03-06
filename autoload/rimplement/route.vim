let s:http_method_pattern = '\<\%(get\|post\|put\|delete\|patch\)\>'

function rimplement#route#Main()
  let description = s:FindRouteDescription()

  if description == ''
    return
  endif

  if description !~ '^\k\+#\k\+$'
    echomsg "Description doesn't look like controller#action: ".description
    return
  endif

  let nesting = s:FindRouteNesting()
  echomsg string(nesting)
  if len(nesting) > 0
    let file_prefix = join(nesting, '/').'/'
    let module_prefix = join(map(nesting, 'rimplement#CapitalCamelCase(v:val)'), '::').'::'
  else
    let file_prefix = ''
    let module_prefix = ''
  endif

  let [controller, action] = split(description, '#')
  let filename = 'app/controllers/'.file_prefix.controller.'_controller.rb'
  exe 'edit '.filename

  if !filereadable(filename)
    " then it doesn't exist yet, fill it in
    call append(0, [
          \ 'class '.module_prefix.rimplement#CapitalCamelCase(controller).'Controller < ApplicationController',
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

function! s:FindRouteDescription()
  if rimplement#SearchUnderCursor('''[^'']\+''') > 0
    return rimplement#GetMotion("vi'")
  elseif rimplement#SearchUnderCursor('"[^"]\+"') > 0
    return rimplement#GetMotion('vi"')
  elseif rimplement#SearchUnderCursor('resources :\k\+') > 0
    call search(':\k')
    let resource = expand('<cword>')
    return resource.'#index'
  elseif rimplement#SearchUnderCursor('resource :\k\+') > 0
    call search(':\k')
    let resource = expand('<cword>')
    return resource.'#show'
  elseif rimplement#SearchUnderCursor(s:http_method_pattern.'\s\+:\k\+') > 0
    call search(':\k')
    let action = expand('<cword>')
    if search('^\s*resources\= :\zs\k\+\ze do$', 'b') < 0
      echomsg "Found the action '".action."', but can't find a containing resource."
      return ''
    endif
    let controller = expand('<cword>')
    return controller.'#'.action
  endif

  echomsg "Couldn't find string description"
  return ''
endfunction

function! s:FindRouteNesting()
  " Find any parent routes
  let indent = indent('.')
  let route_path = []
  let namespace_pattern = 'namespace :\zs\k\+'

  while search('^ \{'.(indent - &sw).'}'.namespace_pattern, 'bW')
    let route = expand('<cword>')
    call insert(route_path, route, 0)
    let indent = indent('.')
  endwhile

  return route_path
endfunction
