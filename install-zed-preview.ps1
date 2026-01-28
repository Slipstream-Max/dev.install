<#
.SYNOPSIS
    Zed Preview 安装脚本

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\ZedPreview）
#>
param(
    [string]$InstallDir = "D:\Programs\ZedPreview"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "Zed Preview"

# Zed 用户配置文件（固定路径）
$ZedSettingsPath = Join-Path $env:APPDATA "Zed\settings.json"

# 检测架构并确定下载 URL
$Arch = if ([Environment]::Is64BitOperatingSystem)
{
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
    { "aarch64"
    } else
    { "x86_64"
    }
} else
{
    Write-Error "不支持 32 位系统"
    exit 1
}

$DownloadUrl = "https://zed.dev/api/releases/preview/latest/Zed-$Arch.exe"
$ExeName = "Zed-$Arch.exe"

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

# 1. 创建安装目录
Write-Host "[1/4] 准备安装目录..."
if (-not (Test-Path $InstallDir))
{
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Write-Host "  安装目录: $InstallDir" -ForegroundColor Green

# 2. 下载
Write-Host "[2/4] 下载 $AppName ($Arch)..."
$TempExe = Join-Path $env:TEMP $ExeName
try
{
    Down-File -Url $DownloadUrl -OutFile $TempExe
    Write-Host "  下载完成" -ForegroundColor Green
} catch
{
    Write-Error "下载失败: $_"
    exit 1
}

# 3. 运行安装程序
Write-Host "[3/4] 运行安装程序..."
try
{
    # Zed 安装程序参数（Inno Setup）
    $ArgList = "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/DIR=`"$InstallDir`"", "/MERGETASKS=`"!addtopath,!runcode`""

    Write-Host "  等待安装完成..."
    $process = Start-Process -FilePath $TempExe -ArgumentList $ArgList -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0)
    {
        Write-Host "  安装完成" -ForegroundColor Green
    } else
    {
        Write-Warning "安装程序退出码: $($process.ExitCode)"
    }

    # 清理临时文件
    Remove-Item -Path $TempExe -Force -ErrorAction SilentlyContinue
} catch
{
    Write-Error "安装失败: $_"
    exit 1
}

# 4. 添加到 PATH
$BinPath = Join-Path $InstallDir "bin"
if (Test-Path $BinPath)
{
    Add-PathSafely -NewPath $BinPath
}

# 5. 同步 Zed 配置文件并联动 JDK 路径
Write-Host "[4/4] 同步 Zed 配置文件..."
$RepoSettingsPath = Join-Path $PSScriptRoot "zed\settings.json"

if (Test-Path $RepoSettingsPath)
{
    $ZedSettingsDir = Split-Path -Parent $ZedSettingsPath
    if (-not (Test-Path $ZedSettingsDir))
    {
        New-Item -ItemType Directory -Path $ZedSettingsDir -Force | Out-Null
    }

    # 动态拼接 JDK 路径：假设 JDK 与 Zed 安装在同一个父目录下
    # 例如：InstallDir 是 D:\Programs\ZedPreview -> BaseDir 是 D:\Programs -> JdkPath 是 D:\Programs\MicrosoftJDK21
    $BaseDir = Split-Path -Parent $InstallDir
    $JdkPath = Join-Path $BaseDir "MicrosoftJDK21"

    Write-Host "  正在根据安装目录联动 JDK 路径: $JdkPath" -ForegroundColor Gray

    # 统一路径分隔符为正斜杠，Zed 配置文件兼容性更好
    $NormalizedJdkPath = $JdkPath.Replace('\', '/')

    $Content = Get-Content -Path $RepoSettingsPath -Raw
    # 替换 jdtls 中的 java_home
    $Content = $Content -replace '("jdtls":\s*\{\s*"settings":\s*\{\s*"java_home":\s*")[^"]*', ('${1}' + $NormalizedJdkPath)
    # 替换 kotlin-language-server 中的 JAVA_HOME
    $Content = $Content -replace '("JAVA_HOME":\s*")[^"]*', ('${1}' + $NormalizedJdkPath)

    $Content | Set-Content -Path $ZedSettingsPath -Encoding UTF8
    Write-Host "  配置文件已同步并自动指向 JDK 路径" -ForegroundColor Green
} else
{
    Write-Warning "  未找到仓库配置文件，已跳过: $RepoSettingsPath"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "安装位置: $InstallDir"
Write-Host "Zed 配置路径: $ZedSettingsPath"
Write-Host "请重新打开终端以使用 'zed' 命令" -ForegroundColor Yellow
