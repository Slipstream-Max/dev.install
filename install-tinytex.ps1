<#
.SYNOPSIS
    TinyTeX (Windows) 安装脚本（下载 GitHub latest release）

.DESCRIPTION
    - 自动获取 rstudio/tinytex-releases 的最新 release tag
    - 下载对应的 TinyTeX-<tag>.zip
    - 解压并安装到指定目录
    - 将 <InstallDir>\bin\windows 添加到当前用户 PATH

.PARAMETER InstallDir
    安装目录（默认 C:\Users\11307\Develop\TinyTeX）

.NOTES
    TinyTeX 是 per-user 的便携式发行版，本脚本不需要管理员权限。
#>
param(
    [string]$InstallDir = "D:\Programs\TinyTeX"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "TinyTeX"
$RepoUrl = "https://api.github.com/repos/rstudio/tinytex-releases/releases/latest"

# ============ 引入工具函数 ============
if (Test-Path "$PSScriptRoot\utils.ps1")
{
    . "$PSScriptRoot\utils.ps1"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  安装 $AppName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 获取最新版本
Write-Host "[1/4] 正在获取最新版本信息..."
try
{
    $LatestRelease = Invoke-RestMethod -Uri $RepoUrl
    $Tag = $LatestRelease.tag_name  # 例如 v2026.01
    if (-not $Tag)
    {
        throw "未获取到 tag_name"
    }
    Write-Host "  最新版本: $Tag" -ForegroundColor Green
} catch
{
    Write-Error "获取最新版本失败: $_"
    exit 1
}

# 2. 准备安装目录（如已存在则备份）
Write-Host "[2/4] 准备安装目录..."
if (-not (Test-Path $InstallDir))
{
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 3. 下载并解压
Write-Host "[3/4] 下载并解压 $AppName..."
$ZipName = "TinyTeX-$Tag.zip"
$DownloadUrl = "https://github.com/rstudio/tinytex-releases/releases/download/$Tag/$ZipName"
$TempZip = Join-Path $env:TEMP $ZipName
$TempExtract = Join-Path $env:TEMP ("TinyTeX-extract-" + [guid]::NewGuid().ToString())

try
{
    Down-File -Url $DownloadUrl -OutFile $TempZip
    try { Unblock-File -LiteralPath $TempZip -ErrorAction SilentlyContinue } catch {}

    New-Item -ItemType Directory -Path $TempExtract -Force | Out-Null
    Expand-Archive -LiteralPath $TempZip -DestinationPath $TempExtract -Force

    # 兼容 zip 内部带顶层目录（常见：TinyTeX/）或直接是内容。
    # 若只有一个顶层目录，则直接进入该目录，避免安装目录多套一层。
    $SourceRoot = $TempExtract
    $dirs = @(Get-ChildItem -LiteralPath $TempExtract -Directory -Force -ErrorAction SilentlyContinue)
    if ($dirs.Count -eq 1)
    {
        $SourceRoot = $dirs[0].FullName
    }

    if (-not (Test-Path (Join-Path $SourceRoot "bin\windows")))
    {
        Write-Warning "未检测到 bin\\windows，仍将按解压内容继续安装。"
    }

    # 直接 Move 整个目录到目标位置（同盘移动几乎瞬间完成，比 Copy 快得多）
    # 先确保目标目录不存在
    if (Test-Path $InstallDir)
    {
        Remove-Item -LiteralPath $InstallDir -Recurse -Force
    }
    Move-Item -LiteralPath $SourceRoot -Destination $InstallDir -Force

    Remove-Item -LiteralPath $TempZip -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $TempExtract -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "  下载与解压完成" -ForegroundColor Green
} catch
{
    Write-Error "下载或解压失败: $_"
    exit 1
}

# 4. 添加到 PATH（用户）
Write-Host "[4/4] 配置环境变量..."
$BinPath = Join-Path $InstallDir "bin\windows"
if (Test-Path $BinPath)
{
    Add-PathSafely -NewPath $BinPath
    Write-Host "  已添加到用户 PATH: $BinPath" -ForegroundColor Green
} else
{
    Write-Warning "未找到目录: $BinPath（可能解压结构有变化）。"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "版本(tag): $Tag"
Write-Host "安装目录: $InstallDir"
Write-Host "PATH 已添加: $BinPath"
Write-Host "提示: 请重新打开终端后再运行 'pdflatex --version' 验证" -ForegroundColor Yellow
