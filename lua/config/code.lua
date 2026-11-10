-- 代码：语法高亮、文本对象、括号与包围符号、补全（blink.cmp）、LSP（原生 vim.lsp）。
local M = {}

--------------------------------------------------------------------------------
-- Treesitter：常用解析器，运行 :TSInstallDefaults 安装。
-- 解析器只在打开对应文件时加载，多装几个不影响启动速度。
--------------------------------------------------------------------------------
M.languages = {
  -- 常写的语言
  "typst", "c", "cpp", "ocaml", "ocaml_interface", "haskell",
  -- 配置与脚本
  "bash", "fish", "lua", "python", "json", "toml", "yaml", "query", "regex", "vim", "vimdoc",
  -- 文档与 Git
  "markdown", "markdown_inline", "diff", "gitcommit",
  -- 偶尔打开
  "css", "html", "javascript", "rust", "tsx", "typescript", "zig", "go", "swift",
}

local group = vim.api.nvim_create_augroup("ConfigCode", { clear = true })

-- 大文件（日志、压缩过的 JSON 等）：解析整份语法树要好几秒，打开、移动都会卡。
local BIG_FILE = 1024 * 1024
local function is_big(buf)
  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  return stat ~= nil and stat.size > BIG_FILE
end

-- 按文件类型启动高亮与缩进，解析器未安装时跳过。
-- 大文件不启动 treesitter，折叠也改成手动（treesitter 折叠会自己去解析整份文件）。
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(event)
    if is_big(event.buf) then
      vim.opt_local.foldmethod = "manual"
      return
    end
    local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
    if lang and pcall(vim.treesitter.start, event.buf, lang) then
      -- C / C++ 保留内置 cindent，其余语言使用 treesitter 缩进。
      if lang ~= "c" and lang ~= "cpp" then
        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end
  end,
})

-- 按语法树选择 / 跳转 / 交换代码块；快捷键见 keymaps.lua。
require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true }, -- 光标不在对象内时，向前找最近的一个。
  move = { set_jumps = true }, -- 跳转计入跳转列表，可用 Ctrl-o 返回。
})

-- 输入括号和引号时自动配对。
require("nvim-autopairs").setup({})
-- 包围符号：ysiw" 加、cs"' 改、ds" 删；选中后按 S 加。
require("nvim-surround").setup({})

--------------------------------------------------------------------------------
-- 补全：blink.cmp。打字时自动弹出，默认不选中任何一项，不理它继续打字就不受影响。
--   Ctrl-n / Ctrl-p 选择（选中的文字直接填进去）   Ctrl-y 确认   Ctrl-e 关闭
--   Ctrl-Space 手动触发 / 开关文档   Ctrl-b / Ctrl-f 滚动文档   Tab / Shift-Tab 在片段占位间跳
--   Enter 只换行，不会确认补全。
-- 来源：语言服务、路径、代码片段、当前文件里出现过的词。按 : 时的命令行补全也由它负责。
--------------------------------------------------------------------------------
-- blink 加载较慢，放到启动完成后（见 plugins.lua 的 later）；语言服务在它之后才启动，
-- 这样各服务一开始就知道编辑器支持哪些补全能力。
local function setup_completion()
  local selection = { preselect = false, auto_insert = true }
  require("blink.cmp").setup({
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      list = { selection = selection },
      menu = {
        border = "rounded",
        scrollbar = false,
        -- 每行：类型图标、名字（及补充说明）、类型名。
        draw = { columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } } },
      },
      documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
      ghost_text = { enabled = true }, -- 选中项以灰字预览在光标后。
    },
    signature = { enabled = true, window = { border = "rounded" } }, -- 输入参数时显示函数签名。
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    cmdline = {
      keymap = { preset = "cmdline" },
      completion = {
        list = { selection = selection },
        menu = { auto_show = true, draw = { columns = { { "label", "label_description", gap = 1 } } } },
      },
    },
  })
end

--------------------------------------------------------------------------------
-- LSP：只用 Neovim 原生的 vim.lsp。
-- 启动时是否开启；运行中用 <leader>lt 随时开关（只影响本次会话）。
--------------------------------------------------------------------------------
local enabled = true

local home = vim.env.HOME

-- 每个语言一项：enabled 是单独的开关，cmd 用绝对路径，不依赖 PATH。
-- 可执行文件不存在时自动跳过，不报错。
local servers = {
  clangd = {
    enabled = true,
    cmd = {
      "/opt/homebrew/opt/llvm/bin/clangd",
      "--background-index", -- 后台索引整个项目，跨文件跳转和查找引用才完整。
      "--clang-tidy",
      "--completion-style=detailed",
      "--header-insertion=never", -- 补全时不自动加 #include。
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
  },
  zls = {
    enabled = true,
    cmd = { "/opt/homebrew/bin/zls" },
    filetypes = { "zig", "zir" },
    root_markers = { "zls.json", "build.zig", ".git" },
  },
  ocamllsp = {
    enabled = true,
    -- 路径带 opam switch 的版本号；换 switch 后要跟着改。
    cmd = { home .. "/.opam/5.5.2/bin/ocamllsp" },
    filetypes = { "ocaml", "ocaml.interface", "ocaml.menhir", "ocaml.ocamllex", "dune" },
    root_markers = { "dune-project", "dune-workspace", ".git" },
  },
  sourcekit = {
    enabled = true,
    cmd = { "/usr/bin/sourcekit-lsp" },
    filetypes = { "swift" }, -- C / C++ 交给 clangd。
    root_markers = { "Package.swift", "buildServer.json", ".git" },
  },
  gopls = {
    enabled = true,
    cmd = { home .. "/go/bin/gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
  },
  rust_analyzer = {
    enabled = true,
    -- rustup 的代理，跟随当前工具链；需要 rustup component add rust-analyzer。
    cmd = { "/opt/homebrew/opt/rustup/bin/rust-analyzer" },
    filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  },
  tinymist = {
    enabled = true,
    cmd = { "/opt/homebrew/bin/tinymist" },
    filetypes = { "typst" },
    root_markers = { "typst.toml", ".git" },
    -- <leader>lf 格式化时用 typstyle；不在保存时自动导出 PDF。
    settings = { formatterMode = "typstyle", exportPdf = "never" },
  },
  hls = {
    enabled = true,
    -- 路径带 HLS 的版本号；用 ghcup 升级后要跟着改。
    cmd = { home .. "/.ghcup/hls/2.14.0.0/bin/haskell-language-server-wrapper", "--lsp" },
    -- wrapper 按项目的 GHC 版本在 PATH 里找 haskell-language-server-<版本>，把它所在目录加进去。
    cmd_env = { PATH = home .. "/.ghcup/hls/2.14.0.0/bin:" .. vim.env.PATH },
    filetypes = { "haskell", "lhaskell", "cabal" },
    root_markers = { "hie.yaml", "cabal.project", "stack.yaml", "package.yaml", ".git" },
  },
}

-- 先登记所有可用的服务，是否启动由开关决定。补全能力由 blink.cmp 加载时自动告知各服务。
local names = {}
for name, server in pairs(servers) do
  if server.enabled and vim.fn.executable(server.cmd[1]) == 1 then
    vim.lsp.config(name, {
      cmd = server.cmd,
      cmd_env = server.cmd_env,
      filetypes = server.filetypes,
      root_markers = server.root_markers,
      settings = server.settings,
    })
    names[#names + 1] = name
  end
end

-- 诊断：波浪线标出位置，说明文字只在光标所在行显示，其余行保持干净。
-- 行号列不放符号；数量看右上角的胶囊。
vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  underline = true,
  signs = false,
  virtual_text = { current_line = true, prefix = "●", spacing = 2 },
  float = { source = true },
})

vim.keymap.set("n", "<leader>lt", function()
  enabled = not enabled
  vim.lsp.enable(names, enabled)
  vim.notify(enabled and "LSP 已开启" or "LSP 已关闭")
end, { silent = true, desc = "Toggle LSP (开关语言服务)" })

-- 只在挂上语言服务的缓冲区里绑定；服务离开时按这张表原样删掉。
-- 原生默认按键仍然有效：grn 重命名、gra 代码操作、grr 引用、gri 实现、
-- grt 类型定义、gO 文件符号、]d / [d 跳诊断。
local pick = require("config.tools").pick
local keys = {
  -- 文档浮窗限制大小，长文档不会盖住整个屏幕。
  { "K", function() vim.lsp.buf.hover({ max_width = 80, max_height = 20 }) end, "Hover docs (查看文档)" },
  { "gd", vim.lsp.buf.definition, "Go to definition (跳到定义)" },
  { "gD", vim.lsp.buf.declaration, "Go to declaration (跳到声明)" },
  { "<leader>lf", function() vim.lsp.buf.format() end, "Format buffer (格式化文件)" },
  { "<leader>lh", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
  end, "Toggle inlay hints (开关内联提示)" },
  { "<leader>le", vim.diagnostic.open_float, "Line diagnostics (本行诊断)" },
  { "<leader>ld", pick("diagnostics_document"), "Diagnostics, file (文件诊断)" },
  { "<leader>lD", pick("diagnostics_workspace"), "Diagnostics, project (项目诊断)" },
  { "<leader>ls", pick("lsp_document_symbols"), "Symbols, file (文件符号)" },
  { "<leader>lS", pick("lsp_live_workspace_symbols"), "Symbols, project (项目符号)" },
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(event)
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key[1], key[2], { buffer = event.buf, silent = true, desc = key[3] })
    end
  end,
})

-- 最后一个语言服务离开缓冲区时（<leader>lt、:lsp disable、服务退出），收回这些按键。
vim.api.nvim_create_autocmd("LspDetach", {
  group = group,
  callback = function(event)
    local buf = event.buf
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      if client.id ~= event.data.client_id then
        return
      end
    end
    for _, key in ipairs(keys) do
      pcall(vim.keymap.del, "n", key[1], { buffer = buf })
    end
  end,
})

require("config.plugins").later(function()
  setup_completion()
  if enabled then
    vim.lsp.enable(names)
  end
end)

return M
