" Fix tabs by doing the following:
"   Making tabs appear 4 spaces wide (max. Shorter if the tab doesn't begin at
"   a multiple of 4 offset from the start of the line)
"   Using spaces instead of a tab character when the tab key is pressed.
"   Displaying a blue ">---" wherever a real tab is present in the file.
"   (Insert a real tab by pressing CTRL-V followed by TAB)
set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
set list
set listchars=tab:>-

" Toggle between tabs and spaces
function! ToggleTabs()
    if &expandtab
        set softtabstop=0
        let &shiftwidth=&tabstop
        set noexpandtab
        echom "Tab will insert a real tab."
    else
        set softtabstop=4
        set shiftwidth=4
        set expandtab
        echom "Tab will insert spaces."
    endif
endfunction

" Map ToggleTabs() to the Tab key in normal mode
nmap <Tab> mz:call ToggleTabs()<CR>

function! RunCmd(cmd)
    return substitute(system(a:cmd), '\n$', '', '')
endfunction

" Look in each directory above the opened file for a .tabs or .spaces file
" If we find a .spaces file, then use spaces.
" If we find a .tabs file, then use real tabs.
" If we don't find anything, then use spaces.
function! ChooseDefaultTabs(dir)
    let x = RunCmd("[ -f " . a:dir . "/.spaces ]")

    if v:shell_error == 0
        return "spaces"
    endif

    let y = RunCmd("[ -f " . a:dir . "/.tabs ]")

    if v:shell_error != 0
        if a:dir == "/"
            return "spaces"
        else
            return ChooseDefaultTabs(RunCmd("dirname " . a:dir))
        endif
    else
        return "tabs"
    endif
endfunction

if ChooseDefaultTabs(expand("%:p:h")) == "tabs"
    silent :call ToggleTabs()
endif


" Put tabs back to normal for makefiles because make requires real tabs.
if has("autocmd")
    filetype plugin indent on
    autocmd FileType make set tabstop=4 shiftwidth=4 softtabstop=0 noexpandtab
endif

" Change the color of comments so they aren't dark blue (impossible to read)
hi Comment ctermfg=2

" Always show line numbers
set number

" Accept mouse input for highlighting visual blocks and scrolling
set mouse=a

" Add the :JSHint plugin for checking JS code.
set runtimepath+=~/.vim/bundle/jshint2.vim/
