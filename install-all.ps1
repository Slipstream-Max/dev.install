<#
.SYNOPSIS
    一键安装所有开发工具
    Orchestrator script to install all tools in their own subdirectories under a base directory.

.PARAMETER BaseInstallDir
    所有软件的基础安装目录（默认 D:\Programs）
#>
param(
    [string]$BaseInstallDir = "D:\Programs"
)

$ErrorActionPreference = 'Continue' # 允许单个失败后继续安装其他

# 1. 确保基础目录存在
if (-not (Test-Path $BaseInstallDir))
{
    Write-Host "创建基础安装目录: $BaseInstallDir"
    New-Item -ItemType Directory -Path $BaseInstallDir -Force | Out-Null
}

# 2. 定义软件列表
# Format: @{ Script="filename.ps1"; SubDir="DirectoryName"; NoInstallDir=$false }
# NoInstallDir: 设为 $true 表示该脚本不接受 -InstallDir 参数
$Tools = @(
    # 安装 Git
    @{ Name="Git for Windows";      Script="install-git.ps1";             SubDir="Git";            NoInstallDir=$false },
    @{ Name="GitHub Desktop";       Script="install-github-desktop.ps1";  SubDir="";               NoInstallDir=$true  },
    # 安装工具链
    @{ Name="Node.js";              Script="install-node.ps1";            SubDir="nodejs";         NoInstallDir=$false },
    @{ Name="uv";                   Script="install-uv.ps1";              SubDir="uv";             NoInstallDir=$false },
    @{ Name="Rust";                 Script="install-rust.ps1";            SubDir="Rust";           NoInstallDir=$false },
    @{ Name="Flutter";              Script="install-flutter.ps1";         SubDir="flutter";        NoInstallDir=$false },
    @{ Name="Microsoft JDK 21";     Script="install-jdk21.ps1";           SubDir="MicrosoftJDK21"; NoInstallDir=$false },
    @{ Name="VS Build Tools";       Script="install-vs-build-tools.ps1";  SubDir="VSBuildTools";   NoInstallDir=$false },
    @{ Name="Android SDK";          Script="install-android-sdk.ps1";     SubDir="AndroidSDK";     NoInstallDir=$false },
    # 安装编辑器和IDE
    @{ Name="VS Code Insiders";     Script="install-vscode-insiders.ps1"; SubDir="VSCodeInsiders"; NoInstallDir=$false },
    @{ Name="Antigravity";          Script="install-antigravity.ps1";     SubDir="Antigravity";    NoInstallDir=$false },
    @{ Name="Zed Preview";          Script="install-zed-preview.ps1";     SubDir="ZedPreview";     NoInstallDir=$false }
)

# 3. 运行通用安装脚本
foreach ($Tool in $Tools)
{
    $ScriptName = $Tool.Script
    $ScriptPath = Join-Path $PSScriptRoot $ScriptName

    if (Test-Path $ScriptPath)
    {
        Write-Host "`n------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "正在调用 $ScriptName 安装 $($Tool.Name)..." -ForegroundColor Cyan

        try
        {
            if ($Tool.NoInstallDir)
            {
                # 不传递 -InstallDir 参数
                Write-Host "目标路径: 使用默认路径" -ForegroundColor Gray
                & $ScriptPath
            } else
            {
                # 传递 -InstallDir 参数
                $InstallPath = Join-Path $BaseInstallDir $Tool.SubDir
                Write-Host "目标路径: $InstallPath" -ForegroundColor Gray
                & $ScriptPath -InstallDir $InstallPath
            }
        } catch
        {
            Write-Error "$($Tool.Name) 安装失败: $_"
        }
    } else
    {
        Write-Warning "找不到脚本: $ScriptName"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  所有任务执行完毕！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
