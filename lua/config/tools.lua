-- 工具：文件管理（oil）、搜索（FZF-Lua）、批量替换（GrugFar）、Git 标记、屏幕内跳转（Flash）。
-- 快捷键见 keymaps.lua。
local M = {}

--------------------------------------------------------------------------------
-- oil：目录就是一个可以编辑的缓冲区。改名直接改字，删除直接删行，:w 生效。
-- 极简显示：只有图标和名字。用 nvim 某个目录 打开目录时也是它。
--------------------------------------------------------------------------------
require("oil").setup({
  default_file_explorer = true,
  columns = { "icon" },
  delete_to_trash = true, -- 删除进废纸篓，不直接抹掉。
  skip_confirm_for_simple_edits = true, -- 单纯改名、新建不再弹确认。
  watch_for_changes = true,
  view_options = { show_hidden = false }, -- g. 切换显示隐藏文件。
  win_options = { number = false, relativenumber = false, cursorline = true, cursorlineopt = "both" },
  float = { padding = 2, max_width = 72, max_height = 28, border = "rounded" },
  confirmation = { border = "rounded" },
  keymaps = {
    ["q"] = { "actions.close", mode = "n" },
    ["<C-v>"] = { "actions.select", opts = { vertical = true } },
    ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-r>"] = "actions.refresh",
    -- Ctrl-h / Ctrl-l 留给窗口切换。
    ["<C-h>"] = false,
    ["<C-l>"] = false,
  },
})

--------------------------------------------------------------------------------
-- FZF-Lua 按需加载：第一次搜索时才加载并初始化，启动时不付这部分开销。
-- 本配置里用到它的地方（快捷键、启动页、vim.ui.select）都经过 M.fzf()。
--------------------------------------------------------------------------------
local fzf_ready = false
function M.fzf()
  local fzf = require("fzf-lua")
  if not fzf_ready then
    fzf.setup({
      -- 以内置的 Telescope 外观为底：输入框在下、结果在上、预览在右、标题嵌在边框上。
      "telescope",
      -- 默认不含操作符等待模式（o），而文本对象（如 daf）定义在这个模式里。
      keymaps = { modes = { "n", "i", "c", "v", "t", "o" } },
      defaults = { formatter = "path.filename_first" }, -- 文件名在前，目录在后变暗。
      winopts = {
        height = 0.8,
        width = 0.8,
        row = 0.45,
        border = "rounded",
        backdrop = 100, -- 不压暗背后的编辑区。
        title_pos = "center",
        preview = { horizontal = "right:55%", flip_columns = 100, scrollbar = false },
      },
      -- 颜色不用 Telescope 那套，和本配置其他浮窗统一：无底色、暗边框。
      hls = {
        normal = "NormalFloat",
        border = "FloatBorder",
        title = "FloatTitle",
        preview_normal = "NormalFloat",
        preview_border = "FloatBorder",
        preview_title = "FzfLuaPreviewTitle",
        cursorline = "PmenuSel",
      },
      fzf_colors = {
        ["fg"] = { "fg", "Comment" },
        ["bg"] = "-1",
        ["hl"] = { "fg", "Function" },
        ["fg+"] = { "fg", "Normal" },
        ["bg+"] = { "bg", "PmenuSel" },
        ["hl+"] = { "fg", "Function" },
        ["info"] = { "fg", "Comment" },
        ["border"] = { "fg", "FloatBorder" },
        ["separator"] = { "fg", "FloatBorder" },
        ["gutter"] = "-1",
        ["query"] = { "fg", "Normal" },
        ["prompt"] = { "fg", "Function" },
        ["pointer"] = { "fg", "Constant" },
        ["marker"] = { "fg", "Constant" },
        ["header"] = { "fg", "Comment" },
      },
    })
    fzf_ready = true
  end
  return fzf
end

-- 返回一个「打开某个搜索」的函数，给按键和启动页用。
function M.pick(picker, opts)
  return function() M.fzf()[picker](opts) end
end

-- GrugFar：批量搜索替换面板。面板内 <localleader>r 替换、<localleader>c 关闭。
require("grug-far").setup({})

-- Git 修改标记：统一成一根细条，由 ui.lua 的行号列画在行号右边。
-- 启动完成后才加载（见 plugins.lua 的 later）。
require("config.plugins").later(function()
  local bar = { text = "▎" }
  require("gitsigns").setup({
    signs = { add = bar, change = bar, delete = bar, topdelete = bar, changedelete = bar, untracked = bar },
    signs_staged = { add = bar, change = bar, delete = bar, topdelete = bar, changedelete = bar },
    preview_config = { border = "rounded" },
  })
end)

require("flash").setup({})

return M
