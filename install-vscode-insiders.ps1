<#
.SYNOPSIS
    VS Code Insiders 安装脚本

.PARAMETER InstallDir
    安装目录（默认 D:\Programs\VSCodeInsiders）
#>
param(
    [string]$InstallDir = "D:\Programs\VSCodeInsiders"
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# ============ 配置 ============
$AppName = "VS Code Insiders"

# 检测架构并确定下载 URL
$Arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 
        "win32-arm64-user" 
    } else { 
        "win32-x64-user" 
    }
} else {
    Write-Error "不支持 32 位系统"
    exit 1
}

$DownloadUrl = "https://update.code.visualstudio.com/latest/$Arch/insider"
$ExeName = "VSCodeUserSetup-Insiders.exe"

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
Write-Host "[1/3] 准备安装目录..."
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# 2. 下载
Write-Host "[2/3] 下载 $AppName..."
$TempExe = Join-Path $env:TEMP $ExeName
try {
    Download-File -Url $DownloadUrl -OutFile $TempExe
    Write-Host "  下载完成" -ForegroundColor Green
} catch {
    Write-Error "下载失败: $_"
    exit 1
}

# 3. 运行安装程序
Write-Host "[3/3] 运行安装程序..."
try {
    # /Verysilent: 静默安装
    # /SuppressMsgBoxes: 抑制消息框
    # /NoRestart: 安装后不重启
    # /Dir: 指定安装目录
    # /MERGETASKS: 禁用程序自带的 PATH 修改和自动启动
    #   !addtopath: 不添加到 PATH（由本脚本统一处理）
    #   !runcode: 安装完成后不自动启动 VS Code
    $ArgList = "/Verysilent", "/SuppressMsgBoxes", "/NoRestart", "/Dir=`"$InstallDir`"", "/MERGETASKS=`"!addtopath,!runcode`""
    
    Write-Host "  等待安装完成..."
    $process = Start-Process -FilePath $TempExe -ArgumentList $ArgList -Wait -PassThru -NoNewWindow
    
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

# 4. 添加到 PATH
$BinPath = Join-Path $InstallDir "bin"
if (Test-Path $BinPath) {
    Add-PathSafely -NewPath $BinPath
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  $AppName 安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "安装位置: $InstallDir"
Write-Host "请重新打开终端以使用 'code-insiders' 命令" -ForegroundColor Yellow
