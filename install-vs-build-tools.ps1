<#
.SYNOPSIS
    Visual Studio Build Tools 安装脚本
    主要用于为 Rust 和 C++ 开发提供最新的 MSVC 编译器和 Windows SDK

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\VSBuildTools）
#>
param(
    [string]$InstallDir = "D:\Programs\VSBuildTools"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "VS Build Tools"
$DownloadUrl = "https://aka.ms/vs/stable/vs_BuildTools.exe"
$ExeName = "vs_BuildTools.exe"

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

# 1. 下载 Bootstrapper
Write-Host "[1/2] 下载安装引导程序..."
$TempExe = Join-Path $env:TEMP $ExeName
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempExe -ErrorAction Stop
    Write-Host "  下载完成" -ForegroundColor Green
} catch {
    Write-Error "下载失败: $_"
    exit 1
}

# 2. 运行静默安装
Write-Host "[2/2] 正在开始静默安装..."
Write-Host "  提示: 这个过程会下载数 GB 数据且不显示进度，请耐心等待 10-20 分钟..." -ForegroundColor Yellow

try {
    # 参数说明：
    # --quiet: 完全静默运行
    # --wait: 等待安装完成再退出
    # --norestart: 安装后不自动重启
    # --nocache: 安装后删除包缓存，节省空间 (几百 MB 到 1GB)
    # --installPath: 指定安装目录
    # --add: 添加具体的工作负载。Microsoft.VisualStudio.Workload.VCTools 是 C++ 生成工具的核心。
    # --includeRecommended: 包含推荐组件（如 Windows SDK）
    
    $ArgList = @(
        "--quiet",
        "--wait",
        "--norestart",
        "--nocache",
        "--installPath", "`"$InstallDir`"",
        "--add", "Microsoft.VisualStudio.Workload.VCTools",
        "--includeRecommended"
    )

    $process = Start-Process -FilePath $TempExe -ArgumentList $ArgList -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        # 3010 表示安装成功，但需要重启电脑生效
        if ($process.ExitCode -eq 3010) {
            Write-Host "  安装成功（需要重启系统后生效）" -ForegroundColor Green
        } else {
            Write-Host "  安装成功" -ForegroundColor Green
        }
    } else {
        Write-Warning "安装程序返回代码: $($process.ExitCode). 请检查网络或磁盘空间。"
    }

    # 清理 bootstrapper
    Remove-Item -Path $TempExe -Force -ErrorAction SilentlyContinue
} catch {
    Write-Error "安装过程中出现错误: $_"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 配置完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "安装路径: $InstallDir"
Write-Host "包含组件: MSVC 编译器, Windows SDK, CMake 运行环境"
Write-Host "注意: 如果安装后 Rust 仍报错找不到链接器，请尝试重启系统。" -ForegroundColor Yellow
