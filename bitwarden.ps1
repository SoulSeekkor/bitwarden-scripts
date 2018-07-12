param (
    [switch] $install,
    [switch] $start,
    [switch] $restart,
    [switch] $stop,
    [switch] $update,
    [switch] $updatedb,
    [switch] $updateself,
    [string] $output = ""
)

$year = (Get-Date).year

Write-Host @'
                 _ _       _     _ _                         _            
 ___  ___  _   _| ( )___  | |__ (_) |___      ____ _ _ __ __| | ___ _ __  
/ __|/ _ \| | | | |// __| | '_ \| | __\ \ /\ / / _` | '__/ _` |/ _ \ '_ \ 
\__ \ (_) | |_| | | \__ \ | |_) | | |_ \ V  V / (_| | | | (_| |  __/ | | |
|___/\___/ \__,_|_| |___/ |_.__/|_|\__| \_/\_/ \__,_|_|  \__,_|\___|_| |_|
'@

Write-Host "
Open source password management solutions
Copyright 2015-${year}, Soul's Services
https://soulseekkor.com, https://github.com/soulseekkor

===================================================
"

docker --version
docker-compose --version

echo ""

# Setup

$scriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($output -eq "") {
    $output = "${dir}\bwdata"
}

$scriptsDir = "${output}\scripts"
$githubBaseUrl = "https://raw.githubusercontent.com/SoulSeekkor/bitwarden-scripts/master"
$coreVersion = "1.20.0"
$webVersion = "1.27.0"

# Functions

function Download-Self {
    Invoke-RestMethod -OutFile $scriptPath -Uri "${githubBaseUrl}/bitwarden.ps1"
}

function Download-Run-File {
    if (!(Test-Path -Path $scriptsDir)) {
        New-Item -ItemType directory -Path $scriptsDir | Out-Null
    }
    Invoke-RestMethod -OutFile $scriptsDir\run.ps1 -Uri "${githubBaseUrl}/run.ps1"
}

function Check-Output-Dir-Exists {
    if (!(Test-Path -Path $output)) {
        throw "Cannot find a Bitwarden installation at $output."
    }
}

function Check-Output-Dir-Not-Exists {
    if (Test-Path -Path $output) {
        throw "Looks like Bitwarden is already installed at $output."
    }
}

# Commands

if ($install) {
    Check-Output-Dir-Not-Exists
    New-Item -ItemType directory -Path $output | Out-Null
    Download-Run-File
    Invoke-Expression "$scriptsDir\run.ps1 -install -outputDir $output -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($start -Or $restart) {
    Check-Output-Dir-Exists
    Invoke-Expression "$scriptsDir\run.ps1 -restart -outputDir $output -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($update) {
    Check-Output-Dir-Exists
    Download-Run-File
    Invoke-Expression "$scriptsDir\run.ps1 -update -outputDir $output -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($updatedb) {
    Check-Output-Dir-Exists
    Invoke-Expression "$scriptsDir\run.ps1 -updatedb -outputDir $output -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($stop) {
    Check-Output-Dir-Exists
    Invoke-Expression "$scriptsDir\run.ps1 -stop -outputDir $output -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($updateself) {
    Download-Self
    echo "Updated self."
}
else {
    echo "No command found."
}
