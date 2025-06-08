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
  PS1="\[\e[33m\][Depth:\$HOME_DEPTH]\[\e[0m\]\[\e[32m\][\$HOME_NAME]\[\e[0m\][\u@\h \[\e[36m\]`date +%Y%m%d_%H:%M`\[\e[0m\] \w]\n\$ "
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
#export PATH="$HOME/nvim/bin:$PATH"
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

-- 基本的なエディタ設定
vim.opt.number = true             -- 行番号を表示
vim.opt.relativenumber = true     -- 相対行番号を表示
vim.opt.expandtab = true          -- タブをスペースに変換
vim.opt.shiftwidth = 2            -- インデントの幅
vim.opt.tabstop = 2               -- タブ幅
vim.opt.smartindent = true        -- スマートインデント
vim.opt.wrap = true               -- 行の折り返しをしない
vim.opt.linebreak = true          -- 単語の途中で折り返さない
vim.opt.showbreak = '↪ '          -- 折り返し行の先頭に表示（お好みで）
vim.opt.cursorline = true         -- カーソル行の強調
vim.opt.termguicolors = true      -- 24bitカラー
vim.opt.clipboard = "unnamedplus" -- クリップボード連携
vim.opt.signcolumn = "yes"        -- サインカラム常に表示
vim.opt.undofile = true           -- アンドゥファイルを有効化

-- lazy.nvimプラグイン設定
require("lazy").setup({
  spec = {
    -- 基本プラグイン
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "nvim-lualine/lualine.nvim" },
    { "folke/tokyonight.nvim" },
    { "mbbill/undotree", cmd = "UndotreeToggle" },
    {
      "Pocco81/auto-save.nvim",
      config = function()
        require("auto-save").setup({})
      end,
      event = { "InsertLeave", "TextChanged" },
    },
    { "tpope/vim-fugitive" },
    { "lewis6991/gitsigns.nvim" },
    { "kdheepak/lazygit.nvim" },
    { "sindrets/diffview.nvim" },

    -- LSP＆補完
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

    -- チートシート
    {
      "sudormrfbin/cheatsheet.nvim",
      dependencies = {
        { "nvim-telescope/telescope.nvim" },
        { "nvim-lua/popup.nvim" },
        { "nvim-lua/plenary.nvim" },
      },
      cmd = { "Cheatsheet" },
    },
    -- ANSIカラー対応カラースキーム（任意）
    --{ "2nthony/vim-ansi-colors" },
  },
  install = { colorscheme = { "ansi", "tokyonight", "habamax" } },  -- 優先順で適用
  checker = { enabled = true },
})

-- colorschemeの適用（優先順位に従い自動適用されるので明示的には不要ですが、好みで指定可能）
vim.cmd.colorscheme("vim")

-- lualineのセットアップ
require("lualine").setup {}

-- gitsigns.nvimセットアップ
require("gitsigns").setup()

-- nvim-cmp, LuaSnip, lspkindの初期設定
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
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

-- LSPサーバのセットアップ（Python, TypeScript）
local lspconfig = require("lspconfig")
lspconfig.pylsp.setup({})
lspconfig.ts_ls.setup({})

-- 引数情報の表示
require("lsp_signature").setup({})
EOF

  # minimal .gitconfig
cat > "$ABSVHOME/.gitconfig" <<"EOF"
[user]
    name = Virtual User
    email = example@example.com
[core]
    editor = vim
EOF

  # wezterm.lua 
cat > "$ABSVHOME/wezterm.lua" <<"EOF"
local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- 基本設定
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBar"

-- フォント設定
config.font = wezterm.font("HackGen Console NF")
config.font_size = 18.0

-- ウィンドウ設定
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_background_opacity = 0.7

-- カラー設定
config.colors = {
  foreground = '#ffffff',
  background = '#1e1e1e',
  cursor_bg = '#ffcc00',
  cursor_fg = '#000000',
  cursor_border = '#ffcc00',
  selection_fg = '#ffffff',
  selection_bg = '#007acc',
  ansi = { '#000000', '#ff5555', '#50fa7b', '#f1fa8c', '#bd93f9', '#ff79c6', '#8be9fd', '#ffffff' },
  brights = { '#4d4d4d', '#ff6e6e', '#69ff94', '#ffffa5', '#d6acff', '#ff92df', '#a4ffff', '#ffffff' },
}

-- タブバー設定
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false

-- デフォルトシェル
config.default_prog = { "bash.exe" }

-- GPU描画
config.front_end = "OpenGL"
config.webgpu_power_preference = "HighPerformance"

-- 🔑 ペイン分割キー設定
config.keys = {
  -- 垂直分割（上下）
  {
    key = "d",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" },
  },
  -- 水平分割（左右）
  {
    key = "s",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" },
  },
  -- 移動（hjkl）
  {
    key = "h",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Left",
  },
  {
    key = "l",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Right",
  },
  {
    key = "k",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Up",
  },
  {
    key = "j",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection "Down",
  },
}

return config
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
  PROMPT="%F{yellow}[Depth:$HOME_DEPTH]%f%F{green}[$HOME_NAME]%f[%n@%m %F{cyan}%D{%Y%m%d_%H:%M}%f %~]\n%# "
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
