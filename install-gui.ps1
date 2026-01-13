<#
.SYNOPSIS
    可视化一键安装工具 (GUI) - Fluent Design Style
    支持跟随系统的明暗主题自动切换。

.DESCRIPTION
    此脚本使用 WPF 构建 UI，并在后台线程运行安装任务。
    界面样式模拟 Windows 11 Fluent Design 风格。
    自动检测系统主题（亮色/暗色）并应用对应配色。
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============ 检测系统主题 ============
function Get-SystemTheme {
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $value = Get-ItemPropertyValue -Path $regPath -Name "AppsUseLightTheme" -ErrorAction Stop
        if ($value -eq 1) { return "Light" } else { return "Dark" }
    } catch {
        return "Dark" # 默认暗色
    }
}

$Theme = Get-SystemTheme

# ============ 主题配色 ============
if ($Theme -eq "Light") {
    # 亮色主题
    $WindowBg = "#F3F3F3"
    $CardBg = "#FFFFFF"
    $ControlBg = "#FAFAFA"
    $ControlBorder = "#E0E0E0"
    $ItemBg = "#F0F0F0"
    $ItemHover = "#E5E5E5"
    $AccentColor = "#0078D4"
    $AccentHover = "#1A86D9"
    $AccentPressed = "#006CBE"
    $TextPrimary = "#1A1A1A"
    $TextSecondary = "#666666"
    $ProgressBg = "#E0E0E0"
} else {
    # 暗色主题 (调整为更柔和的灰色)
    $WindowBg = "#2D2D2D"
    $CardBg = "#383838"
    $ControlBg = "#404040"
    $ControlBorder = "#505050"
    $ItemBg = "#454545"
    $ItemHover = "#505050"
    $AccentColor = "#60CDFF"
    $AccentHover = "#75D6FF"
    $AccentPressed = "#4CC2FF"
    $TextPrimary = "#FFFFFF"
    $TextSecondary = "#A0A0A0"
    $ProgressBg = "#505050"
}

# ============ XAML UI 定义 ============
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="开发环境一键安装器" Height="780" Width="880" WindowStartupLocation="CenterScreen"
        Background="$WindowBg" Foreground="$TextPrimary"
        FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif">
    
    <Window.Resources>
        <!-- Colors -->
        <SolidColorBrush x:Key="WindowBg" Color="$WindowBg"/>
        <SolidColorBrush x:Key="CardBg" Color="$CardBg"/>
        <SolidColorBrush x:Key="ControlBg" Color="$ControlBg"/>
        <SolidColorBrush x:Key="ControlBorder" Color="$ControlBorder"/>
        <SolidColorBrush x:Key="ItemBg" Color="$ItemBg"/>
        <SolidColorBrush x:Key="AccentColor" Color="$AccentColor"/>
        <SolidColorBrush x:Key="AccentHover" Color="$AccentHover"/>
        <SolidColorBrush x:Key="TextPrimary" Color="$TextPrimary"/>
        <SolidColorBrush x:Key="TextSecondary" Color="$TextSecondary"/>
        <SolidColorBrush x:Key="ProgressBg" Color="$ProgressBg"/>

        <!-- Text Styles -->
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
        </Style>

        <!-- Button Style (Fluent) -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="{StaticResource ControlBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource ControlBorder}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="$ItemHover"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="$ControlBg"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="{StaticResource AccentColor}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Accent Button Style -->
        <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="{StaticResource AccentColor}"/>
            <Setter Property="Foreground" Value="Black"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="$AccentHover"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="$AccentPressed"/>
                            </Trigger>
                             <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.6"/>
                                <Setter Property="Foreground" Value="#666666"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- TextBox Style -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource ControlBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource ControlBorder}"/>
            <Setter Property="BorderThickness" Value="0,0,0,1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="4">
                            <ScrollViewer x:Name="PART_ContentHost"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{StaticResource AccentColor}"/>
                                <Setter TargetName="border" Property="BorderThickness" Value="0,0,0,2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- CheckBox Style -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,8"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <!-- ProgressBar Style -->
        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="6"/>
            <Setter Property="Foreground" Value="{StaticResource AccentColor}"/>
            <Setter Property="Background" Value="{StaticResource ProgressBg}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Grid>
                            <Border Name="PART_Track" Background="{TemplateBinding Background}" CornerRadius="3"/>
                            <Border Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="3"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid Margin="32">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Path -->
            <RowDefinition Height="*"/>    <!-- Content (Tools) -->
            <RowDefinition Height="Auto"/> <!-- Progress -->
            <RowDefinition Height="140"/>  <!-- Log -->
            <RowDefinition Height="Auto"/> <!-- Actions -->
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,24">
            <TextBlock Text="开发环境一键安装" FontSize="28" FontWeight="SemiBold"/>
            <TextBlock Text="轻松配置您的工作站。请选择目标路径和组件。" FontSize="14" Foreground="{StaticResource TextSecondary}" Margin="0,8,0,0"/>
        </StackPanel>

        <!-- Path Selection (Card) -->
        <Border Grid.Row="1" Background="{StaticResource CardBg}" CornerRadius="8" Padding="16" Margin="0,0,0,24">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="安装路径" VerticalAlignment="Center" FontWeight="SemiBold" Margin="0,0,16,0"/>
                <TextBox Name="TxtInstallDir" Grid.Column="1" Text="D:\Programs" FontSize="14"/>
                <Button Name="BtnBrowse" Grid.Column="2" Content="浏览" Margin="12,0,0,0" Width="80"/>
            </Grid>
        </Border>

        <!-- Component List (Card) -->
        <Border Grid.Row="2" Background="{StaticResource CardBg}" CornerRadius="8" Padding="16" Margin="0,0,0,24">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBlock Text="选择组件" FontWeight="SemiBold" Margin="0,0,0,12"/>
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <ItemsControl Name="ItemsTools">
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <Border Background="{StaticResource ItemBg}" CornerRadius="6" Margin="0,0,8,8" Padding="12,8">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel VerticalAlignment="Center">
                                            <TextBlock Text="{Binding Name}" FontWeight="Medium" FontSize="14"/>
                                            <TextBlock Text="自动配置环境变量" FontSize="11" Foreground="{StaticResource TextSecondary}"/>
                                        </StackPanel>
                                        <CheckBox Grid.Column="1" IsChecked="{Binding IsChecked}" Tag="{Binding ScriptName}" Margin="0"/>
                                    </Grid>
                                </Border>
                            </DataTemplate>
                        </ItemsControl.ItemTemplate>
                        <ItemsControl.ItemsPanel>
                            <ItemsPanelTemplate>
                                <WrapPanel Orientation="Horizontal" ItemWidth="250"/>
                            </ItemsPanelTemplate>
                        </ItemsControl.ItemsPanel>
                    </ItemsControl>
                </ScrollViewer>
            </Grid>
        </Border>

        <!-- Progress Section -->
        <StackPanel Grid.Row="3" Margin="0,0,0,16">
            <Grid Margin="0,0,0,8">
                <TextBlock Name="TxtStatus" Text="准备就绪" Foreground="{StaticResource TextSecondary}" FontSize="13"/>
                <TextBlock Name="TxtProgress" Text="0%" HorizontalAlignment="Right" Foreground="{StaticResource AccentColor}" FontWeight="Bold"/>
            </Grid>
            <ProgressBar Name="PbMain" Value="0"/>
        </StackPanel>

        <!-- Log Area (Card) -->
        <Border Grid.Row="4" Background="{StaticResource CardBg}" CornerRadius="8" Padding="0" Margin="0,0,0,24" ClipToBounds="True">
            <TextBox Name="TxtLog" Background="Transparent" BorderThickness="0" 
                     Foreground="{StaticResource TextSecondary}" 
                     FontFamily="Consolas" FontSize="12" Padding="12"
                     IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap"
                     Text="等待开始..."/>
        </Border>

        <!-- Action Buttons -->
        <Grid Grid.Row="5">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" VerticalAlignment="Center">
                <TextBlock Text="当前主题: " Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center"/>
                <TextBlock Name="TxtTheme" Text="$Theme" Foreground="{StaticResource AccentColor}" VerticalAlignment="Center" FontWeight="SemiBold"/>
            </StackPanel>
            <Button Name="BtnStart" Style="{StaticResource AccentButton}" Content="立即安装" 
                    HorizontalAlignment="Right" Width="140" Height="40" FontSize="15"/>
        </Grid>
    </Grid>
</Window>
"@

# ============ 读取 UI 元素 ============
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "无法加载 XAML: $_"
    exit
}

$BtnBrowse = $window.FindName("BtnBrowse")
$TxtInstallDir = $window.FindName("TxtInstallDir")
$ItemsTools = $window.FindName("ItemsTools")
$BtnStart = $window.FindName("BtnStart")
$PbMain = $window.FindName("PbMain")
$TxtStatus = $window.FindName("TxtStatus")
$TxtProgress = $window.FindName("TxtProgress")
$TxtLog = $window.FindName("TxtLog")

# ============ 数据准备 ============
$ScriptFiles = Get-ChildItem -Path $PSScriptRoot -Filter "install-*.ps1" | 
    Where-Object { $_.Name -notin @("install-gui.ps1", "install-all.ps1") }

$ToolsData = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()

$NameMap = @{
    "install-node.ps1" = "Node.js (LTS)";
    "install-uv.ps1" = "uv (Python Tooling)";
    "install-rust.ps1" = "Rust Toolchain";
    "install-git.ps1" = "Git SCM";
    "install-vscode-insiders.ps1" = "VS Code Insiders";
    "install-vs-build-tools.ps1" = "VS Build Tools (C++)";
    "install-antigravity.ps1" = "Antigravity";
    "install-flutter.ps1" = "Flutter SDK"
}

foreach ($file in $ScriptFiles) {
    $prettyName = if ($NameMap.ContainsKey($file.Name)) { $NameMap[$file.Name] } else { $file.BaseName }
    $ToolsData.Add([PSCustomObject]@{
        Name = $prettyName
        ScriptName = $file.Name
        IsChecked = $true
    })
}

$ItemsTools.ItemsSource = $ToolsData

# ============ 事件处理 ============

$BtnBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.SelectedPath = $TxtInstallDir.Text
    if ($folderBrowser.ShowDialog() -eq 'OK') {
        $TxtInstallDir.Text = $folderBrowser.SelectedPath
    }
})

$LogSyncInfo = @{ Window = $window; TextBox = $TxtLog }
$WriteLog = {
    param($Message)
    $LogSyncInfo.Window.Dispatcher.Invoke([Action]{
        $LogSyncInfo.TextBox.AppendText("`n$Message")
        $LogSyncInfo.TextBox.ScrollToEnd()
    })
}

$UpdateSyncInfo = @{ Window = $window; StatusTxt= $TxtStatus; ProgressTxt=$TxtProgress; Pb=$PbMain }
$UpdateProgress = {
    param($Status, $Percent)
    $UpdateSyncInfo.Window.Dispatcher.Invoke([Action]{
        if ($Status) { $UpdateSyncInfo.StatusTxt.Text = $Status }
        if ($Percent -ne $null) { 
            $UpdateSyncInfo.Pb.Value = $Percent 
            $UpdateSyncInfo.ProgressTxt.Text = "$([math]::Round($Percent))%"
        }
    })
}

$BtnStart.Add_Click({
    $BtnStart.IsEnabled = $false
    $TxtInstallDir.IsEnabled = $false
    
    $BaseDir = $TxtInstallDir.Text
    
    $SelectedTools = $ToolsData | Where-Object { $_.IsChecked }
    if ($SelectedTools.Count -eq 0) {
        $window.Dispatcher.Invoke([Action]{
            [System.Windows.Forms.MessageBox]::Show("请至少选择一个工具", "提示")
            $BtnStart.IsEnabled = $true
            $TxtInstallDir.IsEnabled = $true
        })
        return
    }

    $TxtLog.Text = "初始化安装程序..."

    $ScriptBlock = {
        # 从 SessionState 读取参数
        $Total = $Tools.Count
        $Current = 0
        
        foreach ($tool in $Tools) {
            $Current++
            $Progress = ($Current - 1) / $Total * 100
            
            Write-Information "STATUS_UPDATE|正在安装: $($tool.Name)|$Progress"
            Write-Information "LOG|------------------------------------------------------------"
            Write-Information "LOG|>> 开始安装: $($tool.Name)"
            
            $SubDirName = switch -Regex ($tool.ScriptName) {
                "node" { "nodejs" }
                "uv"   { "uv" }
                "rust" { "Rust" }
                "git"  { "Git" }
                "vscode" { "VSCodeInsiders" }
                "vs-build" { "VSBuildTools" }
                "antigravity" { "Antigravity" }
                "flutter" { "flutter" }
                Default { $Tool.ScriptName.Replace("install-","").Replace(".ps1","") }
            }
            
            $ScriptPath = Join-Path $ScriptDir $tool.ScriptName
            $TargetInstallDir = Join-Path $BaseDir $SubDirName
            
            Write-Information "LOG|   目标路径: $TargetInstallDir"
            
            try {
                $ps = [PowerShell]::Create()
                $null = $ps.AddCommand($ScriptPath).AddParameter("InstallDir", $TargetInstallDir)
                $null = $ps.Invoke()
                
                if ($ps.Streams.Error.Count -gt 0) {
                    foreach ($err in $ps.Streams.Error) {
                        Write-Information "LOG|ERROR: $err"
                    }
                    Write-Information "LOG|X 安装失败: $($tool.Name)"
                } else {
                    Write-Information "LOG|√ 安装完成: $($tool.Name)"
                }
                
                $ps.Dispose()

            } catch {
                Write-Information "LOG|FATAL: 脚本调用异常 $_"
            }
            
            Start-Sleep -Milliseconds 200
        }
        
        Write-Information "STATUS_UPDATE|全部完成|100"
        Write-Information "LOG|------------------------------------------------------------"
        Write-Information "LOG|所有任务执行完毕。"
    }

    # 使用 PowerShell 对象 + Runspace 进行异步执行
    $script:Runspace = [runspacefactory]::CreateRunspace()
    $script:Runspace.Open()
    
    # 通过 SessionState 传递参数
    $script:Runspace.SessionStateProxy.SetVariable("BaseDir", $BaseDir)
    $script:Runspace.SessionStateProxy.SetVariable("Tools", $SelectedTools)
    $script:Runspace.SessionStateProxy.SetVariable("ScriptDir", $PSScriptRoot)
    
    $script:PowerShellInstance = [PowerShell]::Create()
    $script:PowerShellInstance.Runspace = $script:Runspace
    $null = $script:PowerShellInstance.AddScript($ScriptBlock)
    
    $script:AsyncResult = $script:PowerShellInstance.BeginInvoke()
    
    $script:InstallTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:InstallTimer.Interval = [TimeSpan]::FromMilliseconds(200)
    
    $script:InstallTimer.Add_Tick({
        try {
            # 防止重复执行或在对象释放后执行
            $pi = $script:PowerShellInstance
            $rs = $script:Runspace
            $ar = $script:AsyncResult
            $tm = $script:InstallTimer
            
            if ($null -eq $pi -or $null -eq $rs -or $null -eq $ar) { return }
            
            # 读取输出流
            if ($pi.Streams.Information.Count -gt 0) {
                $items = @($pi.Streams.Information)
                $pi.Streams.Information.Clear()
                foreach ($info in $items) {
                    $msg = $info.ToString()
                    if ($msg -match "^STATUS_UPDATE\|(.*?)\|(.*)") {
                        $UpdateProgress.Invoke($matches[1], [int]$matches[2])
                    } elseif ($msg -match "^LOG\|(.*)") {
                        $WriteLog.Invoke($matches[1])
                    } else {
                        $WriteLog.Invoke($msg)
                    }
                }
            }
            
            if ($pi.Streams.Error.Count -gt 0) {
                $errors = @($pi.Streams.Error)
                $pi.Streams.Error.Clear()
                foreach ($err in $errors) {
                    $WriteLog.Invoke("ERROR: $err")
                }
            }
            
            if ($ar.IsCompleted) {
                # 标记为清理中，防止重入
                $script:PowerShellInstance = $null
                $script:Runspace = $null
                $script:AsyncResult = $null
                
                # 停止计时器
                if ($null -ne $tm) { $tm.Stop() }
                
                # 清理资源
                try { $pi.EndInvoke($ar) } catch {}
                try { $pi.Dispose() } catch {}
                try { $rs.Dispose() } catch {}
                
                # 恢复界面
                $BtnStart.IsEnabled = $true
                $TxtInstallDir.IsEnabled = $true
                $UpdateProgress.Invoke("所有任务完成", 100)
            }
        } catch {
            # 彻底压制所有后台 UI 同步错误
        }
    })
    
    $script:InstallTimer.Start()
})

# ============ 启动窗口 ============
$window.ShowDialog() | Out-Null
