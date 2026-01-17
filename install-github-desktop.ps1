<#
.SYNOPSIS
    GitHub Desktop 安装脚本

.DESCRIPTION
    使用 .exe 安装程序（per-user 安装，自动安装到用户目录）
#>

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "GitHub Desktop"
$RepoUrl = "https://api.github.com/repos/desktop/desktop/releases/latest"

# 1. 动态获取最新版本号
Write-Host "[1/4] 正在获取最新版本信息..."
try {
    $LatestRelease = Invoke-RestMethod -Uri $RepoUrl
    $Tag = $LatestRelease.tag_name # 例如 release-3.5.5 或 release-3.5.5-beta1
    $Version = $Tag -replace '^release-', '' # 3.5.5 或 3.5.5-beta1
    Write-Host "  最新版本: $Version" -ForegroundColor Green
} catch {
    Write-Error "获取最新版本失败: $_"
    exit 1
}

# 2. 检测架构并确定下载 URL
$Arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { "arm64" } else { "x64" }
} else {
    Write-Error "不支持 32 位系统"
    exit 1
}

$ExeName = "GitHubDesktopSetup-$Arch.exe"
$DownloadUrl = "https://github.com/desktop/desktop/releases/download/$Tag/$ExeName"

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

# 1. 下载
Write-Host "[2/4] 下载 $AppName ($Arch)..."
$TempExe = Join-Path $env:TEMP $ExeName

try {
    Download-File -Url $DownloadUrl -OutFile $TempExe
    Write-Host "  下载完成" -ForegroundColor Green
} catch {
    Write-Error "下载失败: $_"
    exit 1
}

# 2. 运行安装程序
Write-Host "[3/4] 运行安装程序..."
try {
    # GitHub Desktop .exe 安装程序会自动处理安装
    # 它是 per-user 安装，会安装到 %LOCALAPPDATA%\GitHubDesktop
    Write-Host "  等待安装完成..."
    $process = Start-Process -FilePath $TempExe -ArgumentList "--silent" -Wait -PassThru
    
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

# 3. 检查安装结果
Write-Host "[4/4] 验证安装..."
$InstallDir = Join-Path $env:LOCALAPPDATA "GitHubDesktop"
if (Test-Path $InstallDir) {
    Write-Host "  安装验证成功" -ForegroundColor Green
} else {
    Write-Host "  注意: 安装目录未找到，可能需要重新登录" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "版本: $Version"
Write-Host "架构: $Arch"
Write-Host "安装目录: $InstallDir"
Write-Host "GitHub Desktop 已添加到开始菜单" -ForegroundColor Yellow
