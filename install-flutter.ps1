<#
.SYNOPSIS
    Flutter SDK 安装脚本

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\flutter）
#>
param(
    [string]$InstallDir = "D:\Programs\flutter"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "Flutter"
$ReleasesUrl = "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$StorageBaseUrl = "https://storage.googleapis.com/flutter_infra_release/releases"

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

# 1. 检查必备组件: Git
Write-Host "[1/5] 检查必备组件..."
if (-not (Get-Command git -ErrorAction SilentlyContinue))
{
    Write-Warning "未检测到 Git。虽然可以继续安装 SDK，但运行 Flutter 命令（如 flutter doctor）需要 Git，请务必后续安装。"
} else
{
    Write-Host "  Git 已就绪" -ForegroundColor Green
}

# 2. 获取最新稳定版下载地址
Write-Host "[2/5] 获取 $AppName 最新版本信息..."
try
{
    $releases = Invoke-RestMethod -Uri $ReleasesUrl
    $stableHash = $releases.current_release.stable
    $latestRelease = $releases.releases | Where-Object { $_.hash -eq $stableHash }

    if (-not $latestRelease)
    {
        Write-Error "无法解析最新稳定版本信息。"
        exit 1
    }

    $RelativePath = $latestRelease.archive
    $DownloadUrl = "$StorageBaseUrl/$RelativePath"
    $Version = $latestRelease.version
    Write-Host "  最新版本: $Version" -ForegroundColor Green
} catch
{
    Write-Error "获取版本信息失败: $_"
    exit 1
}

# 3. 下载 SDK
Write-Host "[3/5] 下载 $AppName SDK (可能会比较慢)..."
$ZipName = Split-Path $RelativePath -Leaf
$TempZip = Join-Path $env:TEMP $ZipName

try
{
    # 如果已经下载过，可以考虑校验或重新下载
    Write-Host "  下载链接: $DownloadUrl"
    Down-File -Url $DownloadUrl -OutFile $TempZip
    Write-Host "  下载完成" -ForegroundColor Green
} catch
{
    Write-Error "下载失败: $_"
    exit 1
}

# 4. 解压
Write-Host "[4/5] 解压到 $InstallDir..."
if (-not (Test-Path $InstallDir))
{
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

try
{
    # 使用 PowerShell 原生解压
    Write-Host "  正在解压，请稍候..."
    Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force

    # 处理嵌套目录 (Flutter zip 内含一个 flutter 文件夹)
    $items = Get-ChildItem -Path $InstallDir -Force
    if ($items.Count -eq 1 -and $items[0].PSIsContainer)
    {
        $subDir = $items[0].FullName
        Write-Host "  调整目录结构 (从 $(Split-Path $subDir -Leaf))..."

        # 移动所有内容（包括隐藏文件）到上级目录
        Get-ChildItem -Path $subDir -Force | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $InstallDir -Force
        }

        # 删除空的嵌套目录
        Remove-Item -Path $subDir -Force -Recurse -ErrorAction SilentlyContinue
    }

    Write-Host "  解压完成" -ForegroundColor Green

    # 清理临时文件
    Remove-Item -Path $TempZip -Force -ErrorAction SilentlyContinue
} catch
{
    Write-Error "解压失败: $_"
    exit 1
}

# 5. 添加到 PATH
Write-Host "[5/5] 配置环境变量..."
$FlutterBin = Join-Path $InstallDir "bin"
if (Test-Path $FlutterBin)
{
    Add-PathSafely -NewPath $FlutterBin
} else
{
    Write-Warning "未找到 flutter\bin 目录，请检查解压路径。"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "版本: $Version"
Write-Host "位置: $(Join-Path $InstallDir "flutter")"
Write-Host "后续步骤:" -ForegroundColor Yellow
Write-Host "1. 重新打开终端"
Write-Host "2. 运行 'flutter doctor' 检查依赖"
Write-Host ""
