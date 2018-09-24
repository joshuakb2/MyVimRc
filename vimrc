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
function ToggleTabs()
    if &expandtab
        set softtabstop=0
        set noexpandtab
        echom "Tabs enabled."
    else
        set softtabstop=4
        set expandtab
        echom "Tabs disabled."
    endif
endfunction


" Put tabs back to normal for makefiles because make requires real tabs.
if has("autocmd")
    filetype plugin indent on
    autocmd FileType make set tabstop=8 shiftwidth=8 softtabstop=0 noexpandtab
endif

" Change the color of comments so they aren't dark blue (impossible to read)
hi Comment ctermfg=2

" Always show line numbers
set number

" Accept mouse input for highlighting visual blocks and scrolling
set mouse=a

" Add the :JSHint plugin for checking JS code.
set runtimepath+=~/.vim/bundle/jshint2.vim/
