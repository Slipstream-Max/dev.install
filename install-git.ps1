<#
.SYNOPSIS
    Git for Windows 安装脚本

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\Git）
#>
param(
    [string]$InstallDir = "D:\Programs\Git"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "Git for Windows"
$RepoUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"

# 1. 动态获取最新版本号
Write-Host "[1/4] 正在获取最新版本信息..."
try {
    $LatestRelease = Invoke-RestMethod -Uri $RepoUrl
    $Tag = $LatestRelease.tag_name # 例如 v2.52.0.windows.1
    $Version = $Tag.TrimStart('v') # 2.52.0.windows.1
    # 提取纯版本号用于文件名 (例如 2.52.0)
    $PureVersion = $Version -split '\.windows' | Select-Object -First 1
} catch {
    Write-Error "获取最新版本失败: $_"
    exit 1
}

# 2. 检测架构并确定下载 URL
$Arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { "arm64" } else { "64-bit" }
} else {
    Write-Error "不支持 32 位系统"
    exit 1
}

$ExeName = "Git-$PureVersion-$Arch.exe"
$DownloadUrl = "https://github.com/git-for-windows/git/releases/latest/download/$ExeName"

# ============ 引入工具函数 ============
if (Test-Path "$PSScriptRoot\utils.ps1") {
    . "$PSScriptRoot\utils.ps1"
}

# ============ 主流程 ============
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  安装 $AppName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 创建安装目录
Write-Host "[1/3] 准备安装目录..."
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 2. 下载
Write-Host "[2/3] 下载 $AppName ($Arch)..."
$TempExe = Join-Path $env:TEMP $ExeName

try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempExe -ErrorAction Stop
    Write-Host "  下载完成" -ForegroundColor Green
} catch {
    Write-Error "下载失败: $_"
    exit 1
}

# 3. 运行安装程序
Write-Host "[3/3] 运行安装程序..."
try {
    # Git 安装程序的静默参数：
    # /VERYSILENT: 完全静默
    # /NORESTART: 不重启
    # /DIR: 指定目录
    # /NoAutoPath: 虽然你要统一管理，但 Git 的 /Group 参数等较复杂，
    # 这里我们还是让它装到指定目录，最后由脚本确认 Path。
    $ArgList = "/VERYSILENT", "/NORESTART", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS", "/DIR=`"$InstallDir`""
    
    Write-Host "  等待安装完成..."
    $process = Start-Process -FilePath $TempExe -ArgumentList $ArgList -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "  安装完成" -ForegroundColor Green
    } else {
        Write-Warning "安装程序退出码: $($process.ExitCode)"
    }
    
    # 清理临时文件
    Remove-Item -Path $TempExe -Force -ErrorAction SilentlyContinue
} catch {
    Write-Error "安装失败: $_"
    exit 1
}

# 4. 添加到 PATH
$BinPath = Join-Path $InstallDir "cmd" # 官方推荐添加 cmd 目录，它包含了 git.exe
if (Test-Path $BinPath) {
    Add-PathSafely -NewPath $BinPath
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "版本: $Version"
Write-Host "文件夹: $InstallDir"
Write-Host "请重新打开终端以使用 'git' 命令" -ForegroundColor Yellow
