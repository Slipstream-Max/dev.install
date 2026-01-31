<#
.SYNOPSIS
    Node.js 安装脚本 (自动下载最新版)

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\nodejs）
#>
param(
    [string]$InstallDir = "D:\Programs\nodejs"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "Node.js"
$BaseUrl = "https://nodejs.org/download/release/latest/"

# 检测架构
$Arch = if ([Environment]::Is64BitOperatingSystem)
{
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
    { "arm64" 
    } else
    { "x64" 
    }
} else
{
    Write-Error "不支持 32 位系统"
    exit 1
}

# ============ 引入工具函数 ============
if (Test-Path "$PSScriptRoot\utils.ps1")
{
    . "$PSScriptRoot\utils.ps1"
}

# ============ 主流程 ============
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  安装 $AppName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try
{
    $HtmlContent = (Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing).Content
    $Pattern = "node-v[0-9.]+-win-$Arch\.zip"
    if ($HtmlContent -match "($Pattern)")
    {
        $ZipName = $matches[1]
        $DownloadUrl = "$BaseUrl$ZipName"
        Write-Host "  检测到最新版本: $ZipName" -ForegroundColor Green
    } else
    {
        throw "无法在页面中找到符合架构 ($Arch) 的 zip 文件链接"
    }
} catch
{
    Write-Error "获取版本信息失败: $_"
    exit 1
}

# 1. 准备安装目录
Write-Host "[1/4] 准备安装目录..."
if (-not (Test-Path $InstallDir))
{
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 2. 下载
Write-Host "[2/4] 下载 $ZipName..."
$TempZip = Join-Path $env:TEMP $ZipName
try
{
    Down-File -Url $DownloadUrl -OutFile $TempZip
    Write-Host "  下载完成" -ForegroundColor Green
} catch
{
    Write-Error "下载失败: $_"
    exit 1
}

# 3. 解压
Write-Host "[3/4] 解压文件..."
try
{
    Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

    $items = Get-ChildItem -Path $InstallDir
    if ($items.Count -eq 1 -and $items[0].PSIsContainer)
    {
        $subDir = $items[0].FullName
        Get-ChildItem -Path $subDir | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $InstallDir -Force
        }
        Remove-Item -Path $subDir -Force
    }

    # 清理临时文件
    Remove-Item -Path $TempZip -Force
    Write-Host "  解压完成" -ForegroundColor Green
} catch
{
    Write-Error "解压失败: $_"
    exit 1
}

# 4. 配置环境变量
Write-Host "[4/4] 配置环境变量..."
# 设置 NODE_HOME
Set-EnvVar -Name "NODE_HOME" -Value $InstallDir
# 添加到 PATH
Add-PathSafely -NewPath $InstallDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "请重新打开终端以使用 node 和 npm 命令" -ForegroundColor Yellow
