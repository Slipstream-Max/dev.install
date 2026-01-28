<#
.SYNOPSIS
    Android SDK 命令行工具安装脚本 (不含 Android Studio)

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\AndroidSDK）
#>
param(
    [string]$InstallDir = "D:\Programs\AndroidSDK"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "Android SDK Command-line Tools"
# 官方最新版本下载地址 (Win)
$DownloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

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

# 1. 准备安装目录
Write-Host "[1/5] 准备安装目录..."
# Android SDK 目录结构非常挑剔，sdkmanager 必须放在 cmdline-tools/latest/bin 才能正常工作
$CmdLineToolsDir = Join-Path $InstallDir "cmdline-tools"
$LatestDir = Join-Path $CmdLineToolsDir "latest"

if (-not (Test-Path $InstallDir))
{ New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
if (-not (Test-Path $CmdLineToolsDir))
{ New-Item -ItemType Directory -Path $CmdLineToolsDir -Force | Out-Null
}

# 2. 下载
Write-Host "[2/5] 下载 $AppName..."
$TempZip = Join-Path $env:TEMP "cmdline-tools.zip"
try
{
    Down-File -Url $DownloadUrl -OutFile $TempZip
    Write-Host "  下载完成" -ForegroundColor Green
} catch
{
    Write-Error "下载失败: $_"
    exit 1
}

# 3. 解压并整理目录
Write-Host "[3/5] 解压并整理目录结构 (cmdline-tools/latest)..."
$ExtractPath = Join-Path $env:TEMP "android_cmdline_temp"
if (Test-Path $ExtractPath)
{ Remove-Item -Path $ExtractPath -Recurse -Force
}

try
{
    Expand-Archive -Path $TempZip -DestinationPath $ExtractPath -Force

    # 如果已存在 latest 目录，先清理
    if (Test-Path $LatestDir)
    { Remove-Item -Path $LatestDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $LatestDir -Force | Out-Null

    # 将解压出的内容（bin, lib, source.properties等）移动到 latest 目录下
    # 注意：Google 的 zip 包里通常有一层名为 'cmdline-tools' 的文件夹
    $InnerDir = Join-Path $ExtractPath "cmdline-tools"
    if (-not (Test-Path $InnerDir))
    { $InnerDir = $ExtractPath
    }

    Get-ChildItem -Path $InnerDir | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $LatestDir -Force
    }

    Write-Host "  整理完成" -ForegroundColor Green
} catch
{
    Write-Error "解压或移动文件失败: $_"
    exit 1
} finally
{
    # 清理
    Remove-Item -Path $TempZip -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. 配置环境变量
Write-Host "[4/5] 配置环境变量..."

# 设置 ANDROID_HOME (User 级别)
Set-EnvVar -Name "ANDROID_HOME" -Value $InstallDir

# 添加 bin 目录到 PATH
$BinPath = Join-Path $LatestDir "bin"
if (Test-Path $BinPath)
{
    Add-PathSafely -NewPath $BinPath
}

# 预设 platform-tools 到 PATH (方便后续使用 adb)
$PlatformToolsPath = Join-Path $InstallDir "platform-tools"
Add-PathSafely -NewPath $PlatformToolsPath

# 5. 完成
Write-Host "[5/5] 初始化建议..."
Write-Host "  安装程序已就绪。由于 SDK 很大，建议你手动运行以下命令安装基础组件:" -ForegroundColor Yellow
Write-Host "  sdkmanager --licenses" -ForegroundColor Gray
Write-Host "  sdkmanager `"platform-tools`" `"platforms;android-36`" `"build-tools;36.0.0`" `"emulator`" " -ForegroundColor Gray

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "ANDROID_HOME: $InstallDir"
Write-Host "请重新打开终端使环境变量生效。" -ForegroundColor Yellow
