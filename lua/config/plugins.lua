-- 每个插件只做一件事，没有打包型插件；配置在对应的功能模块里。
-- 用 vim.pack.update() 升级，实际版本记录在 nvim-pack-lock.json。
local M = {}
local gh = "https://github.com/"

-- 第一屏就要用到的：启动时直接加载。
vim.pack.add({
  -- 界面
  gh .. "rebelot/kanagawa.nvim", -- 配色：深色 wave，浅色 lotus。
  gh .. "b0o/incline.nvim", -- 每个窗口右上角的浮动状态胶囊，替代状态栏和标签栏。
  gh .. "nvim-tree/nvim-web-devicons", -- 文件图标。
  gh .. "karb94/neoscroll.nvim", -- 平滑滚动。
  gh .. "folke/which-key.nvim", -- 按键提示。
  gh .. "rachartier/tiny-cmdline.nvim", -- 把命令行挪成屏幕中间的浮窗。
  -- 工具
  gh .. "stevearc/oil.nvim", -- 像编辑文本一样管理文件。
  gh .. "ibhagwan/fzf-lua", -- 模糊搜索。
  gh .. "MagicDuck/grug-far.nvim", -- 批量搜索替换。
  gh .. "folke/flash.nvim", -- 屏幕内跳转。
  -- 代码
  gh .. "nvim-treesitter/nvim-treesitter",
  { src = gh .. "nvim-treesitter/nvim-treesitter-textobjects", version = "main" }, -- 按语法结构选择、跳转、交换。
  gh .. "windwp/nvim-autopairs", -- 括号和引号自动配对。
  gh .. "kylechui/nvim-surround", -- 加 / 改 / 删包围符号。
}, { confirm = false, load = true })

-- M.later(函数)：把一段初始化推迟到启动完成之后。启动时先把界面画出来，
-- 紧接着（几毫秒内）再做这些事，打开 nvim 的那一下更快，用起来没有区别。
local queue, started = {}, false
function M.later(fn)
  if started then
    fn()
  else
    queue[#queue + 1] = fn
  end
end
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      started = true
      for _, fn in ipairs(queue) do
        local ok, err = pcall(fn)
        if not ok then vim.notify("延迟加载出错：\n" .. err, vim.log.levels.ERROR) end
      end
    end)
  end,
})

-- 加载比较慢、又不影响第一屏的：等界面画出来之后再加载，各自的配置也都放在 later 里。
M.later(function()
  vim.pack.add({
    gh .. "lukas-reineke/indent-blankline.nvim", -- 缩进线和当前作用域。
    gh .. "lewis6991/gitsigns.nvim", -- Git 修改标记。
    { src = gh .. "Saghen/blink.cmp", version = vim.version.range("1.x") }, -- 补全；跟随 1.x 的发布版，自带预编译的匹配器。
  }, { confirm = false, load = true })
end)

return M
