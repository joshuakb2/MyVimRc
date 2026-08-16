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

" Run with :call WorkaroundLuaHighlightBug()
function! WorkaroundLuaHighlightBug()
    execute '!curl -sS https://raw.githubusercontent.com/neovim/neovim/v0.7.2/runtime/syntax/lua.vim | sudo tee $VIMRUNTIME/syntax/lua.vim'
endfunction

" Map CTRL-P to the opposite of CTRL-O -- go forward in cursor jump list
nnoremap <c-p> <tab>
" Map toggle_tabs() to the Tab key in normal mode
nmap <Tab> :lua toggle_tabs()<CR>

" Map Ctrl-W h and Ctrl-W l to switch between the left and right windows
nnoremap <c-w>h <c-w><Left>
nnoremap <c-w>l <c-w><Right>

function! RunCmd(cmd)
    return substitute(system(a:cmd), '\n$', '', '')
endfunction

lua << EOF
-- Look in each directory above the opened file for a .tabs or .spaces file
-- If we find a .spaces file, then use spaces.
-- If we find a .tabs file, then use real tabs.
-- If the file has content, it is expected to be the width of an indentation.
-- If we don't find anything, then use 4 spaces.
local function choose_default_tabs(dir)
    local x = vim.system({ "cat", dir .. "/.spaces" }, { text = true }):wait()
    if x.code == 0 then
        return {
            type = "spaces",
            width = (tonumber(x.stdout) or 4),
        }
    end

    x = vim.system({ "cat", dir .. "/.tabs" }, { text = true }):wait()
    if x.code == 0 then
        return {
            type = "tabs",
            width = (tonumber(x.stdout) or 4),
        }
    end

    if dir == "/" then
        return {
            type = "spaces",
            width = 4,
        }
    end

    return choose_default_tabs(vim.system({ "dirname", dir }, { text = true }):wait().stdout:gsub("%s*$", ""))
end

tabwidth = 4

-- Toggle between tabs and spaces
function _G.toggle_tabs()
    if vim.opt.expandtab:get() then
        _G.set_tabs("tabs")
    else
        _G.set_tabs("spaces")
    end
end

function _G.set_tabs(type, width)
    if width then
        _G.tabwidth = width
    else
        width = _G.tabwidth
    end

    if type == "tabs" then
        vim.opt.softtabstop = 0
        vim.opt.shiftwidth = width
        vim.opt.tabstop = width
        vim.opt.expandtab = false
        print "Tab will insert a real tab."
    else
        vim.opt.softtabstop = width
        vim.opt.shiftwidth = width
        vim.opt.expandtab = true
        print "Tab will insert spaces."
    end
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    callback = function()
        if vim.fn.isdirectory(vim.fn.expand("%:p:h")) then
            local tabs = choose_default_tabs(vim.fn.expand("%:p:h"))
            set_tabs(tabs.type, tabs.width)
        end
    end,
})
EOF

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
Plug 'nvim-treesitter/nvim-treesitter', { 'branch': 'main', 'do': ':TSUpdate' }
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

local servers = { 'rust_analyzer', 'zls', 'eslint', 'svelte', 'jsonls', 'nixd', 'vimls', 'ccls', 'cssls', 'phpactor' }
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

-- Read the major version of a project's locally-installed TypeScript.
local function get_ts_major_version(root)
    local path = root .. '/node_modules/typescript/package.json'
    local f = io.open(path, 'r')
    if not f then return nil end
    local content = f:read('*a')
    f:close()
    local version = content:match('"version"%s*:%s*"(%d+)')
    return version and tonumber(version) or nil
end

local ts_root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' }
local ts_filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }

-- TypeScript 7+ ships a feature-complete native LSP in the `typescript`
-- package (binary: tsc), so it runs on its own. Older versions use ts_ls.
-- Exactly one server attaches per project, chosen by the installed version.
local function project_uses_ts7(bufnr)
    local root = vim.fs.root(bufnr, ts_root_markers)
    if not root then return false, nil end
    local major = get_ts_major_version(root)
    return (major ~= nil and major >= 7), root
end

-- ts_ls: TypeScript 6.x and older only.
vim.lsp.config('ts_ls', {
    capabilities = capabilities,
    filetypes = ts_filetypes,
    root_dir = function(bufnr, on_dir)
        local is_ts7, root = project_uses_ts7(bufnr)
        if root and not is_ts7 then on_dir(root) end
    end,
})

-- tsc: the native TypeScript 7+ language server.
local tsc_capabilities = vim.deepcopy(capabilities)
tsc_capabilities.general = tsc_capabilities.general or {}
tsc_capabilities.general.positionEncodings = { 'utf-16' }

vim.lsp.config('tsc', {
    capabilities = tsc_capabilities,
    filetypes = ts_filetypes,
    root_dir = function(bufnr, on_dir)
        local is_ts7, root = project_uses_ts7(bufnr)
        if is_ts7 then on_dir(root) end
    end,
})

-- tsc lives in node_modules; point its cmd at the project-local binary
-- (this autocmd is registered before vim.lsp.enable so it runs first).
vim.api.nvim_create_autocmd('FileType', {
    pattern = ts_filetypes,
    callback = function(ev)
        local root = vim.fs.root(ev.buf, ts_root_markers)
        if root then
            vim.lsp.config('tsc', {
                cmd = { root .. '/node_modules/.bin/tsc', '--lsp', '--stdio' },
            })
        end
    end,
})

vim.lsp.enable(servers)
vim.lsp.enable('ts_ls')
vim.lsp.enable('tsc')

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
