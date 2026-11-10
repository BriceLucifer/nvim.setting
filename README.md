# nvim.setting

一套给 **Neovim 0.12+** 的个人配置：17 个插件，每个只做一件事，没有打包型插件；全部配置是 8 个 Lua 文件。

- **没有下巴**：没有状态栏、没有命令行那一行、没有标签栏，屏幕上下都是代码。
- **全浮动**：状态信息在每个窗口右上角的胶囊里；按 `:` 时命令行在屏幕中间浮出；通知是右上角的小卡片；普通消息在右下角出现几秒后消失。
- **Kanagawa 配色**：深色 wave、浅色 lotus，跟随系统自动切换。
- **手写而不是插件**：启动页（会转动的星系）、通知卡片、行号列、输入框、关闭文件、窗口放大，都是配置里的 Lua。
- **快**：启动约 30 ms。补全、Git 标记、缩进线在第一屏画出来之后才加载；超过 1 MB 的文件自动关掉语法树，打开和移动不卡。

## 安装

**1. 外部程序**

| 必需 | 用途 |
| --- | --- |
| Neovim 0.12 以上 | 插件管理用的是内置的 `vim.pack` |
| `git` | 下载插件 |
| `fzf`、`rg`、`fd` | 搜索 |
| Nerd Font 字体 | 图标；作者用的是 Maple Mono NF CN |
| `tree-sitter-cli`、C 编译器 | 安装语法解析器 |

可选：`zoxide`（跳常用目录）、各语言的语言服务（见 [LSP](#lsp)）、`fish`（装了就作为 nvim 里的 shell）。

macOS 一条命令装齐必需的部分：

```sh
brew install neovim git fzf ripgrep fd tree-sitter-cli zoxide
```

**2. 下载配置**

```sh
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null   # 有旧配置先挪开
git clone git@github.com:BriceLucifer/nvim.setting.git ~/.config/nvim
```

**3. 第一次打开**

```sh
nvim
```

第一次启动会按 `nvim-pack-lock.json` 里记录的版本自动下载全部插件，等它跑完后 `:restart`。然后在 nvim 里运行一次：

```vim
:TSInstallDefaults
```

装好常用语言的语法解析器（列表在 `code.lua` 的 `M.languages`）。

**4. 改语言服务路径**

`code.lua` 里各语言服务用的是作者机器上的绝对路径。找不到的会自动跳过，不报错；要用哪个，就把它的 `cmd` 改成你机器上的路径。

## 最常用的键

`<leader>` 是**空格键**：`<leader>ff` 就是依次按 `空格`、`f`、`f`。按下空格停 0.2 秒，右下角会列出可用的按键。

| 按键 | 作用 |
| --- | --- |
| `<leader>ff` / `<leader>fg` | 按文件名找文件 / 在所有文件里搜文字 |
| `<leader><leader>` | 在已打开的文件之间切换（没有标签栏，靠它） |
| `-` / `<leader>e` | 文件管理：原地打开所在目录 / 浮窗打开 |
| `s` + 几个字符 | 跳到屏幕上任意位置 |
| `gd` / `K` / `grn` | 跳到定义 / 看文档 / 重命名（需要 LSP） |
| `ysiw"` / `cs"'` / `ds"` | 给单词加引号 / 把 `"` 换成 `'` / 去掉引号 |
| `<leader>sv` / `<leader>sh` | 左右分屏 / 上下分屏 |
| `Ctrl-h` `j` `k` `l` | 在窗口之间移动 |
| `]c` / `[c`、`<leader>gp` | 跳到下一处 / 上一处 Git 修改、预览修改 |
| `<leader>w` / `<leader>q` | 保存 / 退出 |
| `<leader>n` / `<leader>m` | 翻看通知历史 / 消息历史 |
| `<leader>fk` | 忘了按键时搜索所有快捷键 |

## 界面

**右上角的胶囊**（每个窗口一个），从左到右：

1. 模式色块（`NOR` `INS` `VIS` `CMD`…），颜色随模式变。
2. 正在发生的事：录制宏（`@a`）、选区大小、搜索位置（`2/6`），只在发生时出现。
3. 诊断数量：错误、警告、提示。
4. Git 改动行数：新增、修改、删除。
5. 分支名、正在生效的语言服务名（如 `clangd`）。
6. 最右边永远是图标和文件名；未保存时文件名变色并带 `●`；两个打开的文件同名时前面带上级目录。

其他窗口的胶囊只有图标和文件名，颜色压暗。胶囊不会盖住代码：窗口第一行的文字较长时，它从右往左依次省略语言服务、分支、Git、诊断，只留模式和文件名。

**命令行**：按 `:` 或 `/` 时在屏幕中上方浮出一个圆角小窗，补全菜单跟在它下面。只有"保存吗？是 / 否 / 取消"这类确认留在底部。

**通知**：右上角的圆角卡片，排在胶囊下面，多条往下叠，几秒后消失；警告和错误的边框带颜色。语言服务加载项目的进度是一张原地更新的卡片。

**消息**：`:echo` 之类出现在右下角。输出很长时（比如 `:map`）在底部展开，`[+95]` 表示还有 95 行，`g<` 看全部、`q` 关闭。

**启动页**：不带文件打开 nvim 时出现。一个倾斜的旋涡星系：白热的金色核心、由冰白到蓝再到紫的两条旋臂、粉色的恒星诞生区，周围是星空和淡淡的星云；菜单浮在左上方。按右边的字母直接执行，或 `j` / `k` 移动后按 `Enter`。

- 星系每秒 6 帧慢慢转动，转半圈后无缝循环。每一帧只在第一次出现时算一次，之后从缓存文件（`~/.cache/nvim/dashboard-frames.txt`）读。
- 离开启动页、在输命令、终端失去焦点时画面停住；启动页关掉后定时器销毁，不占 CPU。
- 不想要动画：`dashboard.lua` 顶部 `ANIMATE = false`。窗口小于 96×26 时只显示菜单。

**行号列**：行号右边的细条是 Git 修改（绿 新增 / 黄 修改 / 红 删除）。只有当前窗口显示相对行号。上下分屏之间的横线就是分隔线。

## 全部快捷键

### 文件管理（oil）

目录是一个可以编辑的缓冲区：改名就改那一行的字，删除就 `dd`，新建就写一行新名字（以 `/` 结尾是目录），移动就剪切粘贴到另一个目录。**`:w` 之后才真正生效**，删除的文件进废纸篓。

| 按键 | 作用 |
| --- | --- |
| `-` | 打开当前文件所在目录；在目录里再按是回上级 |
| `<leader>e` / `<leader>E` | 浮窗打开所在目录 / 工作目录 |
| `Enter` | 进入目录 / 打开文件 |
| `Ctrl-v` / `Ctrl-s` / `Ctrl-t` | 在左右分屏 / 上下分屏 / 新标签页里打开 |
| `Ctrl-p` | 预览 |
| `g.` | 显示 / 隐藏以 `.` 开头的文件 |
| `gs` / `gx` | 换排序方式 / 用系统程序打开 |
| `Ctrl-r` | 刷新 |
| `q` | 关闭；`g?` 看全部按键 |

### 搜索

| 按键 | 作用 |
| --- | --- |
| `<leader>ff` | 按文件名找文件 |
| `<leader>fg` | 在所有文件里搜文字 |
| `<leader>fw` | 搜索光标下的这个词 |
| `<leader>fb` 或 `<leader><leader>` | 已打开的文件 |
| `<leader>fr` | 最近打开过的文件 |
| `<leader>fl` | 回到上一次搜索的结果 |
| `<leader>fz` | 用 zoxide 跳到常去的目录（也可以 `:Z 关键词`） |
| `<leader>fh` / `<leader>fk` / `<leader>fc` | 搜索帮助文档 / 快捷键 / 命令 |
| `<leader>fR` | 批量搜索替换面板（大写 R） |

搜索窗口是 Telescope 的版式（输入框在下、结果在上、预览在右），底下跑的是 fzf。窗口里 `Ctrl-d` / `Ctrl-u` 滚动预览，`Ctrl-v` / `Ctrl-x` / `Ctrl-t` 在分屏或新标签页里打开，`Ctrl-q` 把全部结果送进 quickfix。

替换面板里 `空格 r` 执行替换，`空格 c` 关闭，`g?` 看帮助。**替换前先看清预览。**

### 窗口、文件、标签页

| 按键 | 作用 |
| --- | --- |
| `<leader>sv` / `<leader>sh` | 左右分屏 / 上下分屏 |
| `Ctrl-h` `Ctrl-j` `Ctrl-k` `Ctrl-l` | 切到左 / 下 / 上 / 右边的窗口 |
| `<leader>sc` / `<leader>so` | 关掉当前窗口 / 只留当前窗口 |
| `<leader>se` | 所有窗口一样大 |
| `<leader>sz` | 临时放大当前窗口，再按一次恢复 |
| `<leader>sH` `sL` `sK` `sJ` | 把分隔线往左 / 右 / 上 / 下挪 |
| `]b` / `[b`（或 `Shift-Tab`） | 下一个 / 上一个打开的文件 |
| `<leader>bd` | 关闭当前文件，保留窗口布局；没保存会问你 |
| `<leader>bo` | 关闭其他文件 |
| `<leader>tn` / `<leader>tc` / `<leader>to` | 新建 / 关闭 / 只留当前标签页 |
| `]t` / `[t` | 下一个 / 上一个标签页 |

### Git

| 按键 | 作用 |
| --- | --- |
| `]c` / `[c` | 跳到下一处 / 上一处修改 |
| `<leader>gp` | 预览这一处修改 |
| `<leader>gs` / `<leader>gS` | 暂存这一处 / 整个文件 |
| `<leader>gr` | 还原这一处修改（丢掉改动） |
| `<leader>gb` / `<leader>gB` | 这一行 / 整个文件每一行是谁改的 |
| `<leader>gd` | 这个文件和上一版的差异 |

### 跳转和编辑

| 按键 | 作用 |
| --- | --- |
| `s` | 屏幕上快速跳转：输入几个字符，再按提示的字母 |
| `S`（选中后用 `R`） | 按代码结构选中一块 |
| `ys{范围}{符号}` | 加包围符号：`ysiw)` 给单词加括号，`yss"` 给整行加引号 |
| `cs{旧}{新}` / `ds{符号}` | 换 / 删包围符号 |
| `S{符号}`（选中后） | 给选区加包围符号 |
| `n` / `N` | 下一个 / 上一个搜索结果，居中 |
| `Ctrl-d` / `Ctrl-u` | 平滑翻半页 |
| `<` / `>`（选中后） | 缩进，选区不丢 |
| `J` / `K`（选中后） | 把选中的几行下移 / 上移 |
| `<leader>p`（选中后） | 粘贴覆盖选区，被覆盖的文字不进剪贴板 |
| `Esc` | 清除搜索高亮 |

### 文本对象

配合 `d` `c` `y` `v` 使用：`a` 连边界一起，`i` 只要里面。依赖 treesitter 解析器。

| 按键 | 对象 |
| --- | --- |
| `af` / `if` | 函数 |
| `ac` / `ic` | 类 / 结构体 |
| `aa` / `ia` | 参数 |
| `al` / `il` | 循环 |
| `ai` / `ii` | 条件语句 |
| `]f` `[f` `]F` `[F` | 下 / 上一个函数的开头、结尾 |
| `]k` / `[k` | 下 / 上一个类 |
| `<leader>an` / `<leader>ap` | 当前参数与下一个 / 上一个交换 |

### 补全（blink.cmp）

打字时自动弹出，默认不选中任何一项，不理它继续打字就不受影响。按 `:` 时的命令补全也是它。

| 按键 | 作用 |
| --- | --- |
| `Ctrl-n` / `Ctrl-p` | 下一项 / 上一项，选中的文字直接填进去 |
| `Ctrl-y` | 确认，并执行附带动作（自动加 import、展开参数等） |
| `Ctrl-e` | 关掉菜单 |
| `Ctrl-Space` | 手动触发；菜单开着时开关文档窗 |
| `Ctrl-b` / `Ctrl-f` | 滚动文档 |
| `Tab` / `Shift-Tab` | 在代码片段的占位之间跳 |
| `Ctrl-k` | 开关函数签名提示 |
| `Enter` | 只换行，不会确认补全 |

### LSP

只在挂上语言服务的文件里生效；胶囊里出现服务名（如 `clangd`）就说明挂上了。

| 按键 | 作用 |
| --- | --- |
| `K` | 看文档 |
| `gd` / `gD` | 跳到定义 / 声明（`Ctrl-o` 返回） |
| `grr` / `gri` / `grt` | 引用 / 实现 / 类型定义 |
| `grn` / `gra` | 重命名 / 代码操作 |
| `gO` | 当前文件的符号列表 |
| `]d` / `[d` | 下一个 / 上一个诊断 |
| `<leader>le` | 本行诊断的完整内容 |
| `<leader>ld` / `<leader>lD` | 搜索当前文件 / 整个项目的诊断 |
| `<leader>ls` / `<leader>lS` | 搜索当前文件 / 整个项目的符号 |
| `<leader>lf` | 格式化（不会在保存时自动格式化） |
| `<leader>lh` | 开关内联提示 |
| `<leader>lt` | 开 / 关全部 LSP（只影响这一次） |

已配置的语言服务（`code.lua` 的 `servers` 表，都是绝对路径，找不到就跳过）：

| 语言 | 语言服务 | 路径 |
| --- | --- | --- |
| C / C++ | clangd | `/opt/homebrew/opt/llvm/bin/clangd` |
| Zig | zls | `/opt/homebrew/bin/zls` |
| OCaml | ocamllsp | `~/.opam/5.5.2/bin/ocamllsp` |
| Swift | sourcekit-lsp | `/usr/bin/sourcekit-lsp` |
| Go | gopls | `~/go/bin/gopls` |
| Rust | rust-analyzer | `/opt/homebrew/opt/rustup/bin/rust-analyzer` |
| Haskell | haskell-language-server | `~/.ghcup/hls/2.14.0.0/bin/…` |
| Typst | tinymist | `/opt/homebrew/bin/tinymist` |

- **OCaml 和 Haskell 的路径里带版本号**，升级后要改 `code.lua` 里对应那一行，否则它会悄悄不启动。
- **C / C++ 项目需要 `compile_commands.json`**，否则 clangd 会报找不到头文件之类的假错误。CMake 配置时加 `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`。
- 诊断：出错的位置画波浪线，说明文字只在光标所在行出现。

### Neovide

只在 Neovide 里生效。字体和标题栏在 `~/.config/neovide/config.toml`。

| 按键 | 作用 |
| --- | --- |
| `Cmd-c` / `Cmd-v` / `Cmd-s` | 复制 / 粘贴 / 保存 |
| `Cmd-=` / `Cmd--` / `Cmd-0` | 放大 / 缩小 / 恢复字号 |

`Option` 当 `Alt` 用；中文输入法只在输入模式和命令行里打开。

## 文件结构

```text
init.lua                入口：按顺序加载下面 8 个模块
nvim-pack-lock.json     插件实际装的版本（自动生成，别手改）
lua/config/
├── options.lua         选项和自动命令（缩进、折叠、剪贴板、复制高亮…）
├── plugins.lua         插件清单
├── ui.lua              配色、命令行、通知卡片、输入框、行号列、胶囊、缩进线、滚动、按键提示
├── dashboard.lua       启动页（菜单和星系画面）
├── tools.lua           oil、FZF-Lua、GrugFar、gitsigns、Flash
├── code.lua            treesitter、文本对象、补全、LSP
├── keymaps.lua         快捷键（LSP 的在 code.lua）和自定义命令
└── neovide.lua         Neovide 专用
```

每个模块单独保护：某一个出错只影响它自己，错误在启动后以通知的形式报出来。

## 插件

| 插件 | 用途 |
| --- | --- |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | 配色 |
| [incline.nvim](https://github.com/b0o/incline.nvim) | 右上角的浮动胶囊 |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | 文件图标 |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | 缩进线 |
| [neoscroll.nvim](https://github.com/karb94/neoscroll.nvim) | 平滑滚动 |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | 按键提示 |
| [tiny-cmdline.nvim](https://github.com/rachartier/tiny-cmdline.nvim) | 居中的浮动命令行 |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | 文件管理 |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | 搜索 |
| [grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim) | 批量替换 |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git 标记和操作 |
| [flash.nvim](https://github.com/folke/flash.nvim) | 屏幕内跳转 |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)、[nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) | 语法高亮、文本对象 |
| [blink.cmp](https://github.com/Saghen/blink.cmp) | 补全 |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | 括号配对 |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | 包围符号 |

## 日常维护

| 想做什么 | 怎么做 |
| --- | --- |
| 改完配置让它生效 | `:restart` |
| 更新插件 | 启动页按 `u`，或 `:lua vim.pack.update()`；确认后记得提交 `nvim-pack-lock.json` |
| 加一种语言的高亮 | 在 `code.lua` 的 `M.languages` 里加名字，然后 `:TSInstallDefaults` |
| 加一种语言的 LSP | 在 `code.lua` 的 `servers` 表里加一项 |
| 换启动页的那句话 / 菜单项 | `dashboard.lua` 里的 `quote` / `items` |
| 存档并同步到 GitHub | `git -C ~/.config/nvim commit -am "说明" && git -C ~/.config/nvim push` |
| 在另一台机器上同步 | `git -C ~/.config/nvim pull`，再 `:restart`（新插件会自动装上） |

## 出了问题

| 现象 | 先看这里 |
| --- | --- |
| 启动后弹出"config.xxx 加载失败" | 那个模块出错了，消息里有原因；多半是插件更新后接口变了 |
| 更新插件后出问题 | 把 `nvim-pack-lock.json` 里那个插件的 `rev` 改回更新前的值，再 `:lua vim.pack.update({ "插件名" }, { offline = true, target = "lockfile" })` |
| 命令行或消息显示不正常 | `ui.lua` 里 `use_ui2 = false`，回到传统的底部命令行（ui2 在 0.12 里仍是实验性的） |
| 改坏了想退回去 | `git -C ~/.config/nvim checkout .` 回到上次提交 |
| 报 `vim/loader … ENOENT … .cache/nvim/luac` | nvim 开着的时候 `~/.cache/nvim` 被删了；重开 nvim 即可 |
| 图标显示成方块 | 终端字体不是 Nerd Font |
| LSP 没反应 | 胶囊里有没有服务名；`:checkhealth vim.lsp`；`:lsp restart` |
| 没有语法高亮 | 解析器没装，`:TSInstall 语言名` |
| 大文件没有语法高亮、不能自动折叠 | 超过 1 MB 的文件故意不开 treesitter；阈值是 `code.lua` 里的 `BIG_FILE` |

## 许可

[GPL-3.0](LICENSE)
