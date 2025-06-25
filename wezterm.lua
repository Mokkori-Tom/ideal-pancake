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
