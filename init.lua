-- ~/.config/nvim/init.lua
-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- leader キー設定
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 基本エディタ設定
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.showbreak = '↪ '
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.undofile = true

-- lazy.nvimプラグイン設定
require("lazy").setup({
  spec = {
    { "tyru/eskk.vim", config = function()
        vim.g['eskk#directory'] = vim.fn.expand("~/.skk")
        vim.g['eskk#dictionary'] = vim.fn.expand("~/.skk/SKK-JISYO.L")
      end
    },
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "nvim-lualine/lualine.nvim" },
    { "folke/tokyonight.nvim" },
    { "mbbill/undotree", cmd = "UndotreeToggle" },
    { "Pocco81/auto-save.nvim", config = function() require("auto-save").setup({}) end, event = { "InsertLeave", "TextChanged" } },
    { "tpope/vim-fugitive" },
    { "lewis6991/gitsigns.nvim" },
    { "kdheepak/lazygit.nvim" },
    { "sindrets/diffview.nvim" },

    -- ==== LSP/補完/スニペット ====
    { "neovim/nvim-lspconfig" },
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-cmdline" },
    { "L3MON4D3/LuaSnip" },
    { "saadparwaiz1/cmp_luasnip" },
    { "onsails/lspkind-nvim" },
    { "ray-x/lsp_signature.nvim" },
    { "rafamadriz/friendly-snippets" },
    {
      "folke/tokyonight.nvim",
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("tokyonight-night")
        -- 基本的な透過
        for _, g in ipairs({
          "Normal", "NormalNC", "SignColumn", "StatusLine", "StatusLineNC",
          "VertSplit", "WinSeparator", "EndOfBuffer", "MsgArea", "MsgSeparator",
          "NormalFloat", "FloatBorder", "LineNr", "Folded", "CursorLine", "CursorLineNr"
        }) do
          vim.api.nvim_set_hl(0, g, { bg = "none" })
        end
        -- 見やすさ強調: コメントや可読性重視だけ上書き
        vim.api.nvim_set_hl(0, "Comment",    { fg = "#7aa2f7", italic = true })
        vim.api.nvim_set_hl(0, "String",     { fg = "#9ece6a" })
        vim.api.nvim_set_hl(0, "Function",   { fg = "#bb9af7", bold = true })
        vim.api.nvim_set_hl(0, "Keyword",    { fg = "#7dcfff", bold = true })
        vim.api.nvim_set_hl(0, "Visual",     { bg = "#33467c" })
      end,
    },
    -- ユーティリティ
    { "folke/which-key.nvim", config = function() require("which-key").setup({}) end, event = "VeryLazy" },
    { "ggandor/leap.nvim", config = function() require("leap").add_default_mappings() end, event = "BufReadPost" },
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim", "nvim-lua/popup.nvim" }, cmd = "Telescope", config = function() require("telescope").setup({}) end },
    { "nvim-pack/nvim-spectre", dependencies = { "nvim-lua/plenary.nvim" }, cmd = "Spectre", config = function() require("spectre").setup() end },
  },
  install = { colorscheme = { "darkvoid", "tokyonight", "habamax" } },
  checker = { enabled = true },
})

-- lualine/gitsigns
require("lualine").setup {}
require("gitsigns").setup()

-- LuaSnip/VSCスニペット
require("luasnip.loaders.from_vscode").lazy_load()

-- cmp設定
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args) require("luasnip").lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  }),
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  },
  formatting = {
    format = require("lspkind").cmp_format({ with_text = true, maxwidth = 50 })
  },
})

-- LSP 設定（lspconfig直指定）
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")

for _, lsp in ipairs({ 
  "pylsp",
  "gopls", 
  "lua_ls", 
  "rust_analyzer", 
  "ts_ls", 
  "bashls" 
}) do
  lspconfig[lsp].setup({ capabilities = capabilities })
end

-- lsp_signature
require("lsp_signature").setup({})

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- LSPアタッチ時のキーマップ
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local buf = event.buf
    local map = function(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf })
    end
    map('n', 'gd', vim.lsp.buf.definition)
    map('n', 'K', vim.lsp.buf.hover)
    map('n', '<leader>rn', vim.lsp.buf.rename)
    map('n', '<leader>ca', vim.lsp.buf.code_action)
    map('n', 'gr', vim.lsp.buf.references)
    map('n', '<leader>f', function()
      vim.lsp.buf.format({ async = true })
    end)
  end,
})

-- ファイル/検索キーマップ
vim.keymap.set('n', '<Leader>ff', '<cmd>Telescope find_files<CR>',   { desc = 'ファイル検索' })
vim.keymap.set('n', '<Leader>fg', '<cmd>Telescope live_grep<CR>',   { desc = 'Grep検索' })
vim.keymap.set('n', '<Leader>fb', '<cmd>Telescope buffers<CR>',      { desc = 'バッファ一覧' })
vim.keymap.set('n', '<Leader>fh', '<cmd>Telescope help_tags<CR>',    { desc = 'ヘルプ検索' })
vim.keymap.set('n', '<Leader>sr', '<cmd>lua require("spectre").open()<CR>', { desc = 'プロジェクト全体で検索＆置換' })
vim.keymap.set('v', '<Leader>sr', '<esc><cmd>lua require("spectre").open_visual({select_word=true})<CR>', { desc = '選択範囲で検索＆置換' })

-- 選択範囲のインデントをカーソル行と同じ幅に揃える
vim.keymap.set('v', '<leader>=', function()
  local line = vim.fn.line('.')
  local indent = vim.fn.indent(line)
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  for l = start_line, end_line do
    vim.fn.setline(l, string.rep(' ', indent) .. vim.fn.matchstr(vim.fn.getline(l), [[^\s*\zs.*]]))
  end
end, { noremap = true, silent = true, desc = "選択範囲のインデントをカーソル行に揃える" })
