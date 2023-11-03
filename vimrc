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

" Map CTRL-P to the opposite of CTRL-O -- go forward in cursor jump list
nnoremap <c-p> <tab>
" Map ToggleTabs() to the Tab key in normal mode
nmap <Tab> mz:call ToggleTabs()<CR>

" Map Ctrl-W h and Ctrl-W l to switch between the left and right windows
nnoremap <c-w>h <c-w><Left>
nnoremap <c-w>l <c-w><Right>

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

    if v:shell_error == 0
        return "tabs"
    endif

    if a:dir == "/"
        return "spaces"
    endif

    return ChooseDefaultTabs(RunCmd("dirname " . a:dir))
endfunction

if isdirectory(expand("%:p:h")) && ChooseDefaultTabs(expand("%:p:h")) == "tabs"
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
set number relativenumber

" Accept mouse input for highlighting visual blocks and scrolling
set mouse=a

" tmux will send xterm-style keys when its xterm-keys option is on
if &term =~ '^screen'
    execute "set <xUp>=\e[1;*A"
    execute "set <xDown>=\e[1;*B"
    execute "set <xRight>=\e[1;*C"
    execute "set <xLeft>=\e[1;*D"
endif

noremap <silent> <C-J> <C-E>
noremap <silent> <C-K> <C-Y>

" set true colors
" if has("termguicolors")
"     set t_8f=[38;2;%lu;%lu;%lum
"     set t_8b=[48;2;%lu;%lu;%lum
"     set termguicolors
" endif

" Plugins
call plug#begin()
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-fugitive'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-lua/telescope.nvim', { 'branch': '0.1.x' }
Plug 'ahmedkhalf/project.nvim'
let g:coc_global_extensions = [
    \ 'coc-tsserver',
    \ 'coc-eslint',
    \ ]
call plug#end()

lua << EOF
require('telescope').setup{
    defaults = {
        file_ignore_patterns = {"node_modules", ".git"}
    }
}
EOF

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use tab for trigger completion with characters ahead and navigate
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Open or refresh the completion list
inoremap <silent><expr> <c-space> coc#refresh()

inoremap <expr> <cr> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
inoremap <silent><expr> <cr> coc#pum#visible() ? coc#_select_confirm() : "\<C-g>u\<CR>"

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> rs <Plug>(coc-rename)
nmap <silent> <Leader>ca <Plug>(coc-codeaction)
nmap <silent> cen <Plug>(coc-diagnostic-next)
nmap <silent> cep <Plug>(coc-diagnostic-prev)
nnoremap <silent> <Space> :set hlsearch!<CR>
vmap <silent> fs <Plug>(coc-format-selected)
vmap <silent> <Leader>dp diffput
nnoremap <Leader>ff <cmd>Telescope find_files<cr>
nnoremap <Leader>fg <cmd>Telescope live_grep<cr>
