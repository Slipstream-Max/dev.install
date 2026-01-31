<#
.SYNOPSIS
    Rust (rustup) 安装脚本

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\Rust）
#>
param(
    [string]$InstallDir = "D:\Programs\Rust"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "Rust"
$DownloadBaseUrl = "https://static.rust-lang.org/rustup/dist"

# 检测架构
$Arch = if ([Environment]::Is64BitOperatingSystem)
{
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')
    { 'aarch64' 
    } else
    { 'x86_64' 
    }
} else
{ 'i686' 
}

$ExeName = "rustup-init.exe"
$DownloadUrl = "$DownloadBaseUrl/$Arch-pc-windows-msvc/$ExeName"

# 环境变量路径
$CargoHome = Join-Path $InstallDir ".cargo"
$RustupHome = Join-Path $InstallDir ".rustup"

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

# 2. 设置环境变量（安装前需要设置，rustup 会使用这些路径）
Write-Host "[2/4] 预设环境变量..."
$env:CARGO_HOME = $CargoHome
$env:RUSTUP_HOME = $RustupHome
Set-EnvVar -Name "CARGO_HOME" -Value $CargoHome
Set-EnvVar -Name "RUSTUP_HOME" -Value $RustupHome

# 3. 下载
Write-Host "[3/4] 下载 $ExeName..."
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

# 4. 运行安装程序
Write-Host "[4/4] 运行安装程序..."
try
{
    # -y 表示默认安装，不需要交互
    # --no-modify-path 表示不修改系统 PATH，由脚本后续统一处理
    $process = Start-Process -FilePath $TempExe -ArgumentList "-y", "--no-modify-path" -Wait -PassThru -NoNewWindow

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

# 5. 添加 cargo/bin 到 PATH
$CargoBin = Join-Path $CargoHome "bin"
Add-PathSafely -NewPath $CargoBin

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "请重新打开终端以使用 rustc, cargo 等命令" -ForegroundColor Yellow
