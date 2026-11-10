-- 目录交给 oil；在插件加载前禁用 netrw。
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- 用不到的内置功能：四种语言的远程插件宿主、压缩包浏览、教程、导出 HTML。
for _, provider in ipairs({ "python3", "ruby", "node", "perl" }) do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end
for _, plugin in ipairs({ "gzip", "tar", "tarPlugin", "zip", "zipPlugin", "tutor_mode_plugin", "2html_plugin" }) do
  vim.g["loaded_" .. plugin] = 1
end

local opt = vim.opt

-- 没有「下巴」：不要状态栏、不要命令行、不要标签栏。
-- 状态信息在每个窗口右上角的浮动胶囊里，命令行和消息按需浮出来（见 ui.lua）。
opt.laststatus = 0
opt.cmdheight = 0
opt.showtabline = 0
opt.showmode = false
opt.showcmd = false -- 否则每按一个前缀键，右下角都会弹一个只有按键名的小窗。
opt.ruler = false
-- laststatus=0 时，上下分屏之间仍会画一行状态行；把它画成一条横线，当分隔线用。
opt.statusline = "%#WinSeparator#%{repeat('─', winwidth(0))}"

-- 显示
opt.number = true
opt.relativenumber = false -- 当前窗口的相对行号和当前行由 ui.lua 按焦点开启。
opt.cursorline = false
opt.cursorlineopt = "number" -- 当前行只点亮行号，代码区不铺横条。
opt.termguicolors = true
opt.signcolumn = "no" -- Git 标记画在自己的行号列里（ui.lua），不需要符号列。
opt.winborder = "rounded" -- 浮窗统一圆角。
opt.fillchars:append({ eob = " ", fold = " ", diff = "╱" }) -- 文件末尾不显示 ~；折叠行不拖一串点。
opt.foldtext = "" -- 折叠后的那一行保留语法高亮。
opt.pumheight = 12
opt.breakindent = true -- 换行显示的长行接着原缩进对齐。

-- 分屏和搜索
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen" -- 开关分屏时其他窗口的文字不跳动。
opt.ignorecase = true
opt.smartcase = true
opt.wrap = false
opt.scrolloff = 6
opt.sidescrolloff = 6
opt.inccommand = "split" -- :s 替换时实时预览。

-- 剪贴板、撤销与折叠
opt.clipboard = "unnamedplus" -- y / p 直接使用系统剪贴板。
opt.undofile = true -- 持久撤销，重开文件仍可撤销。
opt.swapfile = false
opt.autoread = true
opt.confirm = true -- 有未保存改动时 :q 改为询问，而不是报错拒绝。
opt.foldmethod = "expr" -- 折叠交给 treesitter；默认全部展开。
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99

-- 缩进
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4

-- 交互
opt.updatetime = 200
opt.timeoutlen = 400

-- 找到 fish 时使用，否则保留默认 shell。
local fish = vim.fn.exepath("fish")
if fish ~= "" then
  opt.shell = fish
end

-- Neovide：字体在 ~/.config/neovide/config.toml 里设置（guifont 会覆盖它，所以不在这里设）。
-- 行高对应 Ghostty 的 adjust-cell-height。
if vim.g.neovide then
  opt.linespace = 2
end

local group = vim.api.nvim_create_augroup("ConfigOptions", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

autocmd("FileType", {
  group = group,
  pattern = { "c", "cpp" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- Markdown / 文本：笔记按窗口宽度换行，不在单词中间断开。
autocmd("FileType", {
  group = group,
  pattern = { "markdown", "text", "typst" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- 复制后短暂高亮被复制的内容。
autocmd("TextYankPost", {
  group = group,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- 重新打开文件时回到上次光标位置。
autocmd("BufReadPost", {
  group = group,
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 切回 Neovim 或进入缓冲区时检查文件是否被外部修改（配合 autoread）。
-- 只在普通文件缓冲区里检查：插件更新确认页、搜索窗口、输入框这类特殊缓冲区不需要，
-- 检查时又会顺带重新读取其他被改动的文件，那些文件的自动命令出错不该弹到当前界面上。
autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = group,
  callback = function()
    if vim.bo.buftype == "" and vim.fn.mode() ~= "c" then
      pcall(vim.cmd.checktime)
    end
  end,
})
