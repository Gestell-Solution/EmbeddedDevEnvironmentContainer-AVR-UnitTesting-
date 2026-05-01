# ==================================================================================================================
# Author:       MohammedDiaa (mohammeddiaato@gmail.com)
# Company:      Gestell - Professional Embedded Solutions
# ==================================================================================================================
# --- CONFIGURATION ---
$Url = "http://127.0.0.1:8050/run"
$ProjectName = (Get-Item .).Name  # Grabs the folder name
$TempZip = "project.zip"
$OutputZip = "results.zip"        
$ConfigFile = "build_config.json"

Write-Host "--- Container Engine: Advanced Build Mode ($ProjectName) [Windows PowerShell] ---" -ForegroundColor Cyan

# 1. Determine Configuration via JSON
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Configuration file not found. Let's create one!" -ForegroundColor Yellow
    
    $BuildType = ""
    while ($BuildType -notmatch "^(c|avr)$") {
        $BuildType = Read-Host "Is this C or AVR code? (Enter 'c' or 'avr')"
        $BuildType = $BuildType.Trim().ToLower()
    }

    $Mcu = "atmega128"
    $CpuFreq = "16000000"
    
    if ($BuildType -eq "avr") {
        $InputMcu = Read-Host "Enter MCU (default: atmega128)"
        if (![string]::IsNullOrWhiteSpace($InputMcu)) { $Mcu = $InputMcu.Trim() }

        # Smart Frequency Parser
        $validFreq = $false
        while (-not $validFreq) {
            $InputFreq = Read-Host "Enter CPU Freq (e.g., 16M, 8MHz, 500K) [default: 16M]"
            if ([string]::IsNullOrWhiteSpace($InputFreq)) {
                $validFreq = $true # Keep default 16000000
            } else {
                $clean = $InputFreq.Trim().ToUpper()
                # Matches numbers, optional spaces, and M, K, or HZ
                if ($clean -match "^([\d\.]+)\s*(M|K)?(HZ)?$") {
                    $val = [double]$matches[1]
                    if ($matches[2] -eq 'M') { $val *= 1000000 }
                    elseif ($matches[2] -eq 'K') { $val *= 1000 }
                    $CpuFreq = [math]::Truncate($val).ToString()
                    $validFreq = $true
                } else {
                    Write-Host "Invalid format. Try '16M', '8MHz', '500K', or '16000000'." -ForegroundColor Red
                }
            }
        }
    }

    $ExtraFlags = Read-Host "Enter any extra GCC flags (e.g., -O2 -Wall) or press Enter to skip"

    # Create the JSON Object
    $ConfigObj = @{
        build_type = $BuildType
        mcu = $Mcu
        cpu_freq = $CpuFreq
        extra_flags = $ExtraFlags.Trim()
    }
    
    # Save it to the file system
    $ConfigObj | ConvertTo-Json | Set-Content -Path $ConfigFile
    Write-Host "Saved configuration to $ConfigFile." -ForegroundColor Green
} else {
    Write-Host "Found $ConfigFile. Using existing settings." -ForegroundColor DarkGray
}

# 2. Packaging
if (Test-Path $TempZip) { Remove-Item $TempZip }

Write-Host "Zipping files..."
tar.exe -a -c -f $TempZip --exclude=".vscode" --exclude=".git" --exclude=$TempZip --exclude="*.ps1" --exclude="*.out" --exclude=$OutputZip --exclude=$ConfigFile *

# 3. Shipping to the Container
Write-Host "Action: Sending to Factory..."
$statusCode = (curl.exe -s -w "%{http_code}" -o $OutputZip -X POST -F "config=@$ConfigFile" -F "file=@$TempZip" $Url).Trim()

# 4. Cleanup & Results
if (Test-Path $TempZip) { Remove-Item $TempZip }

if ($statusCode -eq "200") {
    Write-Host " Success! Received: $OutputZip" -ForegroundColor Green
} else {
    Write-Host "Error $statusCode" -ForegroundColor Red
    if (Test-Path $OutputZip) { 
        Get-Content $OutputZip 
        Remove-Item $OutputZip 
    }
}

# ==================================================================================================================
# Author:       MohammedDiaa (mohammeddiaato@gmail.com)
# Company:      Gestell - Professional Embedded Solutions
# ==================================================================================================================