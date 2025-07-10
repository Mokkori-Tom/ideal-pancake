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
vim.opt.clipboard = "unnamedplus"   -- クリップボード連携
vim.opt.number = true               -- 行番号表示
vim.opt.relativenumber = true       -- 相対行番号
vim.opt.expandtab = true            -- タブ→スペース
vim.opt.shiftwidth = 2              -- インデント幅
vim.opt.tabstop = 2                 -- タブ幅
vim.opt.smartindent = true          -- スマートインデント
vim.opt.wrap = true                 -- 行の折り返し
vim.opt.linebreak = true            -- 単語途中で折り返さない
vim.opt.showbreak = '↪ '            -- 折り返し表示
vim.opt.cursorline = true           -- カーソル行強調
vim.opt.termguicolors = true        -- 24bitカラー
vim.opt.signcolumn = "yes"          -- サインカラム常時
vim.opt.undofile = true             -- アンドゥファイル有効

-- lazy.nvimプラグイン設定
require("lazy").setup({
  spec = {
    { "vim-denops/denops.vim",         lazy = false },
    { "vim-skk/skkeleton",             lazy = false },
    { "vim-denops/denops-helloworld.vim", lazy = false },
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "nvim-lualine/lualine.nvim" },
    { "folke/tokyonight.nvim" },
    { "mbbill/undotree",               cmd = "UndotreeToggle" },
    {
      "Pocco81/auto-save.nvim",
      config = function() require("auto-save").setup({}) end,
      event = { "InsertLeave", "TextChanged" },
    },
    { "tpope/vim-fugitive" },
    { "lewis6991/gitsigns.nvim" },
    { "kdheepak/lazygit.nvim" },
    { "sindrets/diffview.nvim" },
    -- ==== LSP/補完（追加言語含む）====
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
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
    -- ==== /LSP ====
    {
      "sudormrfbin/cheatsheet.nvim",
      dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",
      },
      cmd = { "Cheatsheet" },
    },
    {
      "folke/which-key.nvim",
      config = function() require("which-key").setup({}) end,
      event = "VeryLazy",
    },
    {
      "ggandor/leap.nvim",
      config = function() require("leap").add_default_mappings() end,
      event = "BufReadPost",
    },
    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "nvim-lua/popup.nvim" },
      cmd = "Telescope",
      config = function() require("telescope").setup({}) end,
    },
    {
      "nvim-pack/nvim-spectre",
      dependencies = { "nvim-lua/plenary.nvim" },
      cmd = "Spectre",
      config = function() require("spectre").setup() end,
    },
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
        vim.api.nvim_set_hl(0, "LineNr", { fg = "#ffffff", bold = true }) 
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ff9e64", bold = true })
        vim.api.nvim_set_hl(0, "Comment",    { fg = "#7aa2f7", italic = true })
        vim.api.nvim_set_hl(0, "String",     { fg = "#9ece6a" })
        vim.api.nvim_set_hl(0, "Function",   { fg = "#bb9af7", bold = true })
        vim.api.nvim_set_hl(0, "Keyword",    { fg = "#7dcfff", bold = true })
        vim.api.nvim_set_hl(0, "Visual",     { bg = "#33467c" })
      end,
    },
  },
  install = { colorscheme = { "darkvoid", "tokyonight", "habamax" } },
  checker = { enabled = true },
})

-- lualineセットアップ
require("lualine").setup {}

-- gitsigns.nvimセットアップ
require("gitsigns").setup()

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    --"pylsp", 
    "gopls", "denols", "taplo",
    "rust_analyzer", "ts_ls", "lua_ls", "bashls"
  }
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()
for _, lsp in ipairs({
  "pylsp", "gopls", "denols", "taplo",
  "rust_analyzer", "ts_ls", "lua_ls", "bashls"
}) do
  require("lspconfig")[lsp].setup({ capabilities = capabilities })
end

local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<Tab>"]     = cmp.mapping.select_next_item(),
    ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
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

require("lsp_signature").setup({})

-- SKK辞書指定
vim.api.nvim_create_autocmd("User", {
  pattern = "skkeleton-initialize-pre",
  callback = function()
    vim.fn["skkeleton#config"]({
      globalDictionaries = { vim.fn.expand("~/.skk/SKK-JISYO.L") }
    })
  end,
})

-- ファイル/検索キーマップ
vim.keymap.set('n', '<Leader>ff', '<cmd>Telescope find_files<CR>',   { desc = 'ファイル検索' })
vim.keymap.set('n', '<Leader>fg', '<cmd>Telescope live_grep<CR>',   { desc = 'Grep検索' })
vim.keymap.set('n', '<Leader>fb', '<cmd>Telescope buffers<CR>',      { desc = 'バッファ一覧' })
vim.keymap.set('n', '<Leader>fh', '<cmd>Telescope help_tags<CR>',    { desc = 'ヘルプ検索' })
vim.keymap.set('n', '<Leader>sr', '<cmd>lua require("spectre").open()<CR>', { desc = 'プロジェクト全体で検索＆置換' })
vim.keymap.set('v', '<Leader>sr', '<esc><cmd>lua require("spectre").open_visual({select_word=true})<CR>', { desc = '選択範囲で検索＆置換' })
vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-enable)")

-- 手動format用キーマップ（n: normal mode）
vim.keymap.set('n', '<leader>cf', function()
  vim.lsp.buf.format({ async = false })
end, { desc = "TOML: 手動format" })

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
