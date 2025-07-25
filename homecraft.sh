#!/bin/bash
set -e

usage() {
  cat <<EOF
homecraft - Virtual HOME environment generator and launcher

Usage:
  homecraft <name|path> [template] [-f|--force] [-r|--reuse] [--date] [-d DIR] [-zsh] [-h|--help]

  <name|path>   : "myenv" creates ./myenv, "/foo/bar" creates at absolute path.
  [template]    : Template directory name (if omitted, minimal dotfiles are auto-generated)
  -f, --force   : Overwrite (remove) existing HOME if already present
  -r, --reuse   : Reuse existing HOME as is
  --date        : Append _YYYYMMDD_HHMM to HOME name (or use __DATE__ in name)
  -d DIR        : Set parent directory (default: current directory)
  -zsh          : Start with zsh (requires .zshrc in template or will auto-generate)
  -h, --help    : Show this help

Examples:
  homecraft dev1
  homecraft /mnt/data/dev2
  homecraft testenv pytemplate --date -d /tmp/workenv
  homecraft "test-__DATE__"
  homecraft myzsh zshtemplate -zsh
EOF
  exit 1
}

ACTION=""
VHOME_BASE="."
DATE_SUFFIX=""
POSITIONAL=()
ZSH_MODE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force) ACTION=force; shift ;;
    -r|--reuse) ACTION=reuse; shift ;;
    --date) DATE_SUFFIX="_$(date +%Y%m%d_%H%M)"; shift ;;
    -d) VHOME_BASE="$2"; shift 2 ;;
    -zsh) ZSH_MODE=1; shift ;;
    -h|--help) usage ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [ -z "$1" ]; then usage; fi
BASE_NAME="$1"
VHOME_NAME="${BASE_NAME//__DATE__/$(date +%Y%m%d_%H%M)}${DATE_SUFFIX}"

if [[ "$VHOME_NAME" = /* ]]; then
  VHOME="$VHOME_NAME"
else
  VHOME="$VHOME_BASE/$VHOME_NAME"
fi

TEMPLATE="$2"
if [ -n "$TEMPLATE" ]; then
  if [[ "$TEMPLATE" = /* ]]; then
    TEMPLATE_PATH="$TEMPLATE"
  else
    TEMPLATE_PATH="$(dirname "$VHOME")/../envtemplates/$TEMPLATE"
  fi
fi

if [ -d "$VHOME" ]; then
  case "$ACTION" in
    force) rm -rf "$VHOME" ;;
    reuse) ;;
    *)
      echo -e "\033[33m$VHOME already exists. Use -f (force) or -r (reuse).\033[0m"
      exit 2
      ;;
  esac
fi

 # If we're reusing, skip all the “populate” steps:
if [ "$ACTION" = "reuse" ]; then
  echo -e "\033[32mReusing existing virtual HOME: $VHOME\033[0m"
  ABSVHOME="$(cd "$VHOME" && pwd)"
  if [ "$ZSH_MODE" = 1 ]; then
    cd "$ABSVHOME"
    exec env HOME="$ABSVHOME" zsh
  else
    exec env HOME="$ABSVHOME" bash --noprofile --rcfile "$ABSVHOME/.bashrc"
  fi
fi

if [ -n "$TEMPLATE_PATH" ]; then
  cp -a "$TEMPLATE_PATH" "$VHOME"
else
  mkdir -p "$VHOME"
  ABSVHOME="$(cd "$VHOME" && pwd)"

  # record parent virtual-home
  PARENTHOME="${HOME:-}"
  if [ -n "$PARENTHOME" ] && [ "$PARENTHOME" != "$ABSVHOME" ]; then
    echo "$PARENTHOME" > "$ABSVHOME/.virtualhome"
  fi

  # .bashrc (guarded: force or create-only)
  if [ "$ACTION" = "force" ] || [ ! -f "$ABSVHOME/.bashrc" ]; then
cat > "$ABSVHOME/.bashrc" <<'EOF'
export HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HOME"

get_home_depth() {
  local d="$HOME"
  local depth=1
  while [ -f "$d/.virtualhome" ]; do
    depth=$((depth + 1))
    d="$(cat "$d/.virtualhome")"
  done
  echo $depth
}

PROMPT_COMMAND='
  HOME_DEPTH=$(get_home_depth)
  HOME_NAME=$(basename "$HOME")
  VENV=""
  if [ -n "$VIRTUAL_ENV" ]; then
    VENV="\[\e[35m\]("$(basename "$VIRTUAL_ENV")")\[\e[0m\]"
  fi
  PS1="$VENV\[\e[33m\][Depth:$HOME_DEPTH]\[\e[0m\]\[\e[32m\][$HOME_NAME]\[\e[0m\][\u@\h \[\e[36m\]$(date +%Y%m%d_%H:%M)\[\e[0m\] \w]\n\$ "
'

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
alias ll='ls -la --color=auto'
export LANG=en_US.UTF-8
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=10000
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="ls:bg:fg:history:pwd"
export EDITOR=vim
#export PATH="$HOME/nvim/bin:$PATH"
#source ./myenv/Scripts/activate
shopt -s histappend
[ -f "$HISTFILE" ] && history -r
trap 'history -a' EXIT
EOF
  fi

  # neovim config (per-profile)
  mkdir -p "$ABSVHOME/.config/nvim"
  cat > "$ABSVHOME/.config/nvim/init.lua" <<"EOF"
-- Bootstrap lazy.nvim ~/.config/nvim/init.lua
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
      "aliqyan-21/darkvoid.nvim",
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("darkvoid")
        for _, group in ipairs({
          "Normal", "NormalNC", "SignColumn", "StatusLine", "StatusLineNC",
          "VertSplit", "WinSeparator", "EndOfBuffer", "MsgArea", "MsgSeparator",
          "NormalFloat", "FloatBorder", "LineNr", "Folded", "CursorLine", "CursorLineNr"
        }) do
          vim.api.nvim_set_hl(0, group, { bg = "none" })
        end
        vim.api.nvim_set_hl(0, "Comment",    { fg = "#64b5f6", italic = true })
        vim.api.nvim_set_hl(0, "Keyword",    { fg = "#d3869b", bold = true })
        vim.api.nvim_set_hl(0, "Identifier", { fg = "#ffd700" })
        vim.api.nvim_set_hl(0, "String",     { fg = "#8ec07c" })
        vim.api.nvim_set_hl(0, "Function",   { fg = "#fabd2f", bold = true })
        vim.api.nvim_set_hl(0, "Type",       { fg = "#b8bb26", bold = true })
        vim.api.nvim_set_hl(0, "LineNr",     { fg = "#a0a0a0", bold = true })
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffd700", bold = true })
        vim.api.nvim_set_hl(0, "Visual",     { bg = "#44475a" })
        -- Tree-sitter (nvim 0.8+)
        vim.api.nvim_set_hl(0, "@comment",   { fg = "#64b5f6", italic = true })
        vim.api.nvim_set_hl(0, "@keyword",   { fg = "#d3869b", bold = true })
        vim.api.nvim_set_hl(0, "@string",    { fg = "#8ec07c" })
        vim.api.nvim_set_hl(0, "@function",  { fg = "#fabd2f", bold = true })
        vim.api.nvim_set_hl(0, "@type",      { fg = "#b8bb26", bold = true })
        vim.api.nvim_set_hl(0, "@variable",  { fg = "#ffd700" })
      end,
    },
    -- { "2nthony/vim-ansi-colors" },
  },
  install = { colorscheme = { "darkvoid", "tokyonight", "habamax" } },
  checker = { enabled = true },
})

-- カラー設定（install.colorscheme優先。明示指定も可能）
-- vim.cmd.colorscheme("darkvoid")

-- lualineセットアップ
require("lualine").setup {}

-- gitsigns.nvimセットアップ
require("gitsigns").setup()

-- nvim-cmp, LuaSnip, lspkindのセットアップ
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
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  }),
  formatting = {
    format = require("lspkind").cmp_format({ with_text = true, maxwidth = 50 })
  },
})

-- LSPサーバのセットアップ（Python, Go, Deno, taplo）
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
for _, lsp in ipairs({ "pylsp", "gopls", "denols", "taplo" }) do
  lspconfig[lsp].setup({ capabilities = capabilities })
end

-- 引数情報の表示
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

-- TOML保存時の自動format
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*.toml",
--   callback = function()
--     vim.lsp.buf.format({ async = false })
--   end,
-- })

-- 2. 手動format用キーマップ（n: normal mode）
vim.keymap.set('n', '<leader>cf', function()
  vim.lsp.buf.format({ async = false })
end, { desc = "TOML: 手動format" })

require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = { "taplo" } })
EOF

  # minimal .gitconfig
cat > "$ABSVHOME/.gitconfig" <<"EOF"
[user]
    name = Virtual User
    email = example@example.com
[core]
    editor = vim
EOF


  # minimal .inputrc
cat > "$ABSVHOME/.inputrc" <<"EOF"
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
EOF

  # .zshrc (guarded: force or create-only)
  if [ "$ZSH_MODE" = 1 ]; then
    if [ "$ACTION" = "force" ] || [ ! -f "$ABSVHOME/.zshrc" ]; then
cat > "$ABSVHOME/.zshrc" <<'EOF'
# cd into the virtual HOME
cd "$HOME"
get_home_depth() {
  local d="$HOME"
  local depth=1
  while [[ -f "$d/.virtualhome" ]]; do
    depth=$((depth + 1))
    d=$(cat "$d/.virtualhome")
  done
  echo $depth
}
precmd() {
  export HOME_DEPTH=$(get_home_depth)
  export HOME_NAME=$(basename "$HOME")
  local VENV=""
  if [[ -n "$VIRTUAL_ENV" ]]; then
    VENV="%F{magenta}($(basename $VIRTUAL_ENV))%f"
  fi
  PROMPT="$VENV%F{yellow}[Depth:$HOME_DEPTH]%f%F{green}[$HOME_NAME]%f[%n@%m %F{cyan}%D{%Y%m%d_%H:%M}%f %~]\n%# "
}

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
alias ll='ls -la --color=auto'
export LANG=en_US.UTF-8
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
[ -f "$HISTFILE" ] && fc -R "$HISTFILE"
autoload -Uz add-zsh-hook
# add-zsh-hook zshexit 'fc -A'
EOF
    fi
  fi

fi

ABSVHOME="$(cd "$VHOME" && pwd)"

echo -e "\033[32mVirtual HOME: $VHOME is ready.\033[0m"

if [ "$ZSH_MODE" = 1 ]; then
  # まず仮想HOMEに移動してから zsh を起動
  cd "$ABSVHOME"
  env HOME="$ABSVHOME" zsh
else
  RCFILE="$ABSVHOME/.bashrc"
  env HOME="$ABSVHOME" bash --noprofile --rcfile "$RCFILE"
fi
