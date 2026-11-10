-- 记录启动起点，启动页用它算启动耗时。
vim.g.config_start = vim.uv.hrtime()
-- 缓存编译后的 Lua 字节码，之后每次启动少读少编译。
vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 按顺序加载，顺序有依赖，不要随意调换。
-- 每个模块单独保护：某一个出错（比如插件升级后改了接口）只影响它自己，
-- 其余照常加载，错误在启动后以通知的形式报出来。
local modules = {
  "options", -- 选项和自动命令
  "plugins", -- 插件清单
  "ui", -- 配色、浮动状态胶囊、行号列、消息、缩进线、滚动、按键提示
  "dashboard", -- 启动页
  "tools", -- 文件管理、搜索、替换、Git、跳转
  "code", -- 语法高亮、文本对象、补全、LSP
  "keymaps", -- 快捷键和自定义命令
  "neovide", -- 只在 Neovide 里生效
}
for _, name in ipairs(modules) do
  local ok, err = pcall(require, "config." .. name)
  if not ok then
    vim.schedule(function()
      vim.notify("config." .. name .. " 加载失败：\n" .. err, vim.log.levels.ERROR)
    end)
  end
end
