<#
.SYNOPSIS
    Microsoft JDK 21 安装脚本

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\MicrosoftJDK21）
#>
param(
    [string]$InstallDir = "D:\Programs\MicrosoftJDK21"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "Microsoft JDK 21"
$Version = "21.0.9"

# 检测架构
$Arch = if ([Environment]::Is64BitOperatingSystem)
{
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
    { "aarch64" 
    } else
    { "x64" 
    }
} else
{
    Write-Error "不支持 32 位系统"
    exit 1
}

$MsiName = "microsoft-jdk-$Version-windows-$Arch.msi"
$DownloadUrl = "https://aka.ms/download-jdk/$MsiName"

# ============ 引入工具函数 ============
if (Test-Path "$PSScriptRoot\utils.ps1")
{
    . "$PSScriptRoot\utils.ps1"
}

# ============ 主流程 ============
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  安装 $AppName ($Arch)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 准备安装目录
Write-Host "[1/4] 准备安装目录..."
if (-not (Test-Path $InstallDir))
{
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 2. 下载
Write-Host "[2/4] 下载 $AppName..."
$TempMsi = Join-Path $env:TEMP $MsiName
try
{
    Down-File -Url $DownloadUrl -OutFile $TempMsi
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
    # MSI 安装参数:
    # /i: 安装
    # /qn: 静默安装，无 UI
    # /norestart: 不重启
    # INSTALLDIR: 指定安装路径
    $ArgList = "/i", "`"$TempMsi`"", "/qn", "/norestart", "INSTALLDIR=`"$InstallDir`""

    Write-Host "  正在通过 msiexec 安装，请稍候..."
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $ArgList -Wait -PassThru

    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010)
    {
        Write-Host "  安装成功" -ForegroundColor Green
        if ($process.ExitCode -eq 3010)
        {
            Write-Warning "系统提示需要重启以完成安装。"
        }
    } else
    {
        Write-Error "安装程序失败，退出码: $($process.ExitCode)"
        exit 1
    }

    # 清理临时文件
    Remove-Item -Path $TempMsi -Force -ErrorAction SilentlyContinue
} catch
{
    Write-Error "安装过程中发生错误: $_"
    exit 1
}

# 4. 配置环境变量
Write-Host "[4/4] 配置环境变量..."
# 设置 JAVA_HOME
Set-EnvVar -Name "JAVA_HOME" -Value $InstallDir
# 添加到 PATH
Add-PathSafely -NewPath (Join-Path $InstallDir "bin")

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "版本: $Version"
Write-Host "安装位置: $InstallDir"
Write-Host "JAVA_HOME: $InstallDir"
Write-Host "请重新打开终端以使用 'java -version' 确认" -ForegroundColor Yellow
