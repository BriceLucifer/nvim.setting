-- Neovide 专用设置；在其它前端（终端 nvim）里直接跳过。
if not vim.g.neovide then
  return
end

local g = vim.g
local map = vim.keymap.set

-- 输入与鼠标
g.neovide_input_macos_option_key_is_meta = "both" -- Option 当 Alt，<A-x> 映射可用。
g.neovide_hide_mouse_when_typing = true
g.neovide_remember_window_size = true

-- 空闲时降帧省电；活动时保持默认刷新率。
g.neovide_refresh_rate_idle = 5

-- 滚动动画交给 neoscroll，避免两层动画叠加变拖沓。
g.neovide_scroll_animation_length = 0

-- 浮窗不加阴影：与终端一致，只用圆角边框区分；阴影会压暗浮窗周围的文字。
g.neovide_floating_shadow = false

-- 中文输入法：只在 insert / 命令行开启，normal 模式不被输入法拦截。
g.neovide_input_ime = false
local ime = vim.api.nvim_create_augroup("NeovideIme", { clear = true })
local function set_ime(on)
  return function()
    g.neovide_input_ime = on
  end
end
vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, { group = ime, callback = set_ime(true) })
vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, { group = ime, callback = set_ime(false) })

-- Cmd 快捷键：复制、粘贴、保存（系统剪贴板已由 clipboard=unnamedplus 接管）。
map("v", "<D-c>", '"+y', { desc = "Copy (复制)" })
map({ "n", "v" }, "<D-v>", '"+P', { desc = "Paste (粘贴)" })
map("i", "<D-v>", "<C-r><C-o>+", { desc = "Paste (粘贴)" })
map("c", "<D-v>", "<C-r>+", { desc = "Paste (粘贴)" })
map("t", "<D-v>", [[<C-\><C-n>"+Pi]], { desc = "Paste (粘贴)" })
map({ "n", "v" }, "<D-s>", "<cmd>write<cr>", { desc = "Save (保存)" })
map("i", "<D-s>", "<cmd>write<cr>", { desc = "Save (保存)" })

-- Cmd +/-/0 缩放字号。
g.neovide_scale_factor = 1.0
local function zoom(factor)
  return function()
    g.neovide_scale_factor = factor and math.max(0.5, g.neovide_scale_factor * factor) or 1.0
  end
end
map({ "n", "i", "v", "t" }, "<D-=>", zoom(1.1), { desc = "Zoom in (放大字号)" })
map({ "n", "i", "v", "t" }, "<D-->", zoom(1 / 1.1), { desc = "Zoom out (缩小字号)" })
map({ "n", "i", "v", "t" }, "<D-0>", zoom(nil), { desc = "Reset zoom (重置字号)" })
