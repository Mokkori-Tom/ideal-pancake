
local wezterm = require 'wezterm'

local config = wezterm.config_builder()

-- 基本設定
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBar"

-- フォント設定
config.font = wezterm.font("HackGen Console NF")
config.font_size = 13.0

-- ウィンドウ設定
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.7  -- 70%の透明度

-- カラー設定
config.colors = {
  foreground = '#ffffff',  -- 前景色
  background = '#1e1e1e',  -- 背景色
  cursor_bg = '#ffcc00',   -- カーソルの背景色
  cursor_fg = '#000000',   -- カーソルの前景色
  cursor_border = '#ffcc00', -- カーソルの境界色
  selection_fg = '#ffffff', -- 選択時の前景色
  selection_bg = '#007acc', -- 選択時の背景色
  ansi = { '#000000', '#ff5555', '#50fa7b', '#f1fa8c', '#bd93f9', '#ff79c6', '#8be9fd', '#ffffff' },
  brights = { '#4d4d4d', '#ff6e6e', '#69ff94', '#ffffa5', '#d6acff', '#ff92df', '#a4ffff', '#ffffff' },
}

-- タブバー設定
config.tab_bar_at_bottom = true  -- タブバーを下に表示
config.show_new_tab_button_in_tab_bar = false  -- 新しいタブボタンを非表示

-- デフォルトシェルの設定
config.default_prog = {'bash', '-c', 'cd ~/ && exec bash'}  -- ここを変更して他のシェルを指定できます

-- WebGPU設定
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

enable_bracketed_paste = false

return config
