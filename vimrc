hi Visual term=reverse cterm=reverse guibg=Grey

" Fix tabs by doing the following:
"   Making tabs appear 4 spaces wide (max. Shorter if the tab doesn't begin at
"   a multiple of 4 offset from the start of the line)
"   Using spaces instead of a tab character when the tab key is pressed.
"   Displaying a blue ">---" wherever a real tab is present in the file.
"   (Insert a real tab by pressing CTRL-V followed by TAB)
set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
set list
set listchars=tab:>-

set wildmode=longest:full,full

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

" Run with :call WorkaroundLuaHighlightBug()
function! WorkaroundLuaHighlightBug()
    execute '!curl -sS https://raw.githubusercontent.com/neovim/neovim/v0.7.2/runtime/syntax/lua.vim | sudo tee $VIMRUNTIME/syntax/lua.vim'
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

fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

" Always trim trailing whitespace before saving a file, unless
" VIM_LEAVE_WHITESPACE_ALONE is defined.
if has("autocmd") && empty($VIM_LEAVE_WHITESPACE_ALONE)
    autocmd BufWritePre * call TrimWhitespace()
endif

" Change the color of comments so they aren't dark blue (impossible to read)
hi Comment ctermfg=2

" Always show line numbers
set number relativenumber

" Accept mouse input for highlighting visual blocks and scrolling
set mouse=a
set updatetime=300

" At least 3 lines above/below cursor when scrolling
set so=3

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
Plug 'tpope/vim-commentary'
" Plug 'pangloss/vim-javascript'
" Plug 'leafgarland/typescript-vim'
" Plug 'peitalin/vim-jsx-typescript'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'tpope/vim-fugitive'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-lua/telescope.nvim'
Plug 'DrKJeff16/project.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'luochen1990/rainbow'
Plug 'https://github.com/tamton-aquib/duck.nvim.git'
Plug 'jeetsukumaran/vim-indentwise'
Plug 'walm/jshint.vim'
Plug 'slim-template/vim-slim'
Plug 'tommcdo/vim-lion'
Plug 'evanleck/vim-svelte'
Plug 'sveltejs/language-tools', {'do': 'npm install && npm run build'}
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/nvim-treesitter-context'
Plug 'joshuakb2/nvim-catppuccin' " Color scheme
let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle
let b:lion_squeeze_spaces = 1 " allow lion to reduce number of spaces when aligning columns
call plug#end()

lua << EOF
require('telescope').setup{
    defaults = {
        file_ignore_patterns = {"node_modules", ".git"}
    }
}
require('project').setup{
    patterns = {'.git', '.project_root'}
}
require'treesitter-context'.setup{}
require'catppuccin'.setup {
	transparent_background = true,
}
vim.api.nvim_create_autocmd('FileType', {
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
vim.cmd.colorscheme 'catppuccin'

-- LSP setup
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local servers = { 'rust_analyzer', 'zls', 'eslint', 'svelte', 'jsonls', 'nixd', 'vimls', 'ccls', 'cssls' }
for _, server in ipairs(servers) do
    vim.lsp.config(server, {
        capabilities = capabilities,
    })
end

vim.lsp.config('eslint', {
    flags = {
        allow_incremental_sync = false,
        debounce_text_changes = 1000,
    },
});

local function has_native_ts_preview(root)
    local path = root .. '/node_modules/@typescript/native-preview/package.json'
    local f = io.open(path, 'r')
    if not f then return false end
    f:close()
    return true
end

local ts_filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }

-- ts_ls: always runs for full IDE features (code actions, auto-import, etc.)
vim.lsp.config('ts_ls', {
    capabilities = capabilities,
    filetypes = ts_filetypes,
    root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },
    on_attach = function(client, bufnr)
        local root = vim.fs.root(bufnr, { 'tsconfig.json', 'jsconfig.json', 'package.json' })
        if root and has_native_ts_preview(root) then
            -- Let tsgo handle these in TS 7 projects
            client.server_capabilities.hoverProvider = false
            client.server_capabilities.definitionProvider = false
            client.server_capabilities.typeDefinitionProvider = false
            client.server_capabilities.implementationProvider = false
            client.server_capabilities.referencesProvider = false
            client.handlers['textDocument/publishDiagnostics'] = function() end
        end
    end,
})

-- tsgo: runs alongside ts_ls in TS 7 projects for faster diagnostics.
local tsgo_capabilities = vim.deepcopy(capabilities)
tsgo_capabilities.general = tsgo_capabilities.general or {}
tsgo_capabilities.general.positionEncodings = { 'utf-16' }

vim.lsp.config('tsgo', {
    capabilities = tsgo_capabilities,
    filetypes = ts_filetypes,
    root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },
    on_attach = function(client)
        -- Let ts_ls handle these; tsgo handles diagnostics + navigation
        client.server_capabilities.codeActionProvider = false
        client.server_capabilities.completionProvider = nil
        client.server_capabilities.renameProvider = false
    end,
})

-- Only enable tsgo in projects with @typescript/native-preview
vim.api.nvim_create_autocmd('FileType', {
    pattern = ts_filetypes,
    callback = function(ev)
        local root = vim.fs.root(ev.buf, { 'package.json' })
        if root and has_native_ts_preview(root) then
            vim.lsp.config('tsgo', {
                cmd = { root .. '/node_modules/.bin/tsgo', '--lsp', '--stdio' },
            })
            vim.lsp.enable('tsgo', true)
        end
    end,
})

vim.lsp.enable(servers)
vim.lsp.enable('ts_ls')

-- nvim-cmp setup
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup {
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-CR>'] = cmp.mapping.confirm({ select = true }),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    }, {
        { name = 'buffer' },
    }),
}

vim.diagnostic.config({
    virtual_text = true,
})

-- vim.api.nvim_create_autocmd('CursorHold', {
--     callback = function()
--         vim.diagnostic.open_float(nil, { focusable = false })
--     end,
-- })

function open_float()
    vim.schedule(function()
        vim.diagnostic.open_float({ scope = 'cursor' })
    end)
end

require('tsgo_project_diagnostics')
EOF

hi TreesitterContext guibg=grey

nmap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nmap <silent> gy <cmd>lua vim.lsp.buf.type_definition()<CR>
nmap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
nmap <silent> gr <cmd>lua vim.lsp.buf.references()<CR>
nmap <silent> rs <cmd>lua vim.lsp.buf.rename()<CR>
nmap <silent> <Leader>ca <cmd>lua vim.lsp.buf.code_action()<CR>
nmap <silent> <Leader>df <cmd>lua vim.diagnostic.jump({ count = 1, on_jump = open_float })<CR>
nmap <silent> <Leader>dr <cmd>lua vim.diagnostic.jump({ count = -1, on_jump = open_float })<CR>
" (see tsgo_project_diagnostics.lua)
" nmap <silent> <Leader>di <cmd>lua vim.diagnostic.setqflist()<CR>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> <Space> :set hlsearch!<CR>
vmap <silent> <Leader>fs <cmd>lua vim.lsp.buf.format()<CR>
nnoremap <silent> <Leader>fd <cmd>lua vim.lsp.buf.format()<CR>
vmap <silent> <Leader>dp diffput
nnoremap <Leader>ff <cmd>Telescope find_files<cr>
nnoremap <Leader>fg <cmd>Telescope live_grep<cr>
nnoremap <Leader>kk :let @k=@"<CR>
nnoremap <silent> <leader>rc :lua require("duck").hatch("🐈")<CR>
