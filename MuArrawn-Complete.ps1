#Requires -RunAsAdministrator
<#
    MuArrawn Tool - Ultimate Optimizer
    Estilo: iGust / Ghost Toolbox / Chris Titus
    Funções: Debloat + Otimização + DNS Flush + Limpeza + Performance
    Nome: MuArrawn
#>

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- CONFIGURAÇÕES ---
$BloatList = @(
    "Microsoft.549981C3F5F10","Microsoft.BingNews","Microsoft.BingWeather","Microsoft.GetHelp",
    "Microsoft.Microsoft3DViewer","Microsoft.MicrosoftOfficeHub","Microsoft.MixedReality.Portal",
    "Microsoft.People","Microsoft.SkypeApp","Microsoft.Wallet","Microsoft.WindowsFeedbackHub",
    "Microsoft.Xbox.TCUI","Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay",
    "Microsoft.ZuneMusic","Microsoft.ZuneVideo","king.com.*","*Spotify*","*Disney*","*Facebook*",
    "*TikTok*","*Clipchamp*","*PrimeVideo*","Microsoft.YourPhone","Microsoft.OneConnect"
)

function LogMuArrawn {
    param($msg, $color="Green")
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts] $msg"
    Write-Host $line -ForegroundColor $color
    if ($global:LogBox) {
        $global:LogBox.AppendText("$line`r`n")
        $global:LogBox.SelectionStart = $global:LogBox.Text.Length
        $global:LogBox.ScrollToCaret()
    }
}

function Restore-MuArrawn {
    try {
        Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
        Checkpoint-Computer -Description "MuArrawn - Antes da Otimizacao" -RestorePointType MODIFY_SETTINGS -EA Stop
        LogMuArrawn "Ponto de restauração MuArrawn criado!" "Green"
    } catch { LogMuArrawn "Aviso: Não foi possível criar ponto de restauração: $($_.Exception.Message)" "Yellow" }
}

# --- FUNÇÕES CORE ---

function Invoke-MuArrawnDebloat {
    param($full=$false, $third=$true)
    LogMuArrawn "=== DEBLOAT MuArrawn iniciado ===" "Cyan"
    Restore-MuArrawn
    $c=0
    foreach ($app in $BloatList) {
        if (-not $third -and ($app -like "*Spotify*" -or $app -like "*Disney*" -or $app -like "*TikTok*")) { continue }
        if (-not $full -and $app -like "*Xbox*") { LogMuArrawn "Preservando $app (modo padrão)" "Gray"; continue }
        $pkgs = Get-AppxPackage -Name $app -AllUsers -EA SilentlyContinue
        foreach ($p in $pkgs) {
            LogMuArrawn "Removendo: $($p.Name)" "White"
            Remove-AppxPackage -Package $p.PackageFullName -AllUsers -EA SilentlyContinue; $c++
        }
        $prov = Get-AppxProvisionedPackage -Online -EA SilentlyContinue | Where-Object { $_.DisplayName -like $app }
        foreach ($pr in $prov) {
            LogMuArrawn "Removendo provisionado: $($pr.DisplayName)" "White"
            Remove-AppxProvisionedPackage -Online -PackageName $pr.PackageName -EA SilentlyContinue | Out-Null; $c++
        }
    }
    LogMuArrawn "Debloat finalizado! $c apps removidos." "Green"
}

function Invoke-MuArrawnOptimization {
    LogMuArrawn "=== OTIMIZAÇÃO MuArrawn ===" "Cyan"
    Restore-MuArrawn
    
    # 1. Plano de energia Alto Desempenho
    LogMuArrawn "-> Ativando plano de Alto Desempenho..." "White"
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    # Tenta ativar Ultimate Performance se existir
    $ultimate = powercfg /list | Select-String "Ultimate"
    if (-not $ultimate) { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null }
    powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 -EA SilentlyContinue

    # 2. Desativar efeitos visuais
    LogMuArrawn "-> Ajustando para melhor desempenho visual..." "White"
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f | Out-Null
    reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f | Out-Null

    # 3. Desativar telemetria e serviços pesados
    LogMuArrawn "-> Desativando telemetria e serviços desnecessários..." "White"
    $services = @("DiagTrack","dmwappushservice","SysMain","WSearch")
    foreach ($s in $services) {
        Set-Service -Name $s -StartupType Disabled -EA SilentlyContinue
        Stop-Service -Name $s -Force -EA SilentlyContinue
        LogMuArrawn "Serviço $s desativado" "Gray"
    }
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null

    # 4. Limpeza profunda
    LogMuArrawn "-> Limpando arquivos temporários..." "White"
    $paths = @("$env:TEMP\*","C:\Windows\Temp\*","C:\Windows\Prefetch\*")
    foreach ($path in $paths) { Remove-Item -Path $path -Recurse -Force -EA SilentlyContinue }
    cleanmgr /sagerun:1 -EA SilentlyContinue
    LogMuArrawn "Limpeza concluída!" "Green"

    # 5. Desativar inicialização automática de apps pesados
    LogMuArrawn "-> Desativando apps de inicialização..." "White"
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Spotify" /t REG_BINARY /d 0300000021D1A38C /f -EA SilentlyContinue | Out-Null

    LogMuArrawn "Otimização MuArrawn finalizada!" "Green"
}

function Invoke-MuArrawnDNS {
    param($dnsType="flush")
    LogMuArrawn "=== DNS / REDE - MuArrawn ===" "Cyan"
    
    if ($dnsType -eq "flush" -or $dnsType -eq "all") {
        LogMuArrawn "-> Limpando cache DNS..." "White"
        ipconfig /flushdns | Out-Null
        LogMuArrawn "DNS Flush OK!" "Green"
        
        LogMuArrawn "-> Resetando Winsock e IP..." "White"
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
        LogMuArrawn "Winsock resetado! Reinicie após." "Green"
    }

    if ($dnsType -eq "cloudflare" -or $dnsType -eq "all") {
        LogMuArrawn "-> Aplicando DNS Cloudflare (1.1.1.1) - Mais rápido para jogos" "White"
        $adapters = Get-NetAdapter -Physical | Where-Object Status -eq "Up"
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @("1.1.1.1","1.0.0.1") -EA SilentlyContinue
            LogMuArrawn "DNS Cloudflare aplicado em: $($adapter.Name)" "Gray"
        }
    }

    if ($dnsType -eq "google") {
        LogMuArrawn "-> Aplicando DNS Google (8.8.8.8)" "White"
        $adapters = Get-NetAdapter -Physical | Where-Object Status -eq "Up"
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @("8.8.8.8","8.8.4.4") -EA SilentlyContinue
        }
        LogMuArrawn "DNS Google aplicado!" "Green"
    }

    if ($dnsType -eq "auto") {
        LogMuArrawn "-> Voltando para DNS Automático..." "White"
        $adapters = Get-NetAdapter -Physical | Where-Object Status -eq "Up"
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -EA SilentlyContinue
        }
        LogMuArrawn "DNS Automático restaurado!" "Green"
    }
}

# --- INTERFACE - ESTILO IGUST / GHOST TOOLBOX ---

$form = New-Object System.Windows.Forms.Form
$form.Text = "MuArrawn - Ultimate Optimizer v2.0"
$form.Size = New-Object Drawing.Size(900, 650)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(18,18,18)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Icon = [System.Drawing.SystemIcons]::Shield

# Header
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Size = New-Object Drawing.Size(900, 70)
$headerPanel.BackColor = [Drawing.Color]::FromArgb(12,12,12)
$headerPanel.Dock = "Top"
$form.Controls.Add($headerPanel)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "MuArrawn"
$lblTitle.Font = New-Object Drawing.Font("Segoe UI",20,[Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [Drawing.Color]::FromArgb(139,92,246)
$lblTitle.Location = New-Object Drawing.Point(20,10)
$lblTitle.Size = New-Object Drawing.Size(200,35)
$headerPanel.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "OPTIMIZER • DEBLOAT • DNS FLUSH • CLEANER"
$lblSub.Font = New-Object Drawing.Font("Segoe UI",8)
$lblSub.ForeColor = [Drawing.Color]::Gray
$lblSub.Location = New-Object Drawing.Point(22,45)
$lblSub.Size = New-Object Drawing.Size(350,15)
$headerPanel.Controls.Add($lblSub)

# Tabs
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object Drawing.Point(10,80)
$tabControl.Size = New-Object Drawing.Size(865, 300)
$tabControl.BackColor = [Drawing.Color]::FromArgb(25,25,25)
$form.Controls.Add($tabControl)

# TAB 1 - DEBLOAT
$tabDebloat = New-Object System.Windows.Forms.TabPage
$tabDebloat.Text = "  🗑️ DEBLOAT  "
$tabDebloat.BackColor = [Drawing.Color]::FromArgb(25,25,25)
$tabDebloat.ForeColor = [Drawing.Color]::White
$tabControl.Controls.Add($tabDebloat)

$chkStandard = New-Object System.Windows.Forms.CheckBox; $chkStandard.Text="Modo Padrão (Mantém Xbox, Loja) - Recomendado"; $chkStandard.Checked=$true; $chkStandard.ForeColor=[Drawing.Color]::White; $chkStandard.Location=New-Object Drawing.Point(20,20); $chkStandard.Size=New-Object Drawing.Size(400,20); $tabDebloat.Controls.Add($chkStandard)
$chkFull = New-Object System.Windows.Forms.CheckBox; $chkFull.Text="Modo Completo (Remove tudo, até Xbox e OneDrive)"; $chkFull.ForeColor=[Drawing.Color]::White; $chkFull.Location=New-Object Drawing.Point(20,45); $chkFull.Size=New-Object Drawing.Size(400,20); $tabDebloat.Controls.Add($chkFull)
$chkThird = New-Object System.Windows.Forms.CheckBox; $chkThird.Text="Remover Apps Terceiros (Spotify, TikTok, Disney+, Facebook)"; $chkThird.Checked=$true; $chkThird.ForeColor=[Drawing.Color]::White; $chkThird.Location=New-Object Drawing.Point(20,70); $chkThird.Size=New-Object Drawing.Size(400,20); $tabDebloat.Controls.Add($chkThird)
$chkStandard.Add_Checked({if($chkStandard.Checked){$chkFull.Checked=$false}}); $chkFull.Add_Checked({if($chkFull.Checked){$chkStandard.Checked=$false}})

$btnDebloat = New-Object System.Windows.Forms.Button; $btnDebloat.Text="RODAR DEBLOAT"; $btnDebloat.BackColor=[Drawing.Color]::FromArgb(139,92,246); $btnDebloat.ForeColor=[Drawing.Color]::White; $btnDebloat.FlatStyle="Flat"; $btnDebloat.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $btnDebloat.Location=New-Object Drawing.Point(20,110); $btnDebloat.Size=New-Object Drawing.Size(200,45); $tabDebloat.Controls.Add($btnDebloat)
$btnReinstall = New-Object System.Windows.Forms.Button; $btnReinstall.Text="DESFAZER / REINSTALAR TUDO"; $btnReinstall.BackColor=[Drawing.Color]::FromArgb(50,50,50); $btnReinstall.ForeColor=[Drawing.Color]::White; $btnReinstall.FlatStyle="Flat"; $btnReinstall.Location=New-Object Drawing.Point(230,110); $btnReinstall.Size=New-Object Drawing.Size(200,45); $tabDebloat.Controls.Add($btnReinstall)

# TAB 2 - OTIMIZAÇÃO
$tabOpt = New-Object System.Windows.Forms.TabPage
$tabOpt.Text = "  ⚡ OTIMIZAÇÃO  "
$tabOpt.BackColor = [Drawing.Color]::FromArgb(25,25,25)
$tabControl.Controls.Add($tabOpt)

$lblOpt = New-Object System.Windows.Forms.Label; $lblOpt.Text="Otimizações de Performance e Privacidade (estilo iGust):"; $lblOpt.ForeColor=[Drawing.Color]::White; $lblOpt.Location=New-Object Drawing.Point(20,15); $lblOpt.Size=New-Object Drawing.Size(400,20); $tabOpt.Controls.Add($lblOpt)
$chkPerf = New-Object System.Windows.Forms.CheckBox; $chkPerf.Text="Plano de Energia Alto/Ultimate Desempenho"; $chkPerf.Checked=$true; $chkPerf.ForeColor=[Drawing.Color]::White; $chkPerf.Location=New-Object Drawing.Point(20,40); $chkPerf.Size=New-Object Drawing.Size(350,20); $tabOpt.Controls.Add($chkPerf)
$chkVisual = New-Object System.Windows.Forms.CheckBox; $chkVisual.Text="Desativar efeitos visuais (Mais FPS)"; $chkVisual.Checked=$true; $chkVisual.ForeColor=[Drawing.Color]::White; $chkVisual.Location=New-Object Drawing.Point(20,65); $chkVisual.Size=New-Object Drawing.Size(350,20); $tabOpt.Controls.Add($chkVisual)
$chkTelem = New-Object System.Windows.Forms.CheckBox; $chkTelem.Text="Desativar Telemetria e Rastreamento"; $chkTelem.Checked=$true; $chkTelem.ForeColor=[Drawing.Color]::White; $chkTelem.Location=New-Object Drawing.Point(20,90); $chkTelem.Size=New-Object Drawing.Size(350,20); $tabOpt.Controls.Add($chkTelem)
$chkClean = New-Object System.Windows.Forms.CheckBox; $chkClean.Text="Limpeza Profunda (Temp, Prefetch, Cache)"; $chkClean.Checked=$true; $chkClean.ForeColor=[Drawing.Color]::White; $chkClean.Location=New-Object Drawing.Point(20,115); $chkClean.Size=New-Object Drawing.Size(350,20); $tabOpt.Controls.Add($chkClean)

$btnOpt = New-Object System.Windows.Forms.Button; $btnOpt.Text="OTIMIZAR AGORA"; $btnOpt.BackColor=[Drawing.Color]::FromArgb(16,185,129); $btnOpt.ForeColor=[Drawing.Color]::White; $btnOpt.FlatStyle="Flat"; $btnOpt.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $btnOpt.Location=New-Object Drawing.Point(20,150); $btnOpt.Size=New-Object Drawing.Size(200,45); $tabOpt.Controls.Add($btnOpt)

# TAB 3 - DNS
$tabDNS = New-Object System.Windows.Forms.TabPage
$tabDNS.Text = "  🌐 DNS / REDE  "
$tabDNS.BackColor = [Drawing.Color]::FromArgb(25,25,25)
$tabControl.Controls.Add($tabDNS)

$lblDNS = New-Object System.Windows.Forms.Label; $lblDNS.Text="Correção de internet, ping alto e DNS:"; $lblDNS.ForeColor=[Drawing.Color]::White; $lblDNS.Location=New-Object Drawing.Point(20,15); $lblDNS.Size=New-Object Drawing.Size(400,20); $tabDNS.Controls.Add($lblDNS)

$btnFlush = New-Object System.Windows.Forms.Button; $btnFlush.Text="FLUSH DNS + RESET REDE"; $btnFlush.BackColor=[Drawing.Color]::FromArgb(59,130,246); $btnFlush.ForeColor=[Drawing.Color]::White; $btnFlush.FlatStyle="Flat"; $btnFlush.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $btnFlush.Location=New-Object Drawing.Point(20,45); $btnFlush.Size=New-Object Drawing.Size(200,40); $tabDNS.Controls.Add($btnFlush)
$btnCloudflare = New-Object System.Windows.Forms.Button; $btnCloudflare.Text="DNS CLOUDFLARE (1.1.1.1) - GAMER"; $btnCloudflare.BackColor=[Drawing.Color]::FromArgb(249,115,22); $btnCloudflare.ForeColor=[Drawing.Color]::White; $btnCloudflare.FlatStyle="Flat"; $btnCloudflare.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $btnCloudflare.Location=New-Object Drawing.Point(230,45); $btnCloudflare.Size=New-Object Drawing.Size(230,40); $tabDNS.Controls.Add($btnCloudflare)
$btnGoogle = New-Object System.Windows.Forms.Button; $btnGoogle.Text="DNS GOOGLE (8.8.8.8)"; $btnGoogle.BackColor=[Drawing.Color]::FromArgb(50,50,50); $btnGoogle.ForeColor=[Drawing.Color]::White; $btnGoogle.FlatStyle="Flat"; $btnGoogle.Location=New-Object Drawing.Point(20,95); $btnGoogle.Size=New-Object Drawing.Size(200,40); $tabDNS.Controls.Add($btnGoogle)
$btnAuto = New-Object System.Windows.Forms.Button; $btnAuto.Text="DNS AUTOMÁTICO (Padrão)"; $btnAuto.BackColor=[Drawing.Color]::FromArgb(50,50,50); $btnAuto.ForeColor=[Drawing.Color]::White; $btnAuto.FlatStyle="Flat"; $btnAuto.Location=New-Object Drawing.Point(230,95); $btnAuto.Size=New-Object Drawing.Size(200,40); $tabDNS.Controls.Add($btnAuto)

# LOG
$global:LogBox = New-Object System.Windows.Forms.TextBox
$global:LogBox.Multiline=$true; $global:LogBox.ScrollBars="Vertical"; $global:LogBox.BackColor=[Drawing.Color]::FromArgb(10,10,10); $global:LogBox.ForeColor=[Drawing.Color]::FromArgb(0,255,136); $global:LogBox.Font=New-Object Drawing.Font("Consolas",9); $global:LogBox.Location=New-Object Drawing.Point(10,390); $global:LogBox.Size=New-Object Drawing.Size(865,180); $global:LogBox.Text="> MuArrawn v2.0 iniciado...`r`n> Pronto para otimizar.`r`n> Dica: Use Debloat > Otimização > DNS para melhor resultado`r`n"; $form.Controls.Add($global:LogBox)

$btnUltimate = New-Object System.Windows.Forms.Button; $btnUltimate.Text="🚀 RODAR TUDO - OTIMIZAÇÃO COMPLETA MuArrawn"; $btnUltimate.BackColor=[Drawing.Color]::FromArgb(139,92,246); $btnUltimate.ForeColor=[Drawing.Color]::White; $btnUltimate.FlatStyle="Flat"; $btnUltimate.Font=New-Object Drawing.Font("Segoe UI",11,[Drawing.FontStyle]::Bold); $btnUltimate.Location=New-Object Drawing.Point(10,580); $btnUltimate.Size=New-Object Drawing.Size(865,40); $form.Controls.Add($btnUltimate)

# EVENTOS
$btnDebloat.Add_Click({ Invoke-MuArrawnDebloat -full $chkFull.Checked -third $chkThird.Checked })
$btnReinstall.Add_Click({ LogMuArrawn "Reinstalando apps padrão..."; Get-AppxPackage -AllUsers | ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -EA SilentlyContinue }; LogMuArrawn "Reinstalado!" })
$btnOpt.Add_Click({ Invoke-MuArrawnOptimization })
$btnFlush.Add_Click({ Invoke-MuArrawnDNS -dnsType "flush" })
$btnCloudflare.Add_Click({ Invoke-MuArrawnDNS -dnsType "cloudflare" })
$btnGoogle.Add_Click({ Invoke-MuArrawnDNS -dnsType "google" })
$btnAuto.Add_Click({ Invoke-MuArrawnDNS -dnsType "auto" })
$btnUltimate.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Isso vai rodar DEBLOAT + OTIMIZAÇÃO + DNS FLUSH + LIMPEZA completa do MuArrawn. Continuar?","MuArrawn - Modo Completo","YesNo","Question") -eq "Yes") {
        Invoke-MuArrawnDebloat -full $chkFull.Checked -third $chkThird.Checked
        Invoke-MuArrawnOptimization
        Invoke-MuArrawnDNS -dnsType "all"
        LogMuArrawn "========== MuArrawn FINALIZADO! Reinicie o PC ==========" "Cyan"
        [System.Windows.Forms.MessageBox]::Show("MuArrawn finalizou a otimização completa!`n`nReinicie o PC para aplicar tudo.","MuArrawn","OK","Information")|Out-Null
    }
})

$form.ShowDialog() | Out-Null
