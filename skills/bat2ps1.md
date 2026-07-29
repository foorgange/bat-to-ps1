---
name: bat2ps1
description: 为 .bat 文件创建等效的 .ps1 包装脚本。自动在同目录下生成，保证功能完全等效。
---

# /bat2ps1 — 将 .bat 转换为等效 .ps1 包装器

用户调用 `/bat2ps1 <path-to-bat-file>` 时，执行以下步骤：

## 步骤 1：读取并分析 .bat 文件

1. 用 Read 工具读取目标 .bat 文件
2. 分析关键特征：
   - 是否包含需要管理员权限的命令（如 `net`, `sc`, `reg add`, `bcdedit` 等）
   - 是否使用 `pause` 结尾
   - 是否接受命令行参数（`%1`, `%2`, `%*` 等）
   - 是否有特殊的 `setlocal` / `set` 环境变量设置
   - 工作目录依赖（`cd /d`, `pushd` 等）
   - 文件编码（是否为 UTF-8 BOM / UTF-16，cmd 需要 ANSI 或 UTF-8 without BOM）

## 步骤 2：创建 .ps1 包装器脚本

在 .bat 文件**同一目录**下创建 `<原名>_runner.ps1`，使用以下模板：

```powershell
<#
.SYNOPSIS
    Wrapper for <原文件名>.bat — runs via cmd.exe
    由 /bat2ps1 自动生成
#>
[CmdletBinding()]
param(
    [string[]]$BatArgs = @()
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BatPath = Join-Path $ScriptDir "<原文件名>.bat"

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

## 步骤 3：根据分析结果调整模板

### 3a. 检测到管理员权限需求
如果 .bat 中包含 `net stop/start`, `sc`, `reg add`, `bcdedit`, `diskpart` 等需要管理员权限的命令：
- 添加参数 `[switch]$RunAsAdmin`
- 在脚本开头添加自提升逻辑：
```powershell
if ($RunAsAdmin -or (
    $batContent -match 'net\s+(start|stop)' -or
    $batContent -match '\bsc\s' -or
    $batContent -match 'reg\s+add' -or
    $batContent -match '\bbcdedit\b' -or
    $batContent -match '\bdiskpart\b'
)) {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script requires Administrator privileges. Restarting..." -ForegroundColor Yellow
        Start-Sleep 1
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}
```

### 3b. 没有 `pause` 结尾
如果 .bat 文件以 `pause` 结尾，保留默认行为（cmd.exe /c 中的 pause 会正常等待按键）。
如果 .bat 文件没有 `pause` 且可能在执行完毕后立即退出，在 `exit $exitCode` 前添加暂停：
```powershell
if ($Host.Name -eq 'ConsoleHost' -and $MyInvocation.InvocationName -ne '') {
    Write-Host "`nPress any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
```

### 3c. 编码问题处理
如果 .bat 文件是 UTF-8 BOM 或 UTF-16 编码（cmd.exe 不能正确处理），在包装器中先转换为临时 ANSI 文件再执行，执行后清理。

## 步骤 4：报告结果

创建完成后，向用户报告：
1. ✅ 已创建 `<原名>_runner.ps1`
2. 📁 位置：与 .bat 同级目录
3. 🔧 等效性说明：通过 `cmd.exe /c` 在正确的目录下执行原始 .bat，保证完全等效
4. 💡 提示用户可以用 `/bat-run <path>` 立即测试

## 关键等效性保证

1. **工作目录**：`Push-Location` 到脚本所在目录，与双击 .bat 行为一致
2. **执行引擎**：始终通过 `cmd.exe /c` 执行，与双击行为一致
3. **参数传递**：支持通过 `-BatArgs` 传递参数给 .bat
4. **退出代码**：正确捕获并传递 `%ERRORLEVEL%`
5. **管理员权限**：自动检测并提升
6. **路径空格**：所有路径引用均使用双引号包裹，安全处理空格
