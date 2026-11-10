-- 启动页（手写，不依赖插件）：不带文件打开 nvim 时出现。
-- 画面是一个倾斜的旋涡星系：金色的核心、两条蓝色的旋臂、旋臂上粉色的恒星诞生区，
-- 周围是稀疏的星空。菜单浮在左上方。
--
-- 画面用盲文点阵字符画成（每格 2×4 个点，亮度越高点越密）。第一帧按窗口大小现算一次后缓存，
-- 打开时直接读，不拖慢启动。之后星系慢慢转动：每一帧也只算一次，算过的存进缓存文件，
-- 转完第一圈以后就只是每秒换几次画面。离开启动页或终端失去焦点时停下。窗口太小时只显示菜单。
local api = vim.api
local bit = require("bit")
local floor, sqrt, abs, max, min = math.floor, math.sqrt, math.abs, math.max, math.min
local width = vim.fn.strdisplaywidth

--------------------------------------------------------------------------------
-- 菜单：图标（Nerd Font 码位）、名字、按键、动作。按键直接执行；也可以 j / k 移动后按 Enter。
--------------------------------------------------------------------------------
local function pick(picker, opts)
  return function() require("config.tools").pick(picker, opts)() end
end

local items = {
  { "\u{f15b}", "New buffer", "e", function() vim.cmd.enew() end },
  { "\u{f002}", "Find file", "f", pick("files") },
  { "\u{f1da}", "Recently opened files", "r", pick("oldfiles") },
  { "\u{f031}", "Word finder", "g", pick("live_grep") },
  { "\u{f07b}", "Explorer", "-", function() require("oil").open(vim.uv.cwd()) end },
  { "\u{f013}", "Config", "c", pick("files", { cwd = vim.fn.stdpath("config") }) },
  { "\u{f021}", "Update plugins", "u", function() vim.pack.update() end },
  { "\u{f011}", "Quit", "q", function() vim.cmd.qa() end },
}

local quote = "A spiral galaxy, turning slowly."
local MENU_WIDTH = 40 -- 菜单一行的宽度（格）
local MIN_WIDTH, MIN_HEIGHT = 96, 26 -- 窗口比这小就不画星系，只显示菜单
local ANIMATE = true -- 星系是否转动；改成 false 就是一幅静止的画，没有定时器
local FPS = 6 -- 每秒几帧
local FRAMES = 120 -- 转半圈（两条旋臂对称，转半圈画面正好重复）分成多少帧

--------------------------------------------------------------------------------
-- 颜色。画面里每格用一个字母表示颜色，每组字母是一条渐变（由下面几个端点颜色插值出来）：
--   a–j 旋臂（靛蓝 → 亮蓝 → 冰白）      k–p 外缘（深紫 → 淡紫）     A–H 核心（棕橙 → 金 → 白）
--   x–z 粉色的恒星诞生区                u v 背景里的星云薄雾        s S t 星星（蓝白、纯白、暖黄）
-- 这是一幅插画，颜色不跟配色主题走，只分深色和浅色两套：浅色背景上"越亮"要画得越深。
--------------------------------------------------------------------------------
local palettes = {
  dark = {
    { "a", 10, { "#27307a", "#3553b8", "#4f7fe6", "#7fb2ff", "#bfe0ff", "#f4fbff" } },
    { "k", 6, { "#3a2a80", "#6446c8", "#9272ea", "#c4a8ff" } },
    { "A", 8, { "#a8601e", "#e09a3c", "#f8d27a", "#fff0c8", "#ffffff" } },
    { "x", 3, { "#a8327e", "#e85aa8", "#ffa8d6" } },
    { "u", 2, { "#2b2f5c", "#3d3470" } },
    { "s", 1, { "#8fa0e0" } },
    { "S", 1, { "#ffffff" } },
    { "t", 1, { "#ffd9a0" } },
  },
  light = {
    { "a", 10, { "#aebbdc", "#8099d6", "#5676c4", "#37539f", "#22357a", "#141f52" } },
    { "k", 6, { "#b9a8dc", "#8e73c8", "#6a4aa8", "#472a80" } },
    { "A", 8, { "#d8a860", "#c98230", "#b06018", "#8a400c", "#602806" } },
    { "x", 3, { "#e0a0c4", "#c4569a", "#8e2a6e" } },
    { "u", 2, { "#d2cba0", "#c4bfa8" } },
    { "s", 1, { "#7a80a8" } },
    { "S", 1, { "#2a2a3a" } },
    { "t", 1, { "#a06a20" } },
  },
}
local scene_hl = {}
local function define_colors()
  for _, ramp in ipairs(palettes[vim.o.background == "light" and "light" or "dark"]) do
    local first, steps, stops = ramp[1]:byte(), ramp[2], ramp[3]
    for i = 1, steps do
      local t = steps > 1 and (i - 1) / (steps - 1) * (#stops - 1) or 0
      local k = min(max(1, #stops - 1), floor(t) + 1)
      local from = tonumber(stops[k]:sub(2), 16)
      local to = tonumber((stops[k + 1] or stops[k]):sub(2), 16)
      local f, rgb = t - (k - 1), 0
      for _, shift in ipairs({ 16, 8, 0 }) do
        local a, b = bit.band(bit.rshift(from, shift), 0xff), bit.band(bit.rshift(to, shift), 0xff)
        rgb = rgb + bit.lshift(floor(a + (b - a) * f + 0.5), shift)
      end
      local letter = string.char(first + i - 1)
      scene_hl[letter] = "DashScene_" .. letter:byte()
      api.nvim_set_hl(0, scene_hl[letter], { fg = rgb })
    end
  end
end

--------------------------------------------------------------------------------
-- 画面
--------------------------------------------------------------------------------
local CELL = 3 -- 一个盲文字符占的字节数
local SCENE_VERSION = 43 -- 改了下面的画法就加一，让旧缓存作废

-- 有序抖动：亮度 v（0–1）决定一片区域里亮多少个点，得到印刷网点一样的明暗过渡。
local BAYER = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 }
local function dither(x, y, v)
  return v > (BAYER[(floor(y) % 4) * 4 + floor(x) % 4 + 1] + 0.5) / 16
end
-- 平滑噪声：旋臂上一团一团的疏密由它决定。
local function hash(i, j)
  local n = math.sin(i * 127.1 + j * 311.7) * 43758.5453
  return n - floor(n)
end
local function noise(x, y)
  local xi, yi = floor(x), floor(y)
  local fx, fy = x - xi, y - yi
  fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
  local a, b, c, d = hash(xi, yi), hash(xi + 1, yi), hash(xi, yi + 1), hash(xi + 1, yi + 1)
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy
end
local function fbm(x, y)
  return (noise(x, y) + 0.5 * noise(2 * x + 5.2, 2 * y + 3.1) + 0.25 * noise(4 * x + 1.7, 4 * y + 9.3)) / 1.75
end

-- 生成 W×H 格的画面。clear 是菜单占的区域（点坐标），星系靠近它的地方会淡出，不压到菜单。
-- spin 是星系转过的角度。返回两组等长的行：text 是盲文字符，color 是每格一个颜色字母（空格表示没有点）。
local function generate(W, H, clear, spin)
  local Wd, Hd = W * 2, H * 4

  -- 星系的几何。长度单位 unit：原始设计里星系盘的尺度是 24、核球是 6。
  local cx, cy = Wd * 0.65, Hd * 0.52
  local unit = min(Hd / 80, Wd * 0.6 / 104) * 1.22
  local TILT = 0.52 -- 盘面朝观察者倾斜：圆盘被压成椭圆
  local ROT = -0.32 -- 椭圆的长轴从左下指向右上，左端从菜单下方伸出去
  local PITCH = 0.36 -- 旋臂卷得有多紧
  local SPIN = 0.9 + (spin or 0) -- 旋臂转到的相位
  local cr, sr = math.cos(ROT), math.sin(ROT)
  local cs, ss = math.cos(-SPIN), math.sin(-SPIN)

  -- 骑在旋臂上的亮星：沿两条对数螺线撒点，位置稍微抖开。两条旋臂上的星一一对称，
  -- 这样转半圈之后整幅画和开始时完全一样，动画可以无缝循环。
  local bright = {}
  for i = 1, 90 do
    local rad = 4 + hash(i, 1.7) * 40
    local a = math.log(rad) / PITCH + (hash(i, 4.3) - 0.5) * 0.7 + SPIN
    for _, side in ipairs({ 1, -1 }) do
      local u, w = math.cos(a) * rad * side, math.sin(a) * rad * TILT * side
      local x, y = floor(cx + (u * cr - w * sr) * unit), floor(cy + (u * sr + w * cr) * unit)
      bright[y * 4096 + x] = true
    end
  end

  local function sample(x, y)
    local dx, dy = (x - cx) / unit, (y - cy) / unit
    local u, w = dx * cr + dy * sr, (-dx * sr + dy * cr) / TILT -- 摆正并还原成正对着看的圆盘
    local rad = sqrt(u * u + w * w) + 0.001
    local gu, gw = u * cs - w * ss, u * ss + w * cs -- 跟着星系一起转的坐标
    local phase = 2 * (math.atan2(gw, gu) - math.log(rad) / PITCH)
    local arm = (0.5 + 0.5 * math.cos(phase)) ^ 2.8 -- 两条旋臂
    local lane = (0.5 + 0.5 * math.cos(phase + 0.9)) ^ 6 -- 旋臂内侧的暗尘埃带
    -- 团块的疏密：正反两个方向各取一次再平均，保证转半圈后图案重合。
    local clump = 0.5 + (fbm(gu * 0.18 + 40, gw * 0.18) + fbm(-gu * 0.18 + 40, -gw * 0.18) - 1) * 0.72
    local bulge = math.exp(-rad / 6) * 1.4
    local disk = math.exp(-rad / 19) * (0.1 + 1.9 * arm * (0.45 + clump)) * (1 - 0.5 * lane * min(1, rad / 8))
    local I = min(1, bulge + disk * 1.6)
    -- 靠近菜单的地方淡出。
    local fade = max(0, min(1, max(x - clear.x1, y - clear.y1) / (Wd * 0.2)))
    fade = fade * fade
    I = I * fade

    if I < 0.07 then
      -- 太空：三种颜色的星星，少数几颗是十字形的亮星；远处飘着一点紫蓝色的星云薄雾。
      local fx, fy = floor(x), floor(y)
      local star = hash(fx * 1.31, fy * 2.17)
      if star < 0.006 then return true, star < 0.0009 and "S" or star < 0.0016 and "t" or "s" end
      if hash((fx - 1) * 1.31, fy * 2.17) < 0.0003 or hash((fx + 1) * 1.31, fy * 2.17) < 0.0003
        or hash(fx * 1.31, (fy - 1) * 2.17) < 0.0003 or hash(fx * 1.31, (fy + 1) * 2.17) < 0.0003 then
        return true, "S"
      end
      local haze = fbm(x / unit * 0.022 + 3, y / unit * 0.03 + 8)
      if haze > 0.46 and dither(x, y, (haze - 0.46) * 0.9 * fade) then return true, haze > 0.62 and "v" or "u" end
      return false
    end
    if bright[floor(y) * 4096 + floor(x)] then return true, "S" end
    if not dither(x, y, (0.3 + I * 1.35) * min(1, fade * 1.6)) then return false end

    -- 核心：中心白热，往外变金、变棕橙；边界用抖动和旋臂的蓝色交错，不是一刀切。
    if rad < 8 + (dither(x + 1, y + 2, 0.5) and 3 or 0) then
      return true, string.char(65 + max(0, min(7, floor((1 - (rad / 11) ^ 1.6) * 8.5))))
    end
    -- 旋臂上的恒星诞生区：粉色的团块，最密的地方发白。
    if arm > 0.6 and clump > 0.63 and rad > 10 then
      return true, string.char(120 + min(2, floor((clump - 0.63) * 30)))
    end
    local level = I * 1.25 + max(0, bulge / (bulge + disk + 0.001) - 0.3) * 0.4
    -- 外缘从蓝色过渡到紫色，交界处两种颜色的点交错。
    if rad > 30 + (dither(x + 2, y + 1, 0.5) and 9 or 0) then
      return true, string.char(107 + min(5, floor(level * 3.2 * 6)))
    end
    return true, string.char(97 + min(9, floor(level * 10)))
  end

  local braille = {}
  for bits = 0, 255 do
    braille[bits] = string.char(0xE2, 0xA0 + bit.rshift(bits, 6), 0x80 + bit.band(bits, 63))
  end
  local DOT = { 0x01, 0x08, 0x02, 0x10, 0x04, 0x20, 0x40, 0x80 } -- 盲文 8 个点的位：自上而下、先左后右
  local salient = { S = 3, t = 2, x = 1, y = 1, z = 2 } -- 亮星和粉色的点少也优先，不被周围的蓝色冲掉
  local text, color = {}, {}
  local row_text, row_color, count = {}, {}, {}
  for r = 0, H - 1 do
    for c = 0, W - 1 do
      local bits = 0
      for k in pairs(count) do count[k] = nil end
      for i = 0, 7 do
        local lit, col = sample(c * 2 + i % 2 + 0.5, r * 4 + floor(i / 2) + 0.5)
        if lit then
          bits = bits + DOT[i + 1]
          count[col] = (count[col] or 0) + 1
        end
      end
      local best, score = " ", 0
      for col, n in pairs(count) do
        n = n + (salient[col] or 0)
        if n > score then best, score = col, n end
      end
      row_text[c + 1], row_color[c + 1] = braille[bits], best
    end
    text[r + 1], color[r + 1] = table.concat(row_text, "", 1, W), table.concat(row_color, "", 1, W)
  end
  return text, color
end

-- 画面按「窗口大小 + 菜单位置」缓存在一个文件里：第一次（或窗口大小变了）现算，之后直接读。
local cache_path = vim.fn.stdpath("cache") .. "/dashboard-scene.txt"
local function scene(W, H, clear)
  local key = ("v%d %d %d %d %d"):format(SCENE_VERSION, W, H, clear.x1, clear.y1)
  local file = io.open(cache_path)
  if file then
    local cached = file:read("*l") == key and vim.split(file:read("*a"), "\n", { plain = true })
    file:close()
    if cached and #cached >= H * 2 then
      return vim.list_slice(cached, 1, H), vim.list_slice(cached, H + 1, H * 2)
    end
  end
  local text, color = generate(W, H, clear)
  file = io.open(cache_path, "w")
  if file then
    file:write(key, "\n", table.concat(text, "\n"), "\n", table.concat(color, "\n"), "\n")
    file:close()
  end
  return text, color
end

-- 动画的各帧：第 index 帧（0 起）是星系多转了 index / FRAMES 个半圈的样子。
-- 帧按顺序生成，生成一帧就追加进缓存文件；下次打开同样大小的窗口时整个文件读进来，不用再算。
local frames_path = vim.fn.stdpath("cache") .. "/dashboard-frames.txt"
local frames = { key = nil, list = {}, count = 0 }
local function frame(index, W, H, clear)
  local key = ("v%d %d %d %d %d %d"):format(SCENE_VERSION, W, H, clear.x1, clear.y1, FRAMES)
  if frames.key ~= key then
    frames = { key = key, list = {}, count = 0 }
    local file = io.open(frames_path)
    local cached = file and file:read("*l") == key and vim.split(file:read("*a"), "\n", { plain = true })
    if file then file:close() end
    -- 行数必须正好是整数帧（末尾多一个空串），否则文件写坏了（比如两个 nvim 同时在写），整个重来。
    if cached and (#cached - 1) % (H * 2) == 0 then
      for i = 0, (#cached - 1) / (H * 2) - 1 do
        local base = i * H * 2
        frames.list[i] = { vim.list_slice(cached, base + 1, base + H), vim.list_slice(cached, base + H + 1, base + H * 2) }
        frames.count = i + 1
      end
    else
      file = io.open(frames_path, "w")
      if file then
        file:write(key, "\n")
        file:close()
      end
    end
  end
  local found = frames.list[index]
  if not found then
    local text, color = generate(W, H, clear, math.pi * index / FRAMES)
    found = { text, color }
    frames.list[index] = found
    if index == frames.count then -- 只按顺序追加，文件里的帧才不会乱
      local file = io.open(frames_path, "a")
      if file then
        file:write(table.concat(text, "\n"), "\n", table.concat(color, "\n"), "\n")
        file:close()
        frames.count = index + 1
      end
    end
  end
  return found[1], found[2]
end

--------------------------------------------------------------------------------
-- 排版和交互
--------------------------------------------------------------------------------
local ns = api.nvim_create_namespace("config.dashboard")
-- marks[行号（0 起）] = { { 起始列, 结束列, 高亮组 }, … }：每一行要上的颜色。
local state = { buf = nil, rows = {}, marks = {}, label_col = 0, startup_ms = nil, menu = nil, paused = false }

-- 颜色在重绘时才挂到屏幕上看得见的行（临时标记），不在缓冲区里存成持久标记：
-- 一帧画面有约 2000 段颜色，每帧删了再建一遍要 5 ms，这样做几乎不花时间。
api.nvim_set_decoration_provider(ns, {
  on_win = function(_, _, buf) return buf == state.buf end,
  on_line = function(_, _, buf, row)
    for _, m in ipairs(state.marks[row] or {}) do
      api.nvim_buf_set_extmark(buf, ns, row, m[1], { end_col = m[2], hl_group = m[3], ephemeral = true })
    end
  end,
})

-- 当前目录所在仓库的分支：直接读 .git/HEAD，不启动 git 进程。
local function cwd_branch()
  local root = vim.fs.root(vim.uv.cwd(), ".git")
  local file = root and io.open(root .. "/.git/HEAD")
  if not file then return nil end
  local head = file:read("*l") or ""
  file:close()
  return head:match("^ref: refs/heads/(.+)$") or head:sub(1, 7)
end

-- 菜单的各行：每行是若干段 { 文字, 高亮 }。返回行的列表和每个菜单项所在的行号。
local function menu_lines(spaced)
  local where = vim.fn.fnamemodify(vim.uv.cwd(), ":~")
  -- 路径太长时把中间的目录缩写成首字母，保证不超出菜单宽度。
  if width(where) > MENU_WIDTH - 12 then where = vim.fn.pathshorten(where) end
  if width(where) > MENU_WIDTH - 12 then where = "…" .. where:sub(-(MENU_WIDTH - 14)) end
  local branch = cwd_branch()
  if branch then where = where .. "  \u{e0a0} " .. branch end
  local v = vim.version()
  -- info = false：只数个数，不去查每个插件的 git 信息（那样要几十毫秒）。
  local plugins = #vim.pack.get(nil, { info = false })
  local stats = ("%d plugins · %.0f ms · v%d.%d.%d"):format(plugins, state.startup_ms or 0, v.major, v.minor, v.patch)

  local lines, item_rows = {}, {}
  local function push(...) lines[#lines + 1] = { ... } end
  push({ where, "DashDim" })
  push()
  for i, item in ipairs(items) do
    local gap = MENU_WIDTH - 3 - width(item[2]) - width(item[3])
    push({ item[1] .. "  ", "DashIcon" }, { item[2], "DashLabel" }, { (" "):rep(gap) }, { item[3], "DashKey" })
    item_rows[i] = #lines
    if spaced and i < #items then push() end
  end
  push()
  push({ quote, "DashQuote" })
  push({ stats, "DashDim" })
  return lines, item_rows
end

-- 画出启动页。index 为空时是打开或窗口变化后的完整重画；动画的每一帧传帧号，只换画面，菜单的文字沿用。
local function render(index)
  local buf = state.buf
  local win = buf and vim.fn.bufwinid(buf) or -1
  if win == -1 then return end
  local W, H = api.nvim_win_get_width(win), api.nvim_win_get_height(win)
  local with_scene = W >= MIN_WIDTH and H >= MIN_HEIGHT
  if index and not with_scene then return end
  if not index or not state.menu then
    state.menu = { menu_lines(H >= 36) }
    define_colors()
  end
  local lines, item_rows = state.menu[1], state.menu[2]

  -- 有星系时菜单在左上方；没有时居中。
  local left = with_scene and max(6, floor(W * 0.07)) or max(0, floor((W - MENU_WIDTH) / 2))
  local top = with_scene and max(3, floor(H * 0.12)) or max(0, floor((H - #lines) / 2))

  local text, color
  if with_scene then
    local clear = { x1 = (left + MENU_WIDTH) * 2 + 6, y1 = (top + #lines) * 4 }
    if index then
      text, color = frame(index, W, H, clear)
    else
      text, color = scene(W, H, clear)
    end
  end

  local out, marks = {}, {}
  state.rows = {}
  for r = 1, H do
    local segments = lines[r - top]
    local art, colors = text and text[r], color and color[r]
    local str, pos, row_marks = "", 0, {}
    marks[r - 1] = row_marks
    -- 把画面的第 a..b 格接到这一行后面，并按颜色分段上色。
    local function add_art(a, b)
      if not art or b < a then
        if not art then str = str .. (" "):rep(max(0, b - a + 1)) end
        return
      end
      local base, start = #str - (a - 1) * CELL, a
      for c = a + 1, b + 1 do
        if c > b or colors:byte(c) ~= colors:byte(start) then
          local hl = scene_hl[colors:sub(start, start)]
          if hl then row_marks[#row_marks + 1] = { base + (start - 1) * CELL, base + (c - 1) * CELL, hl } end
          start = c
        end
      end
      str = str .. art:sub((a - 1) * CELL + 1, b * CELL)
    end

    if segments then
      -- 菜单所在的行：画面在菜单两侧，菜单这一段是纯文字。
      add_art(1, left)
      pos = #str
      local cells = 0
      for _, seg in ipairs(segments) do
        if seg[2] then row_marks[#row_marks + 1] = { #str, #str + #seg[1], seg[2] } end
        str = str .. seg[1]
        cells = cells + width(seg[1])
      end
      str = str .. (" "):rep(max(0, MENU_WIDTH - cells))
      add_art(left + max(MENU_WIDTH, cells) + 1, W)
      for item, row in ipairs(item_rows) do
        if row == r - top then
          state.rows[item] = r
          state.label_col = pos + #items[item][1] + 2
        end
      end
    else
      add_art(1, W)
    end
    out[r] = str
  end

  state.marks = marks
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].modifiable = false
end

-- 光标只停在菜单项上。
local function current_item()
  local row = api.nvim_win_get_cursor(0)[1]
  local best, distance = 1, math.huge
  for i, r in ipairs(state.rows) do
    if abs(r - row) < distance then best, distance = i, abs(r - row) end
  end
  return best
end

local function goto_item(index)
  index = max(1, min(#items, index))
  if state.rows[index] then
    api.nvim_win_set_cursor(0, { state.rows[index], state.label_col })
  end
end

-- 动画：一个定时器按顺序换帧。只在启动页是当前窗口、处于普通模式、终端有焦点时才画，
-- 其余时候（打开了搜索、在输命令、切到别的程序）什么都不做；启动页关掉时定时器随之销毁。
local timer
local function stop_animation()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end
local function start_animation()
  if not ANIMATE or timer then return end
  local index = -1 -- 第一次换帧画第 0 帧，让它也进缓存文件
  timer = vim.uv.new_timer()
  timer:start(600, floor(1000 / FPS), vim.schedule_wrap(function()
    local buf = state.buf
    if not timer then return end
    if not (buf and api.nvim_buf_is_valid(buf)) then return stop_animation() end
    if state.paused or api.nvim_get_current_buf() ~= buf or api.nvim_get_mode().mode ~= "n" then return end
    index = (index + 1) % FRAMES
    local item = current_item()
    render(index)
    goto_item(item)
  end))
end

local function open()
  local buf = api.nvim_get_current_buf()
  state.buf = buf
  state.startup_ms = state.startup_ms or (vim.uv.hrtime() - vim.g.config_start) / 1e6

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "dashboard"
  for name, value in pairs({ number = false, relativenumber = false, cursorline = false, list = false, wrap = false, foldenable = false }) do
    vim.wo[0][0][name] = value
  end

  render()
  goto_item(1)

  local function nmap(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true }) end
  for _, item in ipairs(items) do nmap(item[3], item[4]) end
  nmap("<CR>", function() items[current_item()][4]() end)
  for _, key in ipairs({ "j", "<Down>", "<Tab>", "<C-n>" }) do
    nmap(key, function() goto_item(current_item() + 1) end)
  end
  for _, key in ipairs({ "k", "<Up>", "<S-Tab>", "<C-p>" }) do
    nmap(key, function() goto_item(current_item() - 1) end)
  end

  local group = api.nvim_create_augroup("ConfigDashboard", { clear = true })
  -- 窗口大小或配色变化时重新排版；鼠标点到别处时把光标拉回最近的菜单项。
  api.nvim_create_autocmd({ "VimResized", "WinResized", "ColorScheme" }, {
    group = group,
    callback = function()
      if not api.nvim_buf_is_valid(buf) then return true end
      if vim.fn.bufwinid(buf) == -1 then return end
      local index = api.nvim_get_current_buf() == buf and current_item() or 1
      render()
      if api.nvim_get_current_buf() == buf then goto_item(index) end
    end,
  })
  api.nvim_create_autocmd("CursorMoved", {
    group = group,
    buffer = buf,
    callback = function() goto_item(current_item()) end,
  })
  api.nvim_create_autocmd({ "FocusLost", "FocusGained" }, {
    group = group,
    callback = function(event) state.paused = event.event == "FocusLost" end,
  })
  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      stop_animation()
      state.marks = {}
    end,
  })
  start_animation()
end

-- 只在「不带文件、不带管道输入」启动时出现。
api.nvim_create_autocmd("VimEnter", {
  group = api.nvim_create_augroup("ConfigDashboardOpen", { clear = true }),
  once = true,
  nested = true,
  callback = function()
    local buf = api.nvim_get_current_buf()
    if vim.fn.argc() > 0 or api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then return end
    if api.nvim_buf_line_count(buf) > 1 or api.nvim_buf_get_lines(buf, 0, 1, false)[1] ~= "" then return end
    open()
  end,
})
