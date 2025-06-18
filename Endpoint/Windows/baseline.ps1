# Collect-WindowsCMDBInfo.ps1
# Gathers system information useful for a CMDB

# Get basic system info
$computerSystem = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$bios = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$network = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }

# Get installed software (top 10 by install date)
$software = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, InstallDate | Where-Object { $_.DisplayName } | Sort-Object InstallDate -Descending | Select-Object -First 10

# Create CMDB object
$cmdbInfo = [PSCustomObject]@{
    Hostname           = $env:COMPUTERNAME
    Username           = $env:USERNAME
    Domain             = $computerSystem.Domain
    Manufacturer       = $computerSystem.Manufacturer
    Model              = $computerSystem.Model
    SerialNumber       = $bios.SerialNumber
    OS_Name            = $os.Caption
    OS_Version         = $os.Version
    OS_InstallDate     = ($os.InstallDate).ToString("yyyy-MM-dd")
    Uptime_Days        = ((Get-Date) - ($os.LastBootUpTime)).Days
    CPU_Name           = $cpu.Name
    CPU_Cores          = $cpu.NumberOfCores
    RAM_GB             = "{0:N1}" -f ($computerSystem.TotalPhysicalMemory / 1GB)
    Disk_Total_GB      = "{0:N1}" -f ($disk.Size / 1GB)
    Disk_Free_GB       = "{0:N1}" -f ($disk.FreeSpace / 1GB)
    IP_Address         = $network.IPAddress[0]
    MAC_Address        = $network.MACAddress
    Last_User          = $computerSystem.UserName
    Logged_On_Users    = (query user) -join "; "
    Installed_Software = $software
}

#CMDB folder creation
New-Item -ItemType Directory -Path "C:\Users\Public\CCMDB" -Force



# Output to JSON
cd "C:\Users\Public\CCMDB" ; $cmdbInfo | ConvertTo-Json -Depth 4 | Out-File ".\CMDBInfo_$env:COMPUTERNAME.json"

# Optional: also export to CSV (except software list)
#$cmdbInfo.PSObject.Properties.Remove('Installed_Software')
#$cmdbInfo | Export-Csv ".\CMDBInfo_$env:COMPUTERNAME.csv" -NoTypeInformation

#Write-Host "CMDB data collected and saved to JSON and CSV."




# Target endpoint URL (replace with your actual CMDB API URL)

$endpoint = "http://192.168.108.129:5000/api/cmdb"

$jsonData = Get-Content -Path "C:\Users\Public\CCMDB\CMDBInfo_$env:COMPUTERNAME.json"

# Send the data via POST

try {
$response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $jsonData -ContentType 'application/json'
Write-Host "Data successfully sent. Response:" $response
}

catch {Write-Error "Failed to send data: $_"
}


#$headers = @{"Authorization" = "Bearer YOUR_API_TOKEN" 
#"Content-Type"  = "application/json"}


#Invoke-RestMethod -Uri $endpoint -Method Post -Body $jsonData -Headers $headers


