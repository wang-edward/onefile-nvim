-- install lazy
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
            { out,                            'WarningMsg' },
            { '\nPress any key to exit...' },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- settings
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
vim.opt.guicursor = ''
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"
vim.opt.laststatus = 3 -- only 1 global statusline

-- autoformat on write
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        vim.cmd([[%s/\s\+$//e]])              -- remove trailing whitespace
        vim.lsp.buf.format({ async = false }) -- format with lsp
    end,
})
-- reload when file changes
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    command = "checktime",
})

-- language specific
local lang_indent = { scheme = 2, python = 4, haskell = 2 }

vim.api.nvim_create_autocmd("FileType", {
    pattern = vim.tbl_keys(lang_indent),
    callback = function()
        vim.opt_local.tabstop = lang_indent[vim.bo.filetype]
        vim.opt_local.shiftwidth = lang_indent[vim.bo.filetype]
    end,
})

-- plugins
require('lazy').setup({
    spec = {
        {
            'neovim/nvim-lspconfig',
            { 'catppuccin/nvim',                     name = 'catppuccin',                          priority = 1000 },
            { 'morhetz/gruvbox',                     name = 'gruvbox',                             priority = 1000 },
            { 'folke/tokyonight.nvim',               name = 'tokyonight',                          priority = 1000 },
            { 'lewis6991/gitsigns.nvim',             opts = {} },
            { 'lukas-reineke/indent-blankline.nvim', main = 'ibl',                                 opts = {} },
            { 'DaikyXendo/nvim-material-icon',       dependencies = 'nvim-tree/nvim-web-devicons' },
            { 'akinsho/bufferline.nvim',             dependencies = 'nvim-tree/nvim-web-devicons', opts = {} },
            { 'nvim-lualine/lualine.nvim',           dependencies = 'nvim-tree/nvim-web-devicons', opts = {} },
            { 'nvim-tree/nvim-tree.lua',             opts = {} },
            { 'nvim-treesitter/nvim-treesitter',     build = ':TSUpdate' },
            { 'williamboman/mason.nvim',             opts = {} },
            { 'williamboman/mason-lspconfig.nvim',   opts = {} },
            { 'HiPhish/rainbow-delimiters.nvim' },
            { 'folke/which-key.nvim',                event = 'VeryLazy',                           opts = {} },
            { 'folke/trouble.nvim',                  dependencies = 'nvim-tree/nvim-web-devicons', opts = {} },
            {
                'akinsho/toggleterm.nvim',
                opts = {
                    direction = 'float',
                    float_opts = {
                        border = 'curved',
                    },
                },
            },
            {
                'nvim-telescope/telescope.nvim',
                dependencies = { 'nvim-lua/plenary.nvim' },
                opts = {
                    defaults = {
                        layout_strategy = 'flex',
                        layout_config = {
                            width = 0.9,
                            height = 0.9,
                        },
                    },
                }
            },
            { 'hrsh7th/nvim-cmp',                        dependencies = { 'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', }, },
            { 'greggh/claude-code.nvim',                 dependencies = 'nvim-lua/plenary.nvim',                           opts = { window = { split_ratio = 0.7 }, }, },
            { 'nvim-treesitter/nvim-treesitter-context', opts = { multiline_threshold = 1 } },
        }
    },
    { colorscheme = { 'gruvbox' } },
    checker = { enabled = true },
})

-- autocomplete
local cmp = require('cmp')
cmp.setup({
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    }),
    sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
    }
})

-- lsp
vim.diagnostic.config({
    virtual_text = true, -- Show error text inline
    signs = true,        -- Show signs in gutter (the 'E' you see)
    underline = true,    -- Show squiggly underlines
    update_in_insert = false,
    severity_sort = true,
})
require('nvim-treesitter.configs').setup({
    ensure_installed = { 'zig', 'rust', 'python', 'lua' },
    highlight = { enable = true },
})
require('mason-lspconfig').setup({
    ensure_installed = { 'zls', 'rust_analyzer', 'ruff', 'ty', 'lua_ls', 'hls' },
    handlers = {
        function(server_name)
            require('lspconfig')[server_name].setup({
                capabilities = require('cmp_nvim_lsp').default_capabilities(),
            })
        end,
    },
})
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        local opts = { buffer = ev.buf }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>d', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    end,
})

-- keymap
local map = vim.keymap.set
local opts = { silent = true, noremap = true }

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>s', builtin.live_grep, { desc = 'Telescope find text' })
vim.keymap.set('n', '<leader>l', builtin.resume, { desc = 'Telescope resume search' })

map('n', '<C-h>', '<C-w>h', opts) -- move windows
map('n', '<C-j>', '<C-w>j', opts)
map('n', '<C-k>', '<C-w>k', opts)
map('n', '<C-l>', '<C-w>l', opts)
map('n', '<C-u>', '<C-u>zz', opts) -- center after goto
map('n', '<C-d>', '<C-d>zz', opts)
map('n', '<C-o>', '<C-o>zz', opts)
map('n', '<C-i>', '<C-i>zz', opts)
map("v", "<", "<gv", opts) -- don't deselect after indent
map("v", ">", ">gv", opts)
map('n', '<leader>e', ':NvimTreeToggle<cr>')
map('n', '<leader>/', 'gcc', { desc = 'comment', remap = true, silent = true })
map('v', '<leader>/', 'gc', { desc = 'comment', remap = true, silent = true })
map('n', '<leader>q', '<cmd>q<cr>', { desc = 'close window' })
map('n', '<leader>w', '<cmd>w<cr>', { desc = 'write' })
map('n', '<leader>t', '<cmd>enew<cr>', { desc = 'new buffer ' })
map('n', '<leader>c', '<cmd>bp | bd #<cr>', { desc = 'close buffer' })
map('n', '<leader>n', '<cmd>vsplit | enew<cr>', { desc = 'new file split' })
map('n', '<leader>v', '<cmd>split | enew<cr>', { desc = 'new file split vert' })
map('n', '<leader>h', '<cmd>noh<cr>', { desc = 'no highlight' })
map('n', 'L', '<cmd>BufferLineCycleNext<cr>')
map('n', 'H', '<cmd>BufferLineCyclePrev<cr>')
map('n', '<leader>p', '<cmd>Lazy<cr>')
map('n', 'gl', vim.diagnostic.open_float, opts) -- popup window of error
map('n', '<leader>gg', function()
    local Terminal = require('toggleterm.terminal').Terminal
    local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, })
    lazygit:toggle()
end, { desc = 'lazygit' })
map('n', '<leader>a', function()
    local p = vim.fn.getpos('.')
    vim.cmd('%y+')
    vim.fn.setpos('.', p)
end, { desc = 'copy whole file' })
map('n', '<leader>x', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'diagnostics' })
map('n', '<leader>X', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'buffer diagnostics' })
map('n', '<leader>z', '<cmd>ClaudeCode<CR>', { desc = 'Toggle Claude Code' })
map('n', '<leader>bb', '<cmd>ClaudeCodeContinue<CR>', { desc = 'Claude Code continue ' })
map('n', '<leader>br', '<cmd>ClaudeCodeResume<CR>', { desc = 'Claude Code resume' })
map('t', '<Esc>', '<C-\\><C-n>', opts, { desc = 'exit terminal mode' })
map('n', '<leader>F', function() vim.lsp.buf.format() end, { desc = 'format file' })

map('n', '<leader>T', '<cmd>tabnew<cr>', { desc = 'new tab' })
map('n', '<leader>Q', '<cmd>tabclose<cr>', { desc = 'close tab' })
for i = 1, 9 do
    map('n', '<leader>' .. i, i .. 'gt', { desc = 'goto tab ' .. i })
end

vim.cmd('colorscheme gruvbox')
