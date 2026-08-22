# bat-to-ps1

**Claude Code skills for running `.bat` files via `.ps1` wrappers on Windows.**

**通过 `.ps1` 包装器在 Windows 上运行 `.bat` 文件的 Claude Code 技能。**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Claude%20Code-blue)]()

---

## Table of Contents / 目录

- [The Problem / 问题描述](#the-problem--问题描述)
- [Diagnosis History / 诊断历史](#diagnosis-history--诊断历史)
- [Why This Exists / 项目定位](#why-this-exists--项目定位)
- [The Solution / 解决方案](#the-solution--解决方案)
- [Skills / 技能说明](#skills--技能说明)
- [Installation / 安装](#installation--安装)
- [Generated Wrapper Example / 生成的包装器示例](#generated-wrapper-example--生成的包装器示例)
- [Equivalence Guarantee / 等效性保证](#equivalence-guarantee--等效性保证)
- [Environment / 环境信息](#environment--环境信息)
- [FAQ](#faq)
- [License](#license)

---

## The Problem / 问题描述

### English

On some Windows 11 machines, **running a `.bat` file does nothing useful** — regardless of how you try. The behavior is bizarre:

1. A terminal window pops up ✅
2. But instead of cmd.exe executing the script, **PowerShell opens with an interactive prompt** ❌
3. The `.bat` file's commands are **never executed** ❌
4. This happens **whether you double-click the file OR run `cmd /c` from the command line** ❌
5. Meanwhile, `.ps1` files work normally ✅

This is especially frustrating when:

- Cloning someone else's project that provides a `setup.bat` / `start.bat` / `run.bat`
- Needing to run legacy `.bat` scripts for deployments or automation
- Working in development environments where `.bat` is the standard one-click launcher

### 中文

在某些 Windows 11 电脑上，**运行 `.bat` 文件没有任何反应**——无论你用什么方式。具体表现为：

1. 弹出了一个终端窗口 ✅
2. 但出来的不是 cmd.exe，而是 **PowerShell 的交互式提示符** ❌
3. `.bat` 文件里的命令**完全没有被执行** ❌
4. **不管是双击文件，还是通过 `cmd /c` 命令行执行，结果都一样** ❌
5. 与此同时，`.ps1` 文件却能正常运行 ✅

这在你遇到以下场景时特别让人抓狂：

- 拉到别人的项目，根目录有个 `setup.bat` / `start.bat` 一键脚本，结果自己用不了
- 需要运行传统的 `.bat` 部署脚本
- 开发环境中 `.bat` 是标配的启动方式，但你的电脑不买账

---

## Diagnosis History / 诊断历史

> 以下是使用 Claude Code 在 2026-07-29 对该问题进行的**完整诊断记录**。如果你也遇到了同样的问题，这些尝试结果可以作为参考，避免重复踩坑。
>
> **重要说明**：以下所有尝试（Round 1–5），无论采取何种修复方式，最终结果完全一致——**无论是双击 `.bat` 文件，还是通过 `cmd /c` 等命令行方式执行，全部都是什么都不执行**，没有出现过任何"部分解决"或"仅命令行可用"的中间状态。最终不得不采用曲线救国方案。

### Round 1 / 第一轮：文件类型关联 (ftype) 损坏检查

| 检查项 | 结果 |
|--------|------|
| `assoc .bat` | `batfile` ✅ 正常 |
| `ftype batfile` | `"%1" %*` ❌ **损坏！缺少 cmd.exe 路径** |

**尝试修复**：`ftype batfile="%SystemRoot%\System32\cmd.exe" /c "%1" %*`

**结果**：❌ 由于在 Git Bash (MSYS) 环境中执行，路径转换机制将 `"` 转义成了 `\"`，导致注册表中存储了字面量的反斜杠。Windows ShellExecute 尝试执行字面量路径 `\"C:\WINDOWS\...\cmd.exe\"`，报错「Windows 无法访问指定设备、路径或文件」。**修复后注册表值已正确，但双击和 `cmd /c` 执行 .bat 仍然什么都不执行。**

**教训**：绝不要在 Git Bash 中执行 `ftype` 命令来修改 Windows 文件关联。

---

### Round 2 / 第二轮：通过 PowerShell 直接写入注册表

**尝试修复**：使用 `Set-ItemProperty` 写入正确的值，逐字节验证注册表内容，确认无多余反斜杠。

**结果**：❌ 注册表值完全正确，但行为完全不变——无论是双击还是 `cmd /c` 执行 .bat，仍然弹出 PowerShell，不执行任何 bat 逻辑。

---

### Round 3 / 第三轮：全面排查注册表覆盖项

检查了所有可能影响 `.bat` 文件执行的注册表位置：

| 检查项 | 结果 |
|--------|------|
| `HKCU\Software\Classes\.bat` | 无覆盖 ✅ |
| `HKCU\Software\Classes\batfile` | 无覆盖 ✅ |
| `HKCR\.bat\shell\open\command`（直接） | 不存在 ✅ |
| `Explorer\FileExts\.bat\UserChoice` | 无哈希锁定 ✅ |
| `Explorer\FileExts\.bat\OpenWithProgids` | 仅 `batfile` ✅ |
| `Image File Execution Options\cmd.exe` | 不存在 ✅ |
| `App Paths\cmd.exe` | 不存在 ✅ |
| `Command Processor\AutoRun` (HKCU & HKLM) | 无异常 ✅ |
| `batfile\shellex` 上下文菜单扩展 | 无劫持 ✅ |
| `%ComSpec%` | `C:\WINDOWS\system32\cmd.exe` ✅ |
| `%PATHEXT%` | 包含 `.BAT;.CMD` ✅ |
| AppLocker | Windows Home 不可用 — |
| SRP (Software Restriction Policies) | 无限规则 ✅ |
| Windows Terminal 委托设置 | 全零 GUID（未委托） ✅ |

**结果**：❌ **所有能检查的注册表和策略项全部正常**，但无论是双击还是 `cmd /c` 执行 .bat，依然什么都不执行。

---

### Round 4 / 第四轮：确认各种执行方式的表现

| 测试方式 | 结果 |
|----------|------|
| `cmd.exe /c test.bat`（命令行） | ❌ 弹出 PowerShell，不执行 |
| `powershell Start-Process test.bat` | ❌ 弹出 PowerShell，不执行 |
| `explorer.exe test.bat`（模拟双击） | ❌ 弹出 PowerShell，不执行 |
| `rundll32` ShellExecute | ❌ 弹出 PowerShell，不执行 |
| **Explorer GUI 双击** | ❌ 弹出 PowerShell，不执行 |

**关键发现**：**无论通过何种方式触发 `.bat` 文件执行，结果完全一致——一律弹出 PowerShell 交互式提示符，bat 脚本内容不执行。** 这说明问题不在用户态的注册表或文件关联，而在更深层的系统钩子——所有通向 cmd.exe 的路径都被拦截了。

---

### Round 5 / 第五轮：尝试 PowerShell 包装器绕路

**思路**：既然常规修复完全无效，尝试修改 `batfile` 注册表关联，让双击 .bat 时先启动 PowerShell，再由 PowerShell 调用 cmd.exe。

| 版本 | 方案 | 结果 |
|------|------|------|
| V1 | `Start-Process cmd.exe -NoNewWindow` | ❌ 双击和命令行执行均无输出 |
| V2 | 直接 `cmd.exe /c` | ❌ 双击和命令行执行均无输出 |
| V3 | `Start-Process -WindowStyle Normal`（独立窗口） | ❌ 双击和命令行执行均无输出 |

**结果**：❌ 无论如何包装，通过任何方式触发执行，PowerShell 都无法正常调用 cmd.exe 来运行 bat 脚本。问题比预想的更深层。

---

### Round 6 / 第六轮：放弃修复 — 不得不曲线救国

**最终判断**：经过 5 轮尝试，所有修复手段全部无效——无论是双击还是命令行执行 .bat 文件，结果都是什么都不执行。问题根因不在用户可配置的层面，可能在以下某一层：
- 内核驱动级安全软件（文件 ACL 含 `CodexSandboxUsers` 组）
- 系统级 ShellExecute 钩子
- 其他安全产品注入的 DLL

**由于无法从根本上修复，不得不采用替代方案**：创建 Claude Code skill，将 `.bat` 转为 `.ps1` 包装器。核心思路是利用 .ps1 可以正常执行的特点，在 .ps1 中通过 `cmd.exe /c` 调用原始 .bat 文件，绕开系统对 .bat 文件启动的拦截。

---

## Why This Exists / 项目定位

### English

This is a **personal project** created to solve a real, frustrating problem I encountered on my own machine. After exhausting every reasonable diagnostic avenue (see above) — and finding that **both double-clicking AND `cmd /c` command-line execution resulted in the same outcome (nothing executes)** — I accepted that a system-level fix was not feasible and built a pragmatic workaround.

If you've also experienced `.bat` files mysteriously refusing to run on your Windows machine, and none of the usual fixes (file associations, registry checks, `ftype`, `assoc`, etc.) helped — this project is for you. It won't fix your system, but it **will** let you run those `.bat` files.

### 中文

这是一个**自用项目**，为了解决我自己电脑上一个真实且令人抓狂的问题。在尝试了所有合理的诊断方法（见上文）均告失败后——**无论是双击还是 `cmd /c` 命令行执行，结果统统是什么都不执行**——我选择接受现实，用一个实用的曲线救国方案绕过系统层面的问题。

如果你也遇到过 `.bat` 文件莫名其妙无法运行的情况，且常规修复手段（文件关联、注册表、`ftype`、`assoc` 等）全部无效——那这个项目就是为你准备的。它不会修复你的系统，但它**能让你用上那些 `.bat` 文件**。

---

## The Solution / 解决方案

### Core Idea / 核心思路

Since `.ps1` files work when double-clicked on affected machines, this project provides **Claude Code skills** that automatically create a `.ps1` **wrapper script** next to any `.bat` file.

The wrapper does **NOT** attempt to convert BAT syntax to PowerShell. Instead, it simply:

1. `Push-Location` to the `.bat` file's directory (mimicking double-click behavior)
2. Calls `cmd.exe /c` on the **original** `.bat` file
3. Passes through the exit code
4. Cleans up with `Pop-Location`

### Why This Guarantees Equivalence / 为什么这保证了等效性

Because `cmd.exe /c` is the **exact same engine** that normally executes `.bat` files, the wrapper is 100% behaviorally equivalent — `goto`, `setlocal`, `call`, `errorlevel`, conditional branches, nested scripts… everything works. The wrapper is just a delivery mechanism that bypasses whatever is intercepting `.bat` file launches on your system.

### Visual / 流程示意

```
尝试运行 .bat 文件 → ❌ PowerShell 弹出，脚本不执行
  (无论双击、cmd /c、Start-Process 等任何方式)

运行 _runner.ps1  → ✅ PowerShell 弹出
                    → cmd.exe /c original.bat
                    → 正常执行所有命令
                    → 退出代码正确返回
```

---

## Skills / 技能说明

### `/bat2ps1` — Create Wrapper / 创建包装器

| | |
|---|---|
| **用途** | 在 `.bat` 同级目录创建 `_runner.ps1` 包装器 |
| **命令** | `/bat2ps1 <path-to-bat-file>` |
| **行为** | 读取 .bat，分析需求（管理员权限/参数/编码），生成包装器 |

```
/bat2ps1 C:\project\setup.bat
# → 创建 C:\project\setup_runner.ps1
```

生成的包装器自动处理以下场景：

| 场景 | 处理方式 |
|------|---------|
| 普通执行 | `Push-Location` + `cmd.exe /c` |
| 需要管理员权限 | 自动检测 `net`/`sc`/`reg add`/`bcdedit` 等命令，添加自提升代码 |
| 接受命令行参数 | 通过 `-BatArgs` 参数转发 |
| 路径含空格 | 所有路径用双引号包裹 |
| 退出代码 | 捕获 `$LASTEXITCODE` 并 `exit` |
| 编码异常 | 检测 UTF-8 BOM / UTF-16，必要时转换 |

### `/bat-run` — Create + Test + Fix / 创建 + 测试 + 修复

| | |
|---|---|
| **用途** | 创建包装器 + 执行测试 + 失败自动修复 |
| **命令** | `/bat-run <path-to-bat-file>` |
| **行为** | 若包装器不存在则创建；执行并观察输出；出错则分析并修复（最多 3 次） |

```
/bat-run C:\project\setup.bat
# → 创建 setup_runner.ps1 (如果不存在)
# → 执行测试
# → 出错则自动分析、修复、重试 (最多 3 轮)
# → 如果已有包装器，只执行测试步骤
```

**修复策略**：

| 第 N 次重试 | 策略 |
|-------------|------|
| 第 1 次 | 基础修复：路径引号、编码转换 |
| 第 2 次 | 深度分析：逐行读取 .bat，检查特殊语法 |
| 第 3 次 | 若仍失败，报告具体错误 + 手动修复建议 |

---

## Installation / 安装

### One-liner / 一行安装 (Windows PowerShell)

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/foorgange/bat-to-ps1/main/install.ps1" | Invoke-Expression
```

### Manual / 手动安装

```bash
git clone https://github.com/foorgange/bat-to-ps1.git
cd bat-to-ps1

# Windows
powershell -ExecutionPolicy Bypass -File install.ps1

# macOS / Linux
bash install.sh
```

安装脚本会将 skill 文件复制到 `~/.claude/skills/`。

### Verify / 验证

重启 Claude Code，然后：

```
/bat2ps1 C:\path\to\any\file.bat
```

---

## Generated Wrapper Example / 生成的包装器示例

输入 `/bat2ps1 C:\my-project\setup.bat` 后，生成的 `setup_runner.ps1`：

```powershell
<#
.SYNOPSIS
    Wrapper for setup.bat — runs via cmd.exe
    Automatically generated by /bat2ps1
#>
[CmdletBinding()]
param(
    [string[]]$BatArgs = @()
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BatPath = Join-Path $ScriptDir "setup.bat"

if (-not (Test-Path $BatPath)) {
    Write-Error "Cannot find: $BatPath"
    if ($Host.Name -eq 'ConsoleHost') { pause }
    exit 1
}

Push-Location $ScriptDir
try {
    Write-Host "Executing: $BatPath" -ForegroundColor Cyan
    Write-Host ("=" * 60)

    $exitCode = 0
    if ($BatArgs.Count -gt 0) {
        $argStr = ($BatArgs | ForEach-Object { "`"$_`"" }) -join ' '
        cmd.exe /c "`"$BatPath`" $argStr"
        $exitCode = $LASTEXITCODE
    } else {
        cmd.exe /c "`"$BatPath`""
        $exitCode = $LASTEXITCODE
    }

    Write-Host ("=" * 60)
    if ($exitCode -eq 0) {
        Write-Host "[OK] Exit code: 0" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Exit code: $exitCode" -ForegroundColor Yellow
    }
    exit $exitCode
} finally {
    Pop-Location
}
```

---

## Equivalence Guarantee / 等效性保证

### What IS preserved / 保证保留的

| 方面 | 说明 |
|------|------|
| **工作目录** | `Push-Location` 到脚本所在目录，与双击行为完全一致 |
| **执行引擎** | 始终通过 `cmd.exe /c` 执行原始 `.bat`，100% 兼容 |
| **退出代码** | `$LASTEXITCODE` 正确捕获 `%ERRORLEVEL%` |
| **参数传递** | 通过 `-BatArgs` 转发，空格安全 |
| **管理员权限** | 自动检测需要提权的命令（`net`/`sc`/`reg add`/`bcdedit` 等） |
| **路径空格** | 所有路径引用均使用双引号包裹 |
| **`goto` / `call` / `setlocal`** | 完全兼容 — 因为运行的是原始 .bat |

### What is NOT preserved / 已知局限

| 方面 | 说明 |
|------|------|
| **环境变量持久化** | `.bat` 中通过 `set` 设置的环境变量在 `cmd.exe /c` 退出后不会保留到 PowerShell 会话。对一次性部署脚本（`npm install`、`python setup.py` 等）无影响 |
| **交互式 shell 延续** | 包装器执行完毕即退出。如果 `.bat` 设计为「设置环境变量后留在 shell 中继续操作」，则不适用 |

---

## Environment / 环境信息

以下是问题发现时的实际环境，供参考：

| 项目 | 详情 |
|------|------|
| **OS** | Windows 11 Home China 10.0.26200 |
| **终端** | Windows Terminal 1.24 + Oh My Posh |
| **现象** | .bat 无法执行（双击或 `cmd /c` 均弹出 PowerShell，不执行脚本） |
| **安全软件** | 推测存在（文件 ACL 含 `CodexSandboxUsers` 组） |
| **Claude Code** | Fable 5 / Opus 4.8 |
| **Git** | 2.47.0 |
| **诊断日期** | 2026-07-29 |

---

## FAQ

<details>
<summary><b>Q: Does this convert BAT syntax to PowerShell? / 这会转换 BAT 语法吗？</b></summary>

**A:** No. The wrapper calls `cmd.exe /c` on the original `.bat` file. This guarantees 100% equivalence — every BAT feature works because it's still cmd.exe doing the work.

**不转换。** 包装器用 `cmd.exe /c` 执行原始 .bat，保证 100% 等效——所有 BAT 语法都正常工作，因为执行引擎还是 cmd.exe。
</details>

<details>
<summary><b>Q: What about admin-requiring scripts? / 需要管理员权限的脚本怎么办？</b></summary>

**A:** The skill auto-detects commands like `net start`, `sc`, `reg add`, `bcdedit`, etc. and generates a self-elevating wrapper. You can also pass `-RunAsAdmin` to force elevation.

**自动检测** `net`、`sc`、`reg add`、`bcdedit` 等命令并生成自提升代码。也可手动传 `-RunAsAdmin` 强制提权。
</details>

<details>
<summary><b>Q: Can I double-click the generated .ps1 file? / 生成的 .ps1 能双击运行吗？</b></summary>

**A:** Yes! That's the whole point. On affected machines, `.ps1` double-click works while `.bat` doesn't.

**能！** 这就是这个项目的意义所在。在受影响的电脑上，双击 .ps1 正常而 .bat 不正常。
</details>

<details>
<summary><b>Q: I tried everything in the diagnosis list and still can't fix the root cause. What now? / 我也试了所有诊断方法，还是不行？</b></summary>

**A:** Welcome to the club. That's exactly why this project exists. Install the skill and move on with your life.

**欢迎入坑。** 这就是这个项目存在的理由。装上 skill，继续干活吧。
</details>

<details>
<summary><b>Q: Will this fix the underlying issue on my system? / 这能修复系统的根本问题吗？</b></summary>

**A:** No. This is a workaround, not a fix. The root cause (likely a security software kernel driver or Explorer hook) remains. But you'll be able to run `.bat` files again.

**不能。** 这是曲线救国，不是修复。根因（可能是安全软件驱动或 Explorer 钩子）依然存在。但你能重新用上 .bat 文件了。
</details>

---

## License

MIT © [lihe4](https://github.com/foorgange)

详见 [BACKGROUND.md](BACKGROUND.md) 了解完整的 6 轮诊断过程。

See [BACKGROUND.md](BACKGROUND.md) for the full 6-round diagnostic journey.
