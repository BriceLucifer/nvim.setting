-- 快捷键和自定义命令。LSP 的按键在 code.lua，只在挂上语言服务的文件里生效。
-- 空格为 leader：f 查找、s 窗口、b 缓冲区、t 标签页、g Git、l LSP、m 消息、e 文件管理、w 保存、q 退出。
local map = vim.keymap.set
local tools = require("config.tools")
local pick = tools.pick

-- 清除搜索高亮
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true, desc = "Clear search highlight (清除搜索高亮)" })

-- 保存和终端
map("n", "<leader>w", "<cmd>write<CR>", { silent = true, desc = "Save file (保存文件)" })
map("n", "<leader>q", "<cmd>quit<CR>", { silent = true, desc = "Quit (退出)" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode (退出终端模式)" })

-- 文件管理（oil）：目录是一个可编辑的缓冲区，改完 :w 生效；- 回上级，Enter 进入。
map("n", "-", "<cmd>Oil<CR>", { silent = true, desc = "Open parent directory (打开所在目录)" })
map("n", "<leader>e", function() require("oil").toggle_float() end, { desc = "Explorer, floating (浮窗文件管理)" })
map("n", "<leader>E", function() require("oil").toggle_float(vim.uv.cwd()) end, { desc = "Explorer at cwd (工作目录)" })

-- 分屏
map("n", "<leader>sv", "<cmd>vsplit<CR>", { silent = true, desc = "Split right (左右分屏)" })
map("n", "<leader>sh", "<cmd>split<CR>", { silent = true, desc = "Split below (上下分屏)" })
map("n", "<leader>sc", "<cmd>close<CR>", { silent = true, desc = "Close window (关闭窗口)" })
map("n", "<leader>so", "<cmd>only<CR>", { silent = true, desc = "Only this window (仅保留当前窗口)" })
map("n", "<leader>se", "<C-w>=", { silent = true, desc = "Equalize windows (均分窗口)" })
-- 临时放大当前窗口；再次按下恢复原来各窗口的大小。
map("n", "<leader>sz", function()
  if vim.t.zoom_restore then
    vim.cmd(vim.t.zoom_restore)
    vim.t.zoom_restore = nil
  elseif vim.fn.winnr("$") > 1 then
    vim.t.zoom_restore = vim.fn.winrestcmd()
    vim.cmd("wincmd | | wincmd _")
  end
end, { silent = true, desc = "Zoom / restore (放大窗口 / 恢复布局)" })

-- Ctrl 切换 Neovim 窗口，Alt 留给终端。
map("n", "<C-h>", "<C-w>h", { silent = true, desc = "Window left (左侧窗口)" })
map("n", "<C-j>", "<C-w>j", { silent = true, desc = "Window down (下方窗口)" })
map("n", "<C-k>", "<C-w>k", { silent = true, desc = "Window up (上方窗口)" })
map("n", "<C-l>", "<C-w>l", { silent = true, desc = "Window right (右侧窗口)" })

-- 调整窗口大小：分隔线朝按键方向移动，与光标在哪个窗口无关。
-- 不用 Ctrl+方向键：macOS 用它切换桌面 / 全屏 App，nvim 收不到。
local function move_split(dir)
  return function()
    local horizontal = dir == "h" or dir == "l"
    -- 当前窗口在右侧 / 下方还有邻居时，它是靠左 / 靠上的那个。
    local has_next = vim.fn.winnr(horizontal and "l" or "j") ~= vim.fn.winnr()
    local grow = (dir == "l" or dir == "j") == has_next
    local step = horizontal and 5 or 3
    vim.cmd((horizontal and "vertical " or "") .. "resize " .. (grow and "+" or "-") .. step)
  end
end
map("n", "<leader>sH", move_split("h"), { desc = "Move split left (分隔线左移)" })
map("n", "<leader>sL", move_split("l"), { desc = "Move split right (分隔线右移)" })
map("n", "<leader>sK", move_split("k"), { desc = "Move split up (分隔线上移)" })
map("n", "<leader>sJ", move_split("j"), { desc = "Move split down (分隔线下移)" })

-- 缓冲区。没有标签栏，切换文件用 <leader><leader> 或 ]b / [b。
map("n", "<leader><leader>", pick("buffers"), { desc = "Switch buffer (切换已打开的文件)" })
map("n", "[b", "<cmd>bprevious<CR>", { silent = true, desc = "Previous buffer (上一个缓冲区)" })
map("n", "]b", "<cmd>bnext<CR>", { silent = true, desc = "Next buffer (下一个缓冲区)" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { silent = true, desc = "Previous buffer (上一个缓冲区)" })

-- 关闭文件但保留分屏：显示它的窗口先换成别的文件。未保存时询问保存、放弃或取消。
local function bufdelete(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    local choice = vim.fn.confirm(("保存对 %s 的修改？"):format(name ~= "" and name or "[No Name]"), "&Yes\n&No\n&Cancel")
    if choice == 1 then
      vim.api.nvim_buf_call(buf, vim.cmd.write)
    elseif choice ~= 2 then
      return
    end
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      local alt = vim.fn.bufnr("#")
      if alt > 0 and alt ~= buf and vim.bo[alt].buflisted then
        vim.cmd.buffer(alt)
        return
      end
      for _, other in ipairs(vim.api.nvim_list_bufs()) do
        if other ~= buf and vim.bo[other].buflisted then
          vim.cmd.buffer(other)
          return
        end
      end
      vim.cmd.enew()
    end)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end
map("n", "<leader>bd", bufdelete, { silent = true, desc = "Delete buffer, keep split (关闭缓冲区)" })
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      bufdelete(buf)
    end
  end
end, { silent = true, desc = "Delete other buffers (关闭其他缓冲区)" })

-- 标签页 / 工作区
map("n", "<leader>tn", "<cmd>tabnew<CR>", { silent = true, desc = "New tab (新建工作区)" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { silent = true, desc = "Close tab (关闭工作区)" })
map("n", "]t", "<cmd>tabnext<CR>", { silent = true, desc = "Next tab (下一个标签页)" })
map("n", "[t", "<cmd>tabprevious<CR>", { silent = true, desc = "Previous tab (上一个标签页)" })
map("n", "<leader>to", "<cmd>tabonly<CR>", { silent = true, desc = "Only this tab (关闭其他工作区)" })

-- 搜索；FZF-Lua 在第一次按下时才加载（见 tools.lua）。
map("n", "<leader>ff", pick("files"), { desc = "Find files (查找文件)" })
map("n", "<leader>fg", pick("live_grep"), { desc = "Live grep (全文搜索)" })
map("n", "<leader>fb", pick("buffers"), { desc = "Buffers (切换缓冲区)" })
map("n", "<leader>fr", pick("oldfiles"), { desc = "Recent files (最近文件)" })
map("n", "<leader>fh", pick("help_tags"), { desc = "Help tags (查找帮助文档)" })
map("n", "<leader>fk", pick("keymaps"), { desc = "Keymaps (查找快捷键)" })
map("n", "<leader>fc", pick("commands"), { desc = "Commands (查找命令)" })
map("n", "<leader>fw", pick("grep_cword"), { desc = "Grep word under cursor (搜索光标下的单词)" })
map("n", "<leader>fl", pick("resume"), { desc = "Resume last search (恢复上次搜索)" })
map("n", "<leader>fz", pick("zoxide"), { desc = "Zoxide dirs (查找常用目录)" })
-- 搜索替换：大写 R；小写 <leader>fr 是最近文件。
map("n", "<leader>fR", function() require("grug-far").open({}) end, { desc = "Search & replace (搜索替换)" })

-- 消息在右下角浮出几秒，通知是右上角的卡片；这两个键翻看各自的历史。
map("n", "<leader>m", "<cmd>messages<CR>", { silent = true, desc = "Message history (消息历史)" })
map("n", "<leader>n", "<cmd>Notifications<CR>", { silent = true, desc = "Notification history (通知历史)" })

-- Git 修改块；diff 模式保留原生跳转。gitsigns 在启动后才加载，所以这里都是用到时再取。
local function gs(method, ...)
  local args = { ... }
  return function() require("gitsigns")[method](unpack(args)) end
end
local function hunk(key, direction)
  return function()
    if vim.wo.diff then
      vim.cmd.normal({ key, bang = true })
    else
      require("gitsigns").nav_hunk(direction)
    end
  end
end
map("n", "]c", hunk("]c", "next"), { desc = "Git: next hunk (下一个修改块)" })
map("n", "[c", hunk("[c", "prev"), { desc = "Git: previous hunk (上一个修改块)" })
map("n", "<leader>gp", gs("preview_hunk"), { desc = "Preview hunk (预览修改块)" })
map("n", "<leader>gs", gs("stage_hunk"), { desc = "Stage hunk (暂存修改块)" })
map("n", "<leader>gr", gs("reset_hunk"), { desc = "Reset hunk (还原修改块)" })
map("n", "<leader>gS", gs("stage_buffer"), { desc = "Stage buffer (暂存整个文件)" })
map("n", "<leader>gB", gs("blame"), { desc = "Blame file (查看整个文件归属)" })
map("n", "<leader>gb", gs("blame_line"), { desc = "Blame line (查看行归属)" })
map("n", "<leader>gd", gs("diffthis"), { desc = "Diff this (查看文件差异)" })

-- Flash 跳转。选中后的 S 留给 surround，所以按语法结构选择在可视模式下用 R。
local flash = require("flash")
map({ "n", "x", "o" }, "s", flash.jump, { desc = "Flash jump (字符跳转)" })
map({ "n", "o" }, "S", flash.treesitter, { desc = "Flash treesitter (语法结构选择)" })
map("x", "R", flash.treesitter, { desc = "Flash treesitter (语法结构选择)" })

-- 搜索结果居中并展开折叠。
map("n", "n", "nzzzv", { desc = "Next match, centered (下一个搜索结果)" })
map("n", "N", "Nzzzv", { desc = "Previous match, centered (上一个搜索结果)" })

-- 缩进后保留选区
map("x", "<", "<gv", { desc = "Indent left (减少缩进)" })
map("x", ">", ">gv", { desc = "Indent right (增加缩进)" })

-- 覆盖选区，保留原复制内容。
map("x", "<leader>p", [["_dP]], { desc = "Paste, keep register (粘贴并保留寄存器)" })

-- 上下移动选区，并重新缩进。到了文件顶 / 底就不动，不报 E16。
map("x", "J", ":<C-u>silent! '<,'>move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down (下移选区)" })
map("x", "K", ":<C-u>silent! '<,'>move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up (上移选区)" })

-- 文本对象：按语法树选择，配合 d / c / y / v 使用，例如 daf 删除整个函数、cia 修改参数。
-- a = 包含边界（around），i = 只含内部（inner）。
local ts_select = require("nvim-treesitter-textobjects.select")
local objects = {
  { "f", "function", "Function (函数)" },
  { "c", "class", "Class / struct (类 / 结构体)" },
  { "a", "parameter", "Argument (参数)" },
  { "l", "loop", "Loop (循环)" },
  { "i", "conditional", "Conditional (条件语句)" },
}
for _, obj in ipairs(objects) do
  local key, name, desc = obj[1], obj[2], obj[3]
  map({ "x", "o" }, "a" .. key, function()
    ts_select.select_textobject("@" .. name .. ".outer", "textobjects")
  end, { desc = "Around " .. desc })
  map({ "x", "o" }, "i" .. key, function()
    ts_select.select_textobject("@" .. name .. ".inner", "textobjects")
  end, { desc = "Inside " .. desc })
end

-- 在函数和类之间跳转；]c / [c 已用于 Git 修改块，所以类用 k。
local ts_move = require("nvim-treesitter-textobjects.move")
local function jump(lhs, fn, query, desc)
  map({ "n", "x", "o" }, lhs, function()
    ts_move[fn](query, "textobjects")
  end, { desc = desc })
end
jump("]f", "goto_next_start", "@function.outer", "Next function start (下一个函数开头)")
jump("[f", "goto_previous_start", "@function.outer", "Previous function start (上一个函数开头)")
jump("]F", "goto_next_end", "@function.outer", "Next function end (下一个函数结尾)")
jump("[F", "goto_previous_end", "@function.outer", "Previous function end (上一个函数结尾)")
jump("]k", "goto_next_start", "@class.outer", "Next class start (下一个类开头)")
jump("[k", "goto_previous_start", "@class.outer", "Previous class start (上一个类开头)")

-- 与相邻参数交换位置，光标跟着走。
local ts_swap = require("nvim-treesitter-textobjects.swap")
map("n", "<leader>an", function()
  ts_swap.swap_next("@parameter.inner")
end, { desc = "Swap with next argument (与下一个参数交换)" })
map("n", "<leader>ap", function()
  ts_swap.swap_previous("@parameter.inner")
end, { desc = "Swap with previous argument (与上一个参数交换)" })

--------------------------------------------------------------------------------
-- 自定义命令
--------------------------------------------------------------------------------

-- :Z 关键词：通过 zoxide 切换目录。
vim.api.nvim_create_user_command("Z", function(opts)
  if vim.fn.executable("zoxide") == 0 then
    vim.notify("未找到 zoxide", vim.log.levels.ERROR)
    return
  end
  local result = vim.fn.system(vim.list_extend({ "zoxide", "query" }, opts.fargs))
  local dir = vim.trim(result)
  if vim.v.shell_error ~= 0 or dir == "" then
    vim.notify("zoxide：未找到目录", vim.log.levels.ERROR)
    return
  end
  vim.cmd.cd(vim.fn.fnameescape(dir))
  vim.notify("目录：" .. vim.fn.getcwd())
end, { nargs = "+", desc = "cd via zoxide (通过 zoxide 切换目录)" })

-- 手动安装常用解析器，避免启动时等待。
vim.api.nvim_create_user_command("TSInstallDefaults", function()
  require("nvim-treesitter").install(require("config.code").languages, { summary = true })
end, { desc = "Install default parsers (安装常用语法解析器)" })
