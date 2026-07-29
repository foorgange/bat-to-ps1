# bat-to-ps1 / bat-run Skills

> **项目背景：Windows .bat 文件双击无法执行的诊断与曲线救国方案**

---

## 背景

### 问题现象

我的 Windows 11 电脑上，双击 `.bat` 文件会出现以下异常：
- 终端窗口弹出，但**不执行任何逻辑**
- 窗口显示 PowerShell 提示符（Oh My Posh 主题），而不是 cmd.exe
- 等效的 `.ps1` 文件可以正常双击执行

### 硬件/软件环境

| 项目 | 详情 |
|------|------|
| OS | Windows 11 Home China 10.0.26200 |
| 终端 | Windows Terminal 1.24 + Oh My Posh |
| 安全软件 | 未知（文件 ACL 含 `CodexSandboxUsers` 组） |
| PowerShell | 5.1 / 7.x |
| 现象 | .bat 双击 → PowerShell 窗口弹出，无执行 |

---

## 诊断过程（2026-07-29，通过 Claude Code）

### 尝试 1：检查并修复文件类型关联（ftype）

**发现**：`ftype batfile` 显示 `"%1" %*`（损坏状态），缺少 `cmd.exe` 调用路径。

**修复**：
```cmd
ftype batfile="%SystemRoot%\System32\cmd.exe" /c "%1" %*
```

**结果**：❌ 注册表值中出现了多余的反斜杠转义符（`\"`），导致 Windows ShellExecute 尝试执行字面量路径 `\"C:\WINDOWS\...\cmd.exe\"`，报错「Windows 无法访问指定设备、路径或文件」。

**教训**：在 Git Bash（MSYS）环境中执行 `ftype` 命令会触发路径转换，破坏注册表值。

### 尝试 2：通过 PowerShell 直接写入注册表

**修复**：用 `Set-ItemProperty` 写入正确的值（不带转义反斜杠），验证注册表字节确认无误。

**结果**：❌ 注册表值正确，但双击仍弹出 PowerShell 窗口，不执行 bat 逻辑。

### 尝试 3：排查所有可能的注册表覆盖

检查清单：
- [x] `HKCU\Software\Classes\.bat` — 无覆盖
- [x] `HKCU\Software\Classes\batfile` — 无覆盖
- [x] `HKCR\.bat\shell\open\command` — 无直接覆盖
- [x] `Explorer\FileExts\.bat\UserChoice` — 无哈希锁定
- [x] `Image File Execution Options\cmd.exe` — 无劫持
- [x] `App Paths\cmd.exe` — 无重定向
- [x] `Command Processor\AutoRun` — 无异常
- [x] `batfile\shellex` — 无异常扩展
- [x] `%ComSpec%` — 正常指向 `cmd.exe`
- [x] `%PATHEXT%` — 正常包含 `.BAT;.CMD`
- [x] AppLocker — 不可用（Windows Home）
- [x] SRP (Software Restriction Policies) — 无限制规则

**结果**：❌ 所有注册表项均正常，未找到原因。

### 尝试 4：ShellExecute vs 直接调用测试

| 测试方式 | 结果 |
|----------|------|
| `cmd.exe /c test_bat.bat` | ✅ 正常 |
| `Start-Process test_bat.bat` | ✅ 正常 |
| `explorer.exe test_bat.bat` | ✅ 正常 |
| **双击 test_bat.bat** | ❌ 弹出 PowerShell，不执行 |

**关键发现**：只有通过 Windows Explorer GUI 双击时才出问题，程序化调用一切正常。推测存在 Explorer 进程级钩子（可能与 `CodexSandboxUsers` 安全软件相关）。

### 尝试 5：通过 PowerShell 包装器路由

**方案**：修改 `batfile` 注册表关联 → PowerShell 包装器 → `cmd.exe /c`

- V1：`Start-Process -NoNewWindow` → ❌ cmd.exe 输出不可见
- V2：直接 `cmd.exe /c` → ❌ 双击时输出仍不可见
- V3：`Start-Process -WindowStyle Normal`（独立窗口）+ PowerShell 隐藏 → ❌ 用户反馈无效

**结果**：❌ 无论如何包装，双击行为始终异常。

### 尝试 6：放弃修复，采用曲线救国方案

**最终决定**：不再尝试修复 Windows 系统级问题（根因可能在内核驱动/安全软件层面），改为创建一个可用性工具。

**方案**：创建 Claude Code skill，用户可以通过 `/bat2ps1` 和 `/bat-run` 命令，将任意 `.bat` 文件转换为等效的 `.ps1` 包装脚本。

---

## 等效性设计

### 核心原理

`.ps1` 包装器不转换 BAT 语法，而是**通过 `cmd.exe /c` 在正确的工作目录下执行原始 .bat 文件**。这保证了 100% 的等效性，无论原始 .bat 有多复杂。

### 等效性保证

| 方面 | 处理方式 |
|------|---------|
| 工作目录 | `Push-Location` 到脚本所在目录（模拟双击） |
| 执行引擎 | `cmd.exe /c` 执行原始 .bat |
| 参数传递 | 通过 `-BatArgs` 转发给 .bat |
| 退出代码 | 捕获 `%ERRORLEVEL%` 并传递 |
| 管理员权限 | 自动检测并通过 `Start-Process -Verb RunAs` 提升 |
| 路径空格 | 所有路径引用使用双引号 |
| 编码问题 | 检测并处理 UTF-8 BOM / UTF-16 |

### 局限性

- .bat 中通过 `set` 设置的环境变量在 cmd.exe 退出后不保留（对一次性部署脚本无影响）
- 如果 .bat 依赖 `call` 命令链式调用其他 .bat，包装器需要确保依赖文件可访问

---

## 文件结构

```
~/.claude/skills/
├── bat2ps1.md            # /bat2ps1 — 创建等效 .ps1 包装器
├── bat-run.md             # /bat-run  — 创建 + 测试 + 自动修复
└── bat-to-ps1-README.md  # 本文件
```

---

## 使用方法

```bash
# 仅为 setup.bat 创建包装器 setup_runner.ps1
/bat2ps1 C:\project\setup.bat

# 创建包装器 + 自动测试 + 失败修复
/bat-run C:\project\setup.bat
```

---

## 结论

经过 6 轮诊断和修复尝试，确认问题根因不在用户态注册表配置，而在更深层（可能的安全软件驱动/Explorer 钩子）。在无法进一步排查的情况下，通过 `/bat2ps1` 和 `/bat-run` 两个 skill 提供了实用的曲线救国方案。由于 .ps1 文件在该机器上可以正常双击执行，用户只需用这个工具将 .bat 转为 .ps1 包装器即可。
