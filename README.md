# nvim.setting

一套给 **Neovim 0.12+** 的个人配置：17 个插件，每个只做一件事，没有打包型插件；全部配置是 9 个 Lua 文件。

- **没有下巴**：没有状态栏、没有命令行那一行、没有标签栏，屏幕上下都是代码。
- **全浮动**：状态信息在每个窗口右上角的胶囊里；按 `:` 时命令行在屏幕中上方浮出；通知是右上角的小卡片；普通消息在右下角出现几秒后消失。
- **Catppuccin 配色**：只用 Mocha。
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

macOS 用 Homebrew 装（含可选的 zoxide，字体另装）：

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
| `<leader>u` | 撤销历史树，可以回到任意一次修改 |
| `<leader>fk` | 忘了按键时搜索所有快捷键 |

## 界面

**右上角的胶囊**（每个窗口一个），从左到右：

1. 模式色块（`NOR` `INS` `VIS` `CMD`…），颜色随模式变。
2. 正在发生的事：录制宏（`@a`）、选区大小、搜索位置（`2/6`），只在发生时出现。
3. 诊断数量：错误、警告、提示。
4. Git 改动行数：新增、修改、删除。
5. 分支名、正在生效的语言服务名（如 `clangd`）。
6. 最右边永远是图标和文件名；未保存时文件名变色并带 `●`；两个打开的文件同名时前面带上级目录。

其他窗口的胶囊只有图标和文件名，颜色压暗。窗口第一行文字较长时，胶囊从右往左依次省略语言服务、分支、Git、诊断，只留模式和文件名；还放不下、光标又在第一行时，整个隐藏。

**命令行**：按 `:` 或 `/` 时在屏幕中上方浮出一个圆角小窗，补全菜单跟在它下面。只有"保存吗？是 / 否 / 取消"这类确认留在底部。

**通知**：右上角的圆角卡片，排在胶囊下面，多条往下叠，几秒后消失；警告和错误的边框带颜色。语言服务加载项目的进度是一张原地更新的卡片。

**消息**：`:echo` 之类出现在右下角。输出很长时（比如 `:map`）在底部展开，`[+95]` 表示还有 95 行，`g<` 看全部、`q` 关闭。

**启动页**：不带文件打开 nvim 时出现，一个慢慢转动的星系，菜单在左上方。按菜单项右边的字母直接执行，或 `j` / `k` 移动后按 `Enter`。

- 画好的帧缓存在 `~/.cache/nvim/dashboard-frames.txt`。输命令、终端失去焦点时停转，离开启动页后不占 CPU。
- 不想要动画：`dashboard.lua` 顶部 `ANIMATE = false`。窗口小于 96×26 时只显示菜单。

**行号列**：行号右边的细条是 Git 修改（绿 新增 / 黄 修改 / 红 删除）。只有当前窗口显示相对行号。上下分屏之间的横线就是分隔线。

**看不见的字符**：Tab 显示成 `»`，行尾多余的空格显示成 `·`，混进来一眼就能看到。Go 和 Makefile 规定用 Tab 缩进，那里的 Tab 不显示。

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

搜索窗口是 Telescope 的版式，底下跑的是 fzf。窗口里 `Ctrl-d` / `Ctrl-u` 滚动预览，`Ctrl-v` / `Ctrl-x` / `Ctrl-t` 在左右分屏 / 上下分屏 / 新标签页里打开，`Ctrl-q` 把全部结果送进 quickfix。**例外**：已打开文件的列表（`<leader><leader>`）里，`Ctrl-d` 是关闭选中的文件。

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
| `<leader>gd` | 并排对比这个文件还没暂存的改动 |
| `ih`（配合 `d` `v` `y`） | 光标所在的这一块修改：`dih` 删掉、`vih` 选中、`yih` 复制 |

### 跳转和编辑

| 按键 | 作用 |
| --- | --- |
| `s` | 屏幕上快速跳转：输入几个字符，再按提示的字母 |
| `S`（选中后用 `R`） | 按代码结构选中一块 |
| `ys{范围}{符号}` | 加包围符号：`ysiw)` 给单词加括号，`yss"` 给整行加引号 |
| `cs{旧}{新}` / `ds{符号}` | 换 / 删包围符号 |
| `S{符号}`（选中后） | 给选区加包围符号 |
| `j` / `k` | 折行的文件里按屏幕上看到的行走；带数字（`5j`）时按真实行走 |
| `Ctrl-o` / `Ctrl-i` | 跳转历史的后退 / 前进，像浏览器；回去时连滚动位置一起恢复 |
| `n` / `N` | 下一个 / 上一个搜索结果，居中 |
| `Ctrl-d` / `Ctrl-u` | 平滑翻半页 |
| `<` / `>`（选中后） | 缩进，选区不丢 |
| `J` / `K`（选中后） | 把选中的几行下移 / 上移 |
| `<leader>p`（选中后） | 粘贴覆盖选区，被覆盖的文字不进剪贴板 |
| `<leader>u` | 打开 / 关闭撤销历史树 |
| `Esc` | 清除搜索高亮 |

**撤销历史树**：撤销几步后又改了别的，原来那条路线用 `u` / `Ctrl-r` 就回不去了。`<leader>u` 在右边把所有分叉列成一棵树，在树里移动，文件就变成那个时刻的样子。历史存在磁盘上，重开文件也在。

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
| Lua | lua-language-server | `/opt/homebrew/bin/lua-language-server` |

- **改这份配置时最有用的是 Lua**：认识 `vim.*` 的全部接口，有补全、文档和报错；`<leader>lf` 格式化成 4 格空格、不对齐注释（风格在 `code.lua` 的 `lua_ls` → `format`）。
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
| [catppuccin/nvim](https://github.com/catppuccin/nvim) | 配色 |
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

另外用了 Neovim 自带的 `nvim.undotree`（撤销历史树），不用下载，也不在 `nvim-pack-lock.json` 里。

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

### 让代码文件也折行

默认只有 markdown、纯文本、typst 折行，代码不折行。**一般不建议给代码开**：一行逻辑会被拆成好几行显示，缩进结构反而难看清；代码行宽本来也有格式化工具管着。

**偶尔遇到一行特别长**，临时打开就够了，再输一次关掉，只影响当前窗口：

```vim
:set wrap!
```

**真想让代码一直折行**，改 `options.lua`「分屏和搜索」那段，然后 `:restart`：

```lua
opt.wrap = true -- 原来是 false
opt.linebreak = true -- 新加：在单词之间折，不把单词劈开
```

改完后「Markdown / 文本」那段自动命令就多余了，可以删掉。其余都已经处理好，不用动：`j` / `k` 按屏幕行走（带数字时按真实行），折出来的行接着原缩进对齐（`breakindent`），行号列也不会错位。

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
| 长行右边被截掉，只能左右拖 | 代码文件默认不折行。`:set wrap!` 临时开关，`zL` / `zH` 左右翻半屏；一直折行见[让代码文件也折行](#让代码文件也折行) |

## 许可

[GPL-3.0](LICENSE)
