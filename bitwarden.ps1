param (
    [switch] $install,
    [switch] $start,
    [switch] $restart,
    [switch] $stop,
    [switch] $update,
    [switch] $rebuild,
    [switch] $updatedb,
    [switch] $updateself,
    [string] $output = ""
)

# Setup

$scriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($output -eq "") {
    $output = "${dir}\bwdata"
}

$scriptsDir = "${output}\scripts"
$githubBaseUrl = "https://raw.githubusercontent.com/SoulSeekkor/bitwarden-scripts/master"
$coreVersion = "1.32.0"
$webVersion = "2.12.0"

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
    if (Test-Path -Path "$output\docker") {
        throw "Looks like Bitwarden is already installed at $output."
    }
}

function Write-Line($str) {
    if($env:BITWARDEN_QUIET -ne "true") {
        Write-Host $str
    }
}

# Intro

$year = (Get-Date).year

Write-Line @'
                 _ _       _     _ _                         _            
 ___  ___  _   _| ( )___  | |__ (_) |___      ____ _ _ __ __| | ___ _ __  
/ __|/ _ \| | | | |// __| | '_ \| | __\ \ /\ / / _` | '__/ _` |/ _ \ '_ \ 
\__ \ (_) | |_| | | \__ \ | |_) | | |_ \ V  V / (_| | | | (_| |  __/ | | |
|___/\___/ \__,_|_| |___/ |_.__/|_|\__| \_/\_/ \__,_|_|  \__,_|\___|_| |_|
'@

Write-Line "
Open source password management solutions
Copyright 2018-${year}, Soul's Services
https://soulseekkor.com, https://github.com/soulseekkor

===================================================
"

if($env:BITWARDEN_QUIET -ne "true") {
    docker --version
    docker-compose --version
}

Write-Line ""

# Commands

if ($install) {
    Check-Output-Dir-Not-Exists
    New-Item -ItemType directory -Path $output -ErrorAction Ignore | Out-Null
    Download-Run-File
    Invoke-Expression "& `"$scriptsDir\run.ps1`" -install -outputDir `"$output`" -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($start -Or $restart) {
    Check-Output-Dir-Exists
    Invoke-Expression "& `"$scriptsDir\run.ps1`" -restart -outputDir `"$output`" -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($update) {
    Check-Output-Dir-Exists
    Download-Run-File
    Invoke-Expression "& `"$scriptsDir\run.ps1`" -update -outputDir `"$output`" -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($rebuild) {
    Check-Output-Dir-Exists
    Invoke-Expression "& `"$scriptsDir\run.ps1`" -rebuild -outputDir `"$output`" -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($updatedb) {
    Check-Output-Dir-Exists
    Invoke-Expression "& `"$scriptsDir\run.ps1`" -updatedb -outputDir `"$output`" -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($stop) {
    Check-Output-Dir-Exists
    Invoke-Expression "& `"$scriptsDir\run.ps1`" -stop -outputDir `"$output`" -coreVersion $coreVersion -webVersion $webVersion"
}
elseif ($updateself) {
    Download-Self
    Write-Line "Updated self."
}
else {
    Write-Line "No command found."
}
