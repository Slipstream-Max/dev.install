function Add-PathSafely {
    param([string]$NewPath)
    
    $RegPath = 'registry::HKEY_CURRENT_USER\Environment'
    $CurrentPath = (Get-Item -LiteralPath $RegPath).GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    $PathArray = $CurrentPath -split ';' | Where-Object { $_ -ne '' }
    
    if ($PathArray -notcontains $NewPath) {
        $NewPathValue = ($NewPath, $CurrentPath) -join ';'
        Set-ItemProperty -Type ExpandString -LiteralPath $RegPath -Name 'Path' -Value $NewPathValue
        Write-Host "已添加到 PATH: $NewPath" -ForegroundColor Green
        
        # 广播更新（通过随机变量触发系统环境变量刷新）
        $dummy = 'env-refresh-' + [guid]::NewGuid().ToString().Substring(0,8)
        [Environment]::SetEnvironmentVariable($dummy, '1', 'User')
        [Environment]::SetEnvironmentVariable($dummy, $null, 'User')
    } else {
        Write-Host "PATH 已包含: $NewPath" -ForegroundColor Yellow
    }
}

function Set-EnvVar {
    param([string]$Name, [string]$Value)
    
    $RegPath = 'registry::HKEY_CURRENT_USER\Environment'
    Set-ItemProperty -LiteralPath $RegPath -Name $Name -Value $Value
    Write-Host "已设置: $Name = $Value" -ForegroundColor Green
}

function Download-File {
    <#
    .SYNOPSIS
        使用 BITS 下载文件（后台智能传输服务，支持断点续传）
    
    .PARAMETER Url
        下载链接
    
    .PARAMETER OutFile
        输出文件路径
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutFile
    )
    
    Start-BitsTransfer -Source $Url -Destination $OutFile -Description "Downloading..." -ErrorAction Stop
}


