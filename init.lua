-- install lazy
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
            { out, 'WarningMsg' },
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
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"

vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        vim.cmd([[%s/\s\+$//e]]) -- remove trailing whitespace
        vim.lsp.buf.format({ async = false }) -- format with lsp
    end,
})

-- plugins
require('lazy').setup({
    spec = {
        {
            'neovim/nvim-lspconfig',
            { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
            { 'morhetz/gruvbox', name = 'gruvbox', priority = 1000 },
            { 'lewis6991/gitsigns.nvim', opts = {} },
            { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },
            { 'DaikyXendo/nvim-material-icon', dependencies = 'nvim-tree/nvim-web-devicons' },
            { 'akinsho/bufferline.nvim', dependencies = 'nvim-tree/nvim-web-devicons', opts = {} },
            { 'nvim-lualine/lualine.nvim', dependencies = 'nvim-tree/nvim-web-devicons', opts = {} },
            { 'nvim-tree/nvim-tree.lua', opts = {} },
            { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
            { 'williamboman/mason.nvim', opts = {} },
            { 'williamboman/mason-lspconfig.nvim', opts = {} },
            { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
        }
    },
    { colorscheme = { 'gruvbox' } },
    checker = { enabled = true },
})

-- lsp
vim.diagnostic.config({
    virtual_text = true,  -- Show error text inline
    signs = true,         -- Show signs in gutter (the 'E' you see)
    underline = true,     -- Show squiggly underlines
    update_in_insert = false,
    severity_sort = true,
})
vim.api.nvim_create_autocmd('CursorHold', {
    callback = function()
        vim.diagnostic.open_float(nil, { focus = false })
    end
})
local signs = { Error = "E", Warn = "W", Hint = "H", Info = "I" }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
require('nvim-treesitter.configs').setup({
    ensure_installed = { 'zig' },
    highlight = { enable = true },
})
require('mason-lspconfig').setup({
    ensure_installed = { 'zls' },
})

local lspconfig = require('lspconfig')
lspconfig.zls.setup({})

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
        local opts = { buffer = ev.buf }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    end,
})

-- keymap
local map = vim.keymap.set
local opts = { silent = true, noremap = true }

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>f', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>s', builtin.live_grep, { desc = 'Telescope live grep' })

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
map('n', '<leader>q', '<cmd>qa<cr>', { desc = 'quit' }) -- :qa
map('n', '<leader>w', '<cmd>w<cr>', { desc = 'write' })
map('n', '<leader>c', '<cmd>bdelete<cr>', { desc = 'close tab' })
map('n', '<leader>t', '<cmd>tabnew<cr>', { desc = 'new tab' }) -- :enew
map('n', '<leader>n', '<cmd>vsplit | enew<cr>', { desc = 'new file split' })
map('n', '<leader>v', '<cmd>split | enew<cr>', { desc = 'new file split vert' })
map('n', 'L', '<cmd>BufferLineCycleNext<cr>')
map('n', 'H', '<cmd>BufferLineCyclePrev<cr>')

vim.cmd('colorscheme gruvbox')
