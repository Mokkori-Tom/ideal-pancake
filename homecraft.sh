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

-- 選択範囲のインデントを「基準行」と同じ幅に揃える（例: カーソル行のインデント幅を取得し、他行へ適用）
vim.keymap.set('v', '<leader>=', function()
  -- カーソル行のインデント幅取得
  local line = vim.fn.line('.')
  local indent = vim.fn.indent(line)
  -- 選択範囲
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  -- 各行のインデントを揃える
  for l = start_line, end_line do
    vim.fn.setline(l, string.rep(' ', indent) .. vim.fn.matchstr(vim.fn.getline(l), [[^\s*\zs.*]]))
  end
end, { noremap = true, silent = true, desc = "選択範囲のインデントをカーソル行に揃える" })

-- 基本的なエディタ設定
vim.opt.clipboard:append("unnamedplus") --クリップボード同期
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
        "nvim-telescope/telescope.nvim",
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",
      },
      cmd = { "Cheatsheet" },
    },

    -- which-key
    {
      "folke/which-key.nvim",
      config = function()
        require("which-key").setup({})
      end,
      event = "VeryLazy",
    },
    -- leap
    {
      "ggandor/leap.nvim",
      config = function()
        require("leap").add_default_mappings()
      end,
      event = "BufReadPost",
    },
    -- telescope
    {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "nvim-lua/popup.nvim" },
      cmd = "Telescope",
      config = function()
        require("telescope").setup({})
      end,
    },
    {
      "nvim-pack/nvim-spectre",
      dependencies = { "nvim-lua/plenary.nvim" },
      cmd = "Spectre",
      config = function()
        require("spectre").setup()
      end,
   },
   {
      "aliqyan-21/darkvoid.nvim",
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("darkvoid")
        -- 背景透過
        for _, group in ipairs({
  "Normal", "NormalNC", "SignColumn", "StatusLine", "StatusLineNC",
  "VertSplit", "WinSeparator", "EndOfBuffer", "MsgArea", "MsgSeparator",
  "NormalFloat", "FloatBorder", "LineNr", "Folded", "CursorLine", "CursorLineNr"
}) do
          vim.api.nvim_set_hl(0, group, { bg = "none" })
        end
          vim.api.nvim_set_hl(0, "Comment", { fg = "#64b5f6", italic = true })     -- コメントに青み＋斜体
          vim.api.nvim_set_hl(0, "Keyword", { fg = "#d3869b", bold = true })      -- キーワードを紫系＋太字
          vim.api.nvim_set_hl(0, "Identifier", { fg = "#ffd700" })                -- 変数名を金色
          vim.api.nvim_set_hl(0, "String", { fg = "#8ec07c" })                    -- 文字列をグリーン
          vim.api.nvim_set_hl(0, "Function", { fg = "#fabd2f", bold = true })     -- 関数名をオレンジ
          vim.api.nvim_set_hl(0, "Type", { fg = "#b8bb26", bold = true })         -- 型名に黄緑
          vim.api.nvim_set_hl(0, "LineNr", { fg = "#a0a0a0", bold = true })    -- やや明るいグレー
          vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffd700", bold = true })  -- カーソル行の番号を金色
          vim.api.nvim_set_hl(0, "Visual", { bg = "#44475a" })  -- ドラキュラ風薄い紫
          -- Tree-sitter (nvim 0.8+)
          vim.api.nvim_set_hl(0, "@comment",    { fg = "#64b5f6", italic = true })
          vim.api.nvim_set_hl(0, "@keyword",    { fg = "#d3869b", bold = true })
          vim.api.nvim_set_hl(0, "@string",     { fg = "#8ec07c" })
          vim.api.nvim_set_hl(0, "@function",   { fg = "#fabd2f", bold = true })
          vim.api.nvim_set_hl(0, "@type",       { fg = "#b8bb26", bold = true })
          vim.api.nvim_set_hl(0, "@variable",   { fg = "#ffd700" })

      end,
     },
    -- ANSIカラー対応カラースキーム（任意）
    --{ "2nthony/vim-ansi-colors" },
  },
  install = { colorscheme = { "darkvoid", "tokyonight", "habamax" } },  -- 優先順で適用
  checker = { enabled = true },
})

-- colorschemeの適用（優先順位に従い自動適用されるので明示的には不要ですが、好みで指定可能）
-- vim.cmd.colorscheme("darkvoid")

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

-- ファイル検索
vim.keymap.set('n', '<Leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'ファイル検索' })
-- Grep検索
vim.keymap.set('n', '<Leader>fg', '<cmd>Telescope live_grep<CR>', { desc = 'Grep検索' })
-- バッファ一覧
vim.keymap.set('n', '<Leader>fb', '<cmd>Telescope buffers<CR>', { desc = 'バッファ一覧' })
-- ヘルプ検索
vim.keymap.set('n', '<Leader>fh', '<cmd>Telescope help_tags<CR>', { desc = 'ヘルプ検索' })
-- 置き換え
vim.keymap.set('n', '<Leader>sr', '<cmd>lua require("spectre").open()<CR>', { desc = 'プロジェクト全体で検索＆置換' })
vim.keymap.set('v', '<Leader>sr', '<esc><cmd>lua require("spectre").open_visual({select_word=true})<CR>', { desc = '選択範囲で検索＆置換' })
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
config.default_prog = { "bash" }

-- GPU描画
config.front_end = "OpenGL"
config.webgpu_power_preference = "HighPerformance"

-- ペイン分割キー設定
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

  # qemu-Alpine-Linux
cat > "$ABSVHOME/qemu-Alpine-setup.txt" <<"EOF"
😎qemu-AlpineLinux🌐
---ディスクイメージの作成でかくても良い
qemu-img create -f qcow2 alpine.qcow2 40G
---qcow2からrawへの変換
既存qcow2をあとからrawに変換
qemu-img convert -O raw alpine.qcow2 alpine.raw
---
　# RAM割り当てオプション 　
# -m 4096 → 4GB割り当て 　
# -m 8192 → 8GB割り当て 　
# -m 16384 → 16GB割り当て 　
# -m 32768 → 32GB割り当て 
---boot.sh
qemu-system-x86_64 \
  -m 8192 \
  -cdrom ./alpine-standard-3.22.0-x86_64.iso \
  -hda ./alpine.qcow2 \
  -boot d \
  -smp 6 \
  -net nic -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080 \
  -vga virtio \
  -display gtk \
  -usb -device usb-tablet
---run.sh
qemu-system-x86_64 \
  -m 8192 \
  -hda ./alpine.qcow2 \
  -boot c \
  -smp 6 \
  -vga virtio \
  -display gtk \
  -usb -device usb-tablet \
  -net nic \
  -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080
---
初期ログイン
root
---設定
eIp address for eth0?->th0->Enter！
HTTP/FTP proxy URL?->Enter！
Which NTP client to run? (busybox, openntpd, chrony, none)->chrony->Enter！
Which mirror do you want to use? (or '?' for list)->「firstなミラー」＝ 一番上のミラー番号、つまり f！
Setup a user? (Enter a username or 'no')->新しいユーザーを作る（カッコいいおすすめ）->neo->※例：neo, タロウ, admin, psion, お好きな名前でOK!->その後にパスワード入力→wheelグループ追加（= sudo 権限付与）などが続く
Enter ssh key or URL for neo (or 'none')->まだSSH鍵がない / あとで設定する→none
Which disk would you like to use? (or '?' for help)->sda
How would you like to use it? (sys, data, crypt, lvm, none)->sys
WARNING: Erase the above disk and continue? [y/N]->y!!
installation is complete. please reboot->完・全・勝・利！！！
QEMUウィンドウを一度閉じる（Ctrl+Q など）または：poweroff
---仮想コンソール切り替えキーの話
Alt + F2	TTY2（2番目の仮想ターミナル）へ切り替え
---ターミナルが占領されてる
ターミナルが占領されてるのは -f（foreground）だから。
バックグラウンド起動にすれば快適よ！
起動方法	ターミナル占有	備考
-f 付き	✅ 占有される	開発中や確認に便利
& 付き	❌ 占有されない	常時稼働や実運用向け
---apkと必要なパッケージ
apk update
apk add git bash curl openssh
rc-service sshd start
rc-update add sshd
---commandごちゃごちゃ
# まずはこれを
$ apk update
$ apk upgrade
# 必須な方々
$ apk add git curl bash
# そもそもnvimが入っていないから#外してリポジトリ有効に
$ vi etc/apk/repositories
# ご存じnvim
$ apk add nvim
# sudoのインストール
$ apk add sudo
# なんだっけ?
$ apk add kbd
# これが無くては始まらない
$ apk add wget
# 完コピ
$ wget -mirror --no-parent https://~
# grepをpipeでつなぐと素晴らしい
$ search /hogehoge | grep hoge
# ファイル名検索
$ find /./. -name '*hote*'
# gitクローンつまりレポジトリのlocalへの複製
$ git clone https:~
# apkのレポジトリを編集
$ nvim /etc/apk/repositories
# まず行う。apkを最新の状態へ。
$ apk update
# 素晴らしいターミナル革命-testingリポジトリを有効にしておくこと
$ apk add kmscon
# GUI無いverの軽量emacs
$ apk add emacs-nox
# 編集はvisudoでどうぞ
$ /etc/sudoers
# ユーザーをwheelグループへ追加
$ adduser username wheel
# ユーザーのグループ確認
$ groups username
# なんだっけ?
$ sudo whoami
# サスペンド
$ exit
# なんだっけ？
$ apk add kbd
# その名の通り
$ poweroff
# コンソールemacs-CLIでは一緒
$ emacs -nw
# emacs-auto-saveはここから
$ git clone https://github.com/manateelazycat/auto-save.git ~/.emacs.d/site-lisp/auto-save
# listからgrep
$ fc-list | grep -i 'mono'
# なんだっけ？
$ doas -s
# 権限管理
$ visudo
# mini_httpdサーバホスティングの開始
$ mini_httpd -d ~/ -p 8080
# なんだっけ？
$ sudo rc-update add sshd
# opensshホスティングの開始
$ sudo rc-service sshd start
# opensshの稼働状況確認
$ sudo rc-service sshd status
# pythonでサーバ立てたい
python -m http.server 8000
# IPが知りたい時は
$ ip a
# edge/testingリポジトリが有効ならそのまま導入可もし有効化してなければ /etc/apk/repositories に#を外すコミュニティリポジトリ有効
# edge/testingリポジトリが有効ならそのまま導入可もし有効化してなければ /etc/apk/repositories に
$ https://dl-cdn.alpinelinux.org/alpine/edge/testing
# skkの辞書-DL
$ mkdir -p ~/.skk
$ curl -L -o ~/.skk/SKK-JISYO.L https://raw.githubusercontent.com/skk-dev/dict/master/SKK-JISYO.L
# skkの導入init.el
---
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(use-package ddskk
  :ensure t)

(global-set-key (kbd "C-x j") 'skk-auto-fill-mode)
(setq skk-large-jisyo "~/.skk/SKK-JISYO.L")
---
# fonts_install
$ curl https://github.com/yuru7/HackGen/releases/download/v2.10.0/HackGen_NF_v2.10.0.zip
$ sudo apk add wget unzip fontconfig
$ sudo unzip download/v2.10.0/HackGen_NF_v2.10.0.zip -d /usr/share/fonts/hackgen
# kmscon_run
$ kmscon --font-name="HackGen35 Console NF" --font-size=18
# Login_error
$ sudo chmod u+s /bin/login
# wget
$ wget --no-host-directories http://10.0.2.2:8000/
# curl-get
$ curl http://localhost:8080/
# ポート占有確認
$ netstat -a -o | grep 8080
# ssh-connect
$ ssh -p 2222 neo@localhost
# ssh-DL
$ scp -P 2222 -r neo@localhost:~/test ./
# DNS設定
$ echo "nameserver 00.00.00" > /etc/resolv.conf
# 純粋CLIで「クリップボードのようなこと」をしたいなら？
$ cat > /tmp/buffer.txt
$ less /tmp/buffer.txt
#「less is more（lessはmoreより多機能）」
# UNIXの伝統的なジョークです
---
apk add chafa
chafa image.png
ANSI色付きディスプレイで、文字セルを使った画像表示が可能
--symbols オプションで文字種類を変更（block, braille など）
chafa --symbols braille image.png
→ 点(ドット)芸が強調された出力になります。
---
exit コマンドを入力
Ctrl + D（EOF送信）
どちらも即時にSSHセッションが終了します。
---
どうやらkmsconを起動した状態でsshは接続しない方がよい
---
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
