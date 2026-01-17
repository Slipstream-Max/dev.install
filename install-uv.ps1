<#
.SYNOPSIS
    uv 安装脚本

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\uv）

.PARAMETER CacheDir
    缓存目录

.PARAMETER PythonDir
    Python 安装目录
#>
param(
    [string]$InstallDir = "D:\Programs\uv",
    [string]$CacheDir,
    [string]$PythonDir
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "uv"
$DownloadBaseUrl = "https://github.com/astral-sh/uv/releases/latest/download"

# 检测架构
$Arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'aarch64' } else { 'x86_64' }
} else { 'i686' }

$ZipName = "uv-$Arch-pc-windows-msvc.zip"
$DownloadUrl = "$DownloadBaseUrl/$ZipName"

# 默认路径
if (-not $CacheDir) { $CacheDir = Join-Path $InstallDir "cache" }
if (-not $PythonDir) { $PythonDir = Join-Path $InstallDir "python" }

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
Write-Host "[1/4] 准备安装目录..."
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 2. 下载
Write-Host "[2/4] 下载 $ZipName..."
$TempZip = Join-Path $env:TEMP $ZipName
try {
    Download-File -Url $DownloadUrl -OutFile $TempZip
    Write-Host "  下载完成" -ForegroundColor Green
} catch {
    Write-Error "下载失败: $_"
    exit 1
}

# 3. 解压
Write-Host "[3/4] 解压文件..."
try {
    Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force
    
    # 处理嵌套目录
    $items = Get-ChildItem -Path $InstallDir
    if ($items.Count -eq 1 -and $items[0].PSIsContainer) {
        $subDir = $items[0].FullName
        Get-ChildItem -Path $subDir | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $InstallDir -Force
        }
        Remove-Item -Path $subDir -Force
    }
    
    # 清理临时文件
    Remove-Item -Path $TempZip -Force
    Write-Host "  解压完成" -ForegroundColor Green
} catch {
    Write-Error "解压失败: $_"
    exit 1
}

# 4. 设置环境变量
Write-Host "[4/4] 配置环境变量..."
Set-EnvVar -Name "UV_CACHE_DIR" -Value $CacheDir
Set-EnvVar -Name "UV_PYTHON_INSTALL_DIR" -Value $PythonDir
Add-PathSafely -NewPath $InstallDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "请重新打开终端以使用 uv 命令" -ForegroundColor Yellow
