-- 界面：配色、消息与输入、行号列、浮动状态胶囊、缩进线、滚动、按键提示。
local api = vim.api
local group = api.nvim_create_augroup("ConfigUi", { clear = true })

-- 普通文件缓冲区；工具面板（oil、搜索、帮助、启动页）不算。
local function is_file(buf)
  return vim.bo[buf].buftype == "" and vim.bo[buf].buflisted
end

--------------------------------------------------------------------------------
-- 配色：Kanagawa，深色 wave，浅色 lotus，跟随系统（终端回报背景色后 Neovim 会自动重载配色）。
-- transparent 让编辑区沿用终端 / 窗口自身的背景。
-- 本配置自己的高亮组（Bar* 胶囊、Dash* 启动页）也在这里定义，颜色全部取自主题，深浅切换时一起换。
--------------------------------------------------------------------------------
require("kanagawa").setup({
  transparent = true,
  background = { dark = "wave", light = "lotus" },
  colors = { theme = { all = { ui = { bg_gutter = "none" } } } },
  overrides = function(colors)
    local t = colors.theme
    local fill = t.ui.bg_p1 -- 胶囊底色：比背景亮一档。
    local hl = {
      -- 浮窗统一：无底色，只留圆角边框。
      NormalFloat = { fg = t.ui.fg, bg = "none" },
      FloatBorder = { fg = t.ui.bg_p2, bg = "none" },
      FloatTitle = { fg = t.syn.fun, bg = "none", bold = true },
      WinSeparator = { fg = t.ui.bg_p2 },
      StatusLine = { fg = t.ui.bg_p2, bg = "none" },
      StatusLineNC = { fg = t.ui.bg_p2, bg = "none" },
      MsgArea = { fg = t.ui.fg_dim },
      CursorLineNr = { fg = t.syn.constant, bold = true },
      Folded = { bg = t.ui.bg_p1 },

      -- 补全菜单。
      Pmenu = { fg = t.ui.fg_dim, bg = "none" },
      PmenuSel = { fg = "none", bg = t.ui.bg_p2, bold = true },
      PmenuSbar = { bg = "none" },
      PmenuThumb = { bg = t.ui.bg_p2 },
      BlinkCmpMenuBorder = { link = "FloatBorder" },
      BlinkCmpDocBorder = { link = "FloatBorder" },
      BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },
      BlinkCmpGhostText = { fg = t.ui.nontext },
      BlinkCmpLabelDetail = { fg = t.syn.comment },
      BlinkCmpLabelDescription = { fg = t.syn.comment },
      PmenuExtra = { fg = t.syn.comment, bg = "none" },
      PmenuExtraSel = { fg = t.syn.comment, bg = t.ui.bg_p2 },
      PmenuKind = { fg = t.ui.fg_dim, bg = "none" },
      PmenuKindSel = { fg = t.ui.fg_dim, bg = t.ui.bg_p2 },

      -- 搜索窗口（FZF-Lua）：和其他浮窗同一套边框和标题。
      FzfLuaNormal = { link = "NormalFloat" },
      FzfLuaBorder = { link = "FloatBorder" },
      FzfLuaTitle = { link = "FloatTitle" },
      FzfLuaPreviewNormal = { link = "NormalFloat" },
      FzfLuaPreviewBorder = { link = "FloatBorder" },
      FzfLuaPreviewTitle = { fg = t.ui.special, bg = "none" },
      FzfLuaFzfSeparator = { link = "FloatBorder" },
      FzfLuaFzfBorder = { link = "FloatBorder" },
      BlinkCmpLabelMatch = { fg = t.syn.fun, bold = true },

      -- 缩进线：平时几乎看不见，当前作用域亮一档。
      IblIndent = { fg = t.ui.bg_p1, nocombine = true },
      IblScope = { fg = t.ui.special, nocombine = true },

      -- Git 细条。
      GitSignsAdd = { fg = t.vcs.added },
      GitSignsChange = { fg = t.vcs.changed },
      GitSignsDelete = { fg = t.vcs.removed },

      -- 通知卡片：图标按级别着色；警告和错误连边框一起着色。
      NotifyText = { fg = t.ui.fg, bg = "none" },
      NotifyInfoIcon = { fg = t.diag.info },
      NotifyWarnIcon = { fg = t.diag.warning },
      NotifyErrorIcon = { fg = t.diag.error },
      NotifyInfoBorder = { fg = t.ui.bg_p2, bg = "none" },
      NotifyWarnBorder = { fg = t.diag.warning, bg = "none" },
      NotifyErrorBorder = { fg = t.diag.error, bg = "none" },
      TinyCmdlineNormal = { fg = t.ui.fg, bg = "none" },

      -- 浮动状态胶囊。
      InclineNormal = { bg = "none" },
      InclineNormalNC = { bg = "none" },
      BarCap = { fg = fill, bg = "none" },
      BarText = { fg = t.ui.fg, bg = fill, bold = true, italic = true },
      BarTextModified = { fg = t.syn.constant, bg = fill, bold = true, italic = true },
      BarSep = { fg = t.ui.nontext, bg = fill },
      BarHint = { fg = t.diag.hint, bg = fill },
      BarTextNC = { fg = t.ui.special, bg = fill, italic = true },
      BarDim = { fg = t.ui.special, bg = fill },
      BarModified = { fg = t.syn.constant, bg = fill },
      BarError = { fg = t.diag.error, bg = fill },
      BarWarn = { fg = t.diag.warning, bg = fill },
      BarAdd = { fg = t.vcs.added, bg = fill },
      BarChange = { fg = t.vcs.changed, bg = fill },
      BarDelete = { fg = t.vcs.removed, bg = fill },
      BarBranch = { fg = t.syn.keyword, bg = fill },
      BarLsp = { fg = t.syn.type, bg = fill },
      BarActivity = { fg = t.syn.constant, bg = fill, bold = true },

      -- 启动页的菜单（星系画面自己的颜色在 dashboard.lua 里）。
      DashIcon = { fg = t.syn.fun },
      DashLabel = { fg = t.ui.fg },
      DashKey = { fg = t.syn.keyword, bold = true },
      DashQuote = { fg = t.syn.constant, italic = true },
      DashDim = { fg = t.ui.special },
    }
    -- 模式色块：色块本体，以及左侧同色的圆角。
    local modes = {
      Normal = t.syn.fun,
      Insert = t.syn.string,
      Visual = t.syn.keyword,
      Replace = t.diag.error,
      Command = t.syn.constant,
      Terminal = t.syn.special1,
    }
    for name, color in pairs(modes) do
      hl["BarMode" .. name] = { fg = t.ui.bg, bg = color, bold = true }
      hl["BarMode" .. name .. "Cap"] = { fg = color, bg = "none" }
      hl["BarMode" .. name .. "Sep"] = { fg = color, bg = fill }
    end
    return hl
  end,
})
vim.cmd.colorscheme("kanagawa")

--------------------------------------------------------------------------------
-- 消息与命令行：Neovim 0.12 的 ui2 + tiny-cmdline。按 : 时命令行在屏幕中间浮出，平时不占行；
-- :echo 之类的普通消息显示在右下角的小窗里，几秒后消失。g< 查看完整消息。
-- ui2 还是实验性功能：万一命令行显示异常，把下面的 use_ui2 改成 false，
-- 就回到传统的一行命令行（底部会多占一行）。
--------------------------------------------------------------------------------
local use_ui2 = true

if use_ui2 then
  require("vim._core.ui2").enable({
    msg = { target = "msg", msg = { timeout = 3000 } },
  })
  -- 把命令行从左下角挪到屏幕中上方的圆角浮窗里；搜索（/ ?）也一样。补全菜单跟着它走。
  local cmdline = require("tiny-cmdline")
  cmdline.setup({
    width = { value = "50%", min = 50, max = 90 },
    position = { x = "50%", y = "30%" },
    native_types = { "-" }, -- 确认对话框（保存？是/否/取消）留在底部，和它的问题文字待在一起。
    title = { enabled = true, pos = "left" },
    on_reposition = cmdline.adapters.blink,
  })
else
  vim.opt.cmdheight = 1
  require("tiny-cmdline")._initialized = true -- 它依赖 ui2；标记成已初始化，启动后就不会自己再启用。
end

-- 通知卡片（手写，替换 vim.notify）：插件和 LSP 的通知显示成右上角的圆角小卡片，
-- 排在胶囊下方，多条往下叠，几秒后自己消失。语言服务的加载进度是一张原地更新的卡片。
-- :Notifications（<leader>n）翻看历史。
local levels = vim.log.levels
local notify_style = {
  [levels.ERROR] = { icon = "\u{f057}", name = "Error", timeout = 6000 },
  [levels.WARN] = { icon = "\u{f071}", name = "Warn", timeout = 4000 },
  [levels.INFO] = { icon = "\u{f05a}", name = "Info", timeout = 3000 },
  [levels.DEBUG] = { icon = "\u{f188}", name = "Info", timeout = 3000 },
  [levels.TRACE] = { icon = "\u{f040}", name = "Info", timeout = 3000 },
  progress = { icon = "\u{f013}", name = "Info", timeout = 10000 },
}
local notify_ns = api.nvim_create_namespace("config.notify")
local cards, history = {}, {}
local CARD_MAX_WIDTH, CARD_MAX_COUNT = 56, 5

-- 从胶囊下面一行开始，自上而下排列。
local function layout_cards()
  local row = 1
  for _, card in ipairs(cards) do
    api.nvim_win_set_config(card.win, { relative = "editor", anchor = "NE", row = row, col = vim.o.columns - 1 })
    row = row + card.height + 2
  end
end

local function close_card(card)
  for i, other in ipairs(cards) do
    if other == card then
      table.remove(cards, i)
      break
    end
  end
  card.closed = true
  if card.timer then
    card.timer:stop()
    card.timer:close()
    card.timer = nil
  end
  if card.win and api.nvim_win_is_valid(card.win) then api.nvim_win_close(card.win, true) end
  if api.nvim_buf_is_valid(card.buf) then api.nvim_buf_delete(card.buf, { force = true }) end
  layout_cards()
end

-- 写入（或更新）一张卡片的内容，并重新计时。
local function fill_card(card, msg, style)
  local lines = vim.split(vim.trim(tostring(msg)), "\n", { plain = true })
  local width = 0
  for i, line in ipairs(lines) do
    lines[i] = (i == 1 and " " .. style.icon .. "  " or "    ") .. line:gsub("\t", "  ") .. " "
    width = math.max(width, vim.fn.strdisplaywidth(lines[i]))
  end
  width = math.min(width, CARD_MAX_WIDTH)
  local height = 0
  for _, line in ipairs(lines) do
    height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / width))
  end
  card.height = math.min(height, 12)

  api.nvim_buf_set_lines(card.buf, 0, -1, false, lines)
  api.nvim_buf_set_extmark(card.buf, notify_ns, 0, 0, { end_col = #style.icon + 1, hl_group = "Notify" .. style.name .. "Icon" })
  if card.win and api.nvim_win_is_valid(card.win) then
    api.nvim_win_set_config(card.win, { width = width, height = card.height })
  else
    card.win = api.nvim_open_win(card.buf, false, {
      relative = "editor",
      anchor = "NE",
      row = 1,
      col = vim.o.columns - 1,
      width = width,
      height = card.height,
      style = "minimal",
      border = "rounded",
      focusable = false,
      noautocmd = true,
      zindex = 60,
    })
    vim.wo[card.win].wrap = true
  end
  vim.wo[card.win].winhighlight = ("NormalFloat:NotifyText,FloatBorder:Notify%sBorder"):format(style.name)

  card.timer = card.timer or vim.uv.new_timer()
  card.timer:stop()
  card.timer:start(style.timeout, 0, vim.schedule_wrap(function()
    if not card.closed then close_card(card) end
  end))
  layout_cards()
end

local function new_card()
  local card = { buf = api.nvim_create_buf(false, true) }
  cards[#cards + 1] = card
  while #cards > CARD_MAX_COUNT do close_card(cards[1]) end
  return card
end

---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, level)
  if vim.in_fast_event() then
    return vim.schedule(function() vim.notify(msg, level) end)
  end
  level = level or levels.INFO
  local style = notify_style[level] or notify_style[levels.INFO]
  history[#history + 1] = { os.date("%H:%M:%S"), style, tostring(msg) }
  if #history > 200 then table.remove(history, 1) end

  local card = new_card()
  -- 有些时刻不允许开窗口（比如正在执行补全）；那就退回成一条普通消息。
  if not pcall(fill_card, card, msg, style) then
    close_card(card)
    api.nvim_echo({ { style.icon .. "  ", "Notify" .. style.name .. "Icon" }, { tostring(msg) } }, true, {})
  end
end

api.nvim_create_user_command("Notifications", function()
  if #history == 0 then return api.nvim_echo({ { "没有通知", "Comment" } }, false, {}) end
  local chunks = {}
  for _, item in ipairs(history) do
    chunks[#chunks + 1] = { item[1] .. "  ", "Comment" }
    chunks[#chunks + 1] = { item[2].icon .. "  ", "Notify" .. item[2].name .. "Icon" }
    chunks[#chunks + 1] = { item[3] .. "\n" }
  end
  api.nvim_echo(chunks, false, {})
end, { desc = "Notification history (通知历史)" })

-- 语言服务的进度（索引、加载项目等）：同一件事只占一张卡片，原地更新，结束后消失。
local progress = {}
api.nvim_create_autocmd("LspProgress", {
  group = group,
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    local value = event.data.params.value
    if not client or type(value) ~= "table" then return end
    local key = event.data.client_id .. ":" .. tostring(event.data.params.token)
    local card = progress[key]
    if card and card.closed then card = nil end
    if value.kind == "end" then
      progress[key] = nil
      if card then close_card(card) end
      return
    end
    if not card then
      card = new_card()
      card.title = value.title
      progress[key] = card
    end
    local text = client.name .. "  " .. (value.title or card.title or "")
    if value.message then text = text .. "  " .. value.message end
    if value.percentage then text = text .. ("  %d%%"):format(value.percentage) end
    if not pcall(fill_card, card, text, notify_style.progress) then
      progress[key] = nil
      close_card(card)
    end
  end,
})
api.nvim_create_autocmd("VimResized", { group = group, callback = layout_cards })

-- vim.ui.input（重命名等）：光标旁的小输入框。Enter 确认，Esc 取消。
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
  opts = opts or {}
  local default = opts.default or ""
  local title = vim.trim((opts.prompt or "Input"):gsub("[:：]%s*$", ""))
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  api.nvim_buf_set_lines(buf, 0, -1, false, { default })
  local win = api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = math.max(32, vim.fn.strdisplaywidth(default) + 12, vim.fn.strdisplaywidth(title) + 4),
    height = 1,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
  })
  vim.cmd("startinsert!")

  local done = false
  local function finish(value)
    if done then return end
    done = true
    vim.cmd.stopinsert()
    if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
    on_confirm(value)
  end
  local function confirm() finish(api.nvim_buf_get_lines(buf, 0, 1, false)[1]) end
  local function cancel() finish(nil) end
  vim.keymap.set({ "i", "n" }, "<CR>", confirm, { buffer = buf })
  vim.keymap.set("n", "<Esc>", cancel, { buffer = buf })
  vim.keymap.set("n", "q", cancel, { buffer = buf })
  vim.keymap.set("i", "<C-c>", cancel, { buffer = buf })
  api.nvim_create_autocmd("BufLeave", { buffer = buf, once = true, callback = cancel })
end

-- vim.ui.select（代码操作等）：第一次用到时交给 FZF-Lua。
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(...)
  require("config.tools").fzf().register_ui_select()
  return vim.ui.select(...)
end

--------------------------------------------------------------------------------
-- 行号列（手写的 'statuscolumn'）：折叠标记 + 行号 + Git 细条。
-- 只有当前窗口显示相对行号和当前行高亮，其他窗口显示普通行号。
--------------------------------------------------------------------------------
function _G.StatusColumn()
  local win = api.nvim_get_current_win() -- 求值时「当前窗口」就是正在画的那个窗口。
  local buf = api.nvim_win_get_buf(win)
  if not is_file(buf) then return "" end

  local width = math.max(3, #tostring(api.nvim_buf_line_count(buf)))
  -- 换行显示的续行和虚拟行：留空。
  if vim.v.virtnum ~= 0 then return (" "):rep(width + 3) .. "%*" end

  local lnum = vim.v.lnum
  local fold = vim.fn.foldclosed(lnum) == lnum and "\u{f105}" or " "
  local num = (vim.wo[win].relativenumber and vim.v.relnum ~= 0) and vim.v.relnum or lnum
  local git = " "
  local marks = api.nvim_buf_get_extmarks(buf, -1, { lnum - 1, 0 }, { lnum - 1, -1 }, { type = "sign", details = true })
  for _, mark in ipairs(marks) do
    local sign_hl = mark[4].sign_hl_group
    if sign_hl and sign_hl:find("^GitSigns") then
      git = "%#" .. sign_hl .. "#▎"
      break
    end
  end
  -- 结尾的 %* 不能省：结果如果只有空格和数字，会被当成数字处理，前后的空格就丢了。
  return fold .. ("%" .. width .. "d"):format(num) .. " " .. git .. "%*"
end
vim.o.statuscolumn = "%{%v:lua.StatusColumn()%}"

local editor_focused = true
local function update_window_focus()
  local current = api.nvim_get_current_win()
  for _, win in ipairs(api.nvim_list_wins()) do
    -- [0]：只改「这个窗口显示这个缓冲区时」的值，换了缓冲区不会带过去。
    local wo = vim.wo[win][0]
    if is_file(api.nvim_win_get_buf(win)) then
      local active = editor_focused and win == current
      wo.number = true
      wo.relativenumber = active
      wo.cursorline = active
    elseif api.nvim_win_get_config(win).relative == "" then
      wo.relativenumber = false
    end
  end
end
api.nvim_create_autocmd({ "WinEnter", "BufEnter", "FileType", "VimEnter" }, { group = group, callback = update_window_focus })
api.nvim_create_autocmd({ "FocusGained", "FocusLost" }, {
  group = group,
  callback = function(event)
    editor_focused = event.event == "FocusGained"
    update_window_focus()
  end,
})

--------------------------------------------------------------------------------
-- 浮动状态胶囊（incline）：每个窗口右上角一个。
--   所有窗口：图标、文件名（重名时带上级目录）、修改圆点。
--   当前窗口：左端模式色块；右边依次是 正在发生的事（宏、选区、搜索）、诊断、Git 改动、分支、语言服务。
-- 只显示有内容的段，没有就不占位置。
--------------------------------------------------------------------------------
local devicons = require("nvim-web-devicons")
devicons.setup({})

-- 图标一律写成码位（Nerd Font），避免编辑器或终端把私有区字符弄丢。
local CAP_LEFT, CAP_RIGHT = "\u{e0b6}", "\u{e0b4}"
local SEPARATOR = "   " -- 段间分隔符（空格 + 细竖线 + 空格）占的宽度。

local mode_names = {
  n = { "NOR", "Normal" },
  i = { "INS", "Insert" },
  v = { "VIS", "Visual" },
  V = { "V-L", "Visual" },
  ["\22"] = { "V-B", "Visual" },
  s = { "SEL", "Visual" },
  S = { "SEL", "Visual" },
  R = { "REP", "Replace" },
  c = { "CMD", "Command" },
  t = { "TER", "Terminal" },
}

-- 图标的颜色各不相同：按颜色现建高亮组（底色用胶囊色），换配色时清空重建。
local icon_groups = {}
api.nvim_create_autocmd("ColorScheme", { group = group, callback = function() icon_groups = {} end })
local function icon_group(color)
  local name = "BarIcon" .. color:sub(2)
  if not icon_groups[name] then
    local fill = api.nvim_get_hl(0, { name = "BarText", link = false }).bg
    api.nvim_set_hl(0, name, { fg = color, bg = fill })
    icon_groups[name] = true
  end
  return name
end

-- 文件名；有别的已打开文件同名时，前面带上级目录以示区分。
local function file_label(buf)
  local path = api.nvim_buf_get_name(buf)
  if path == "" then return nil, "[No Name]" end
  local tail = vim.fs.basename(path)
  for _, other in ipairs(api.nvim_list_bufs()) do
    if other ~= buf and vim.bo[other].buflisted and vim.fs.basename(api.nvim_buf_get_name(other)) == tail then
      return vim.fs.basename(vim.fs.dirname(path)) .. "/", tail
    end
  end
  return nil, tail
end

-- 只在正在发生时出现：录制中的宏、可视选区大小、搜索位置。
local function activity(mode)
  local recording = vim.fn.reg_recording()
  if recording ~= "" then return "\u{f111} @" .. recording end
  if mode == "v" or mode == "V" or mode == "\22" then
    local lines = math.abs(vim.fn.line("v") - vim.fn.line(".")) + 1
    if mode == "\22" then
      return lines .. "×" .. (math.abs(vim.fn.virtcol("v") - vim.fn.virtcol(".")) + 1)
    elseif mode == "v" and lines == 1 then
      return (math.abs(vim.fn.col("v") - vim.fn.col(".")) + 1) .. " chars"
    end
    return lines .. " lines"
  end
  if vim.v.hlsearch == 1 then
    local ok, count = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 50 })
    if ok and count.total and count.total > 0 then
      return "\u{f002} " .. count.current .. "/" .. count.total
    end
  end
end

-- 胶囊可以占用的宽度：窗口宽度减去窗口第一行文字的宽度，这样不会盖住代码。
-- 只量窗口宽度那么长的一段：压缩过的 JSON 之类一行几 MB，每次光标移动都整行量一遍会卡。
local function free_width(win, buf)
  local top = vim.fn.line("w0", win)
  local info = vim.fn.getwininfo(win)[1]
  local text = (api.nvim_buf_get_lines(buf, top - 1, top, false)[1] or ""):sub(1, info.width * 4)
  return info.width - info.textoff - vim.fn.strdisplaywidth(text) - 2
end

local function render(props)
  local buf, win, focused = props.buf, props.win, props.focused
  local dir, name, icon, color
  if vim.bo[buf].filetype == "oil" then
    -- 文件管理窗口：显示所在目录。
    name = vim.fn.fnamemodify(require("oil").get_current_dir(buf) or "", ":~")
    icon, color = "\u{f07b}", ("#%06x"):format(api.nvim_get_hl(0, { name = "Directory", link = false }).fg or 0x7e9cd8)
  elseif vim.bo[buf].buftype ~= "" then
    return nil
  else
    dir, name = file_label(buf)
    icon, color = devicons.get_icon_color(name, nil, { default = true })
  end
  local function add(list, text, hl) list[#list + 1] = { text, group = hl } end
  local modified = vim.bo[buf].modified

  -- 最右边永远是图标和文件名：胶囊靠右对齐，所以文件名的位置不会随其他内容变化而跳动。
  local file = {}
  add(file, icon .. " ", focused and icon_group(color) or "BarDim")
  if dir then add(file, dir, "BarDim") end
  add(file, name, not focused and "BarTextNC" or modified and "BarTextModified" or "BarText")
  if modified then add(file, " ●", "BarModified") end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then add(file, " \u{f023}", "BarDim") end

  -- 最左边：当前窗口是模式色块，其他窗口只有一个圆角。
  local head = {}
  local mode = api.nvim_get_mode().mode
  if focused then
    -- 焦点在搜索之类的浮窗里时，这个窗口本身并不在终端模式。
    if mode:sub(1, 1) == "t" and vim.bo[buf].buftype ~= "terminal" then mode = "n" end
    local m = mode_names[mode] or mode_names[mode:sub(1, 1)] or mode_names.n
    add(head, CAP_LEFT, "BarMode" .. m[2] .. "Cap")
    add(head, " " .. m[1] .. " ", "BarMode" .. m[2])
    add(head, " ", "BarText")
  else
    add(head, CAP_LEFT, "BarCap")
  end

  -- 中间的各段，按重要程度排列；窗口第一行放不下时从后往前省略。段与段之间用细竖线隔开。
  local extras = {}
  if focused then
    local act = activity(mode)
    if act then extras[#extras + 1] = { { act, group = "BarActivity" } } end

    local count, severity = vim.diagnostic.count(buf), vim.diagnostic.severity
    local diagnostics = {
      { count[severity.ERROR], "\u{f057}", "BarError" },
      { count[severity.WARN], "\u{f071}", "BarWarn" },
      { (count[severity.HINT] or 0) + (count[severity.INFO] or 0), "\u{f0eb}", "BarHint" },
    }
    local seg = {}
    for _, d in ipairs(diagnostics) do
      if d[1] and d[1] > 0 then add(seg, (#seg > 0 and " " or "") .. d[2] .. " " .. d[1], d[3]) end
    end
    if #seg > 0 then extras[#extras + 1] = seg end

    local git = vim.b[buf].gitsigns_status_dict
    if git then
      local changes = {
        { git.added, "\u{eadc}", "BarAdd" },
        { git.changed, "\u{eade}", "BarChange" },
        { git.removed, "\u{eadf}", "BarDelete" },
      }
      seg = {}
      for _, c in ipairs(changes) do
        if c[1] and c[1] > 0 then add(seg, (#seg > 0 and " " or "") .. c[2] .. " " .. c[1], c[3]) end
      end
      if #seg > 0 then extras[#extras + 1] = seg end
      if git.head and git.head ~= "" then
        extras[#extras + 1] = { { "\u{e0a0} " .. git.head, group = "BarBranch" } }
      end
    end

    local servers = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      servers[#servers + 1] = client.name
    end
    if #servers > 0 then
      extras[#extras + 1] = { { "\u{f013} " .. table.concat(servers, " "), group = "BarLsp" } }
    end
  end

  local function measure(list)
    local total = 0
    for _, seg in ipairs(list) do total = total + vim.fn.strdisplaywidth(seg[1]) end
    return total
  end
  local free = free_width(win, buf)
  local used = measure(head) + measure(file) + 2 -- 结尾的空格和右圆角。
  -- 连最基本的部分都放不下、光标又正好在这一行：整个让开，不挡正在编辑的文字。
  if used > free and focused and vim.fn.winline() == 1 then return nil end

  local out = head
  for _, seg in ipairs(extras) do
    local w = measure(seg) + #SEPARATOR
    if used + w > free then break end
    vim.list_extend(out, seg)
    add(out, " │ ", "BarSep")
    used = used + w
  end
  vim.list_extend(out, file)
  add(out, " ", "BarText")
  add(out, CAP_RIGHT, "BarCap")
  return out
end

local incline = require("incline")
incline.setup({
  render = render,
  window = {
    padding = 0,
    margin = { horizontal = 1, vertical = 0 },
    placement = { horizontal = "right", vertical = "top" },
    zindex = 30, -- 低于搜索、补全等浮窗，被它们盖住而不是盖住它们。
  },
  hide = { cursorline = false, focused_win = false, only_win = false },
})
-- incline 自己只在光标移动等事件时重画；这些状态变化也要立刻反映。
api.nvim_create_autocmd(
  { "ModeChanged", "RecordingEnter", "RecordingLeave", "DiagnosticChanged", "LspAttach", "LspDetach", "BufModifiedSet", "CmdlineLeave" },
  { group = group, callback = function() vim.schedule(incline.refresh) end }
)
api.nvim_create_autocmd("User", { group = group, pattern = "GitSignsUpdate", callback = function() vim.schedule(incline.refresh) end })

--------------------------------------------------------------------------------
-- 缩进线：静态细线，当前作用域亮一档。
--------------------------------------------------------------------------------
require("config.plugins").later(function()
  require("ibl").setup({
    indent = { char = "▏" },
    scope = { char = "▎", show_start = false, show_end = false },
    exclude = { filetypes = { "dashboard", "oil", "help", "grug-far" } },
  })
end)

--------------------------------------------------------------------------------
-- 平滑滚动：翻页短促减速，不拖沓。
--------------------------------------------------------------------------------
require("neoscroll").setup({
  mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
  duration_multiplier = 0.5,
  easing = "quadratic",
  hide_cursor = false,
})

--------------------------------------------------------------------------------
-- 按键提示：前缀键停顿 200ms 后在右下角列出可用按键。
--------------------------------------------------------------------------------
require("which-key").setup({
  preset = "helix",
  delay = 200,
  spec = {
    { "<leader>f", group = "Find (查找)" },
    { "<leader>s", group = "Window (窗口)" },
    { "<leader>b", group = "Buffer (缓冲区)" },
    { "<leader>t", group = "Tab (标签页)" },
    { "<leader>g", group = "Git" },
    { "<leader>l", group = "LSP (语言服务)" },
    { "<leader>a", group = "Argument (参数)" },
  },
  win = { title = false, padding = { 1, 2 } },
  -- 描述为 English (中文)；先按分组、再按字母排序，同类按键聚在一起。
  sort = { "group", "alphanum" },
  icons = { mappings = false, breadcrumb = "»", separator = "→", group = "", rules = false },
  show_help = false,
  show_keys = false,
})
