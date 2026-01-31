# --------------------------------------------
# Run on Node (ron)
# v1.0.0
# Author: Aaron Carneiro <@euaaron>
# Email: ron@aaroncarneiro.com
# GitHub: https://github.com/euaaron
# This File: https://gist.github.com/euaaron/8b0a2497244b3711e65ad798bdc5873f
# --------------------------------------------
$ronVersion = "v1.0.4"
$silentInit = $true

# Configuration
$configFileName = ".ronrc"
$ronrc = "$PSScriptRoot\$configFileName"

# ============ UTILITY FUNCTIONS ============

# Logging function - centralized console output
function Write-Log {
  param(
    [string] $Message = "",
    [string] $ForegroundColor = "White",
    [switch] $IsError
  )
  if ($IsError) {
    Write-Host $Message -ForegroundColor Red
  } else {
    Write-Host $Message -ForegroundColor $ForegroundColor
  }
}

# Load configuration from JSON file
function Get-Config {
  if (Test-Path $ronrc) {
    $config = Get-Content $ronrc | ConvertFrom-Json
    # Add default properties if missing
    if (-Not $config.PSObject.Properties['autoUpdate']) {
      $config | Add-Member -NotePropertyName autoUpdate -NotePropertyValue $true -Force
    }
    if (-Not $config.PSObject.Properties['lastUpdateCheck']) {
      $config | Add-Member -NotePropertyName lastUpdateCheck -NotePropertyValue "" -Force
    }
    return $config
  }
  
  # Return default config if file doesn't exist
  return @{
    nodeDirectory = $HOME + "\.ron\node\"
    defaultVersion = "24"
    architecture = "win-x64"
    autoUpdate = $true
    lastUpdateCheck = ""
  }
}

# Save configuration to JSON file
function Set-Config {
  param(
    [PSCustomObject] $Config
  )
  
  try {
    $Config | ConvertTo-Json | Set-Content -Path $ronrc -Force
    Write-Log "Configuration saved to $ronrc" -ForegroundColor Green
  }
  catch {
    Write-Log "Error saving configuration: $_" -IsError
  }
}

# Initialize configuration file with defaults if missing
function Initialize-Config {
  param(
    [bool] $Force = $false
  )
  
  if ($Force -and (Test-Path $ronrc)) {
    Write-Log "Force flag detected. Removing existing configuration..." -ForegroundColor Yellow
    Remove-Item $ronrc -Force
    Write-Log "Existing configuration removed." -ForegroundColor Green
  }
  
  if (-Not (Test-Path $ronrc)) {
    Write-Log "Initializing ron configuration..." -ForegroundColor Cyan
    
    # Determine system architecture
    $systemArch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
    $architecture = switch -Regex ($systemArch) {
      "64.*bit|x64|AMD64" { "win-x64" }
      "32.*bit|x86" { "win-x86" }
      "ARM.*64|aarch64" { "win-arm64" }
      default { "win-x64" }
    }
    Write-Log "Detected architecture: $architecture" -ForegroundColor Green
    
    # Fetch LTS version from nodejs.org
    Write-Log "Fetching current Node.js LTS version..." -ForegroundColor Cyan
    try {
      $indexJson = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing
      $ltsVersion = ($indexJson | Where-Object { $_.lts -ne $false } | Select-Object -First 1).version
      $defaultVersion = $ltsVersion -replace "v(\d+)\..*", '$1'
      Write-Log "Current LTS version: v$defaultVersion" -ForegroundColor Green
    }
    catch {
      Write-Log "Warning: Unable to fetch LTS version from nodejs.org. Using fallback version 24" -ForegroundColor Yellow
      $defaultVersion = "24"
    }
    
    # Prompt user for node directory
    $defaultPath = "$HOME\.ron"
    Write-Log ""
    Write-Log "Please provide the desired Node.js installation directory." -ForegroundColor Cyan
    Write-Log "Default path: $defaultPath (or ~/.ron)" -ForegroundColor Gray
    Write-Host -NoNewline "Enter path (press Enter for default): "
    $userInput = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($userInput)) {
      $nodeDirectory = $defaultPath + "\node\"
      Write-Log "Using default path: $nodeDirectory" -ForegroundColor Green
    }
    else {
      # Clean up user input and ensure it ends properly
      $userInput = $userInput.Trim().TrimEnd('\\')
      $nodeDirectory = $userInput + "\node\"
      Write-Log "Using custom path: $nodeDirectory" -ForegroundColor Green
    }
    
    $defaultConfig = @{
      nodeDirectory = $nodeDirectory
      defaultVersion = $defaultVersion
      architecture = $architecture
      autoUpdate = $true
      lastUpdateCheck = ""
    }
    Set-Config $defaultConfig
    Write-Log "Configuration file created at $ronrc" -ForegroundColor Green
    Write-Log ""
    Write-Log "This tool checks daily for Node.js LTS updates so you never fall behind." -ForegroundColor Cyan
    Write-Log "If you don't want automatic update checks, run 'ron -autoupdate false'" -ForegroundColor Gray
  }
}

function CreateDir {
  param(
    [string] $Dir = ""
  )

  if (-Not $Dir -Contains "*:\") {
    $tempDir = $Dir;
    $Dir = ([System.Environment]::CurrentDirectory)
    $Dir += "\"
    $Dir += $tempDir;
  }

  if (-Not (Test-Path $Dir)) {
    $dirPath = $Dir.Split("\");
    $currentPath = ""
    $count = 0;
    $dirPath | ForEach-Object {
      if (-Not ($dirPath[$count] -Eq "") -Or -Not ($dirPath[$count] -Eq "\")) {
        $currentPath += $dirPath[$count]
        $currentPath += "\"
        $currentPath = $currentPath.Replace("\\", "\");
        if (-Not (Test-Path $currentPath) -And -Not ($currentPath -Eq "")) {
          mkdir $currentPath | Out-Null
        }
      }
      if (-Not ($dirPath.Length - 1 -Eq $count)) {
        $count += 1;
      } else {
          Write-Log "Directory '$currentPath' has been created successfully!"
        return;
      }
    }
  } else {
    Write-Log "Error! '$dir' already exists!" -IsError
  }
}

Function Test-CommandExists {
  Param (
    [string] $Command, 
    [switch] $Silent
  )
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'stop'
  $exists = $false;

  try {
    if(Get-Command $Command) {
      $exists = $true
      if (-Not $Silent) {
        Write-Log "Command '$Command' exists!"
      }
    }
  }
  Catch {
    $exists = $false
    if (-Not $Silent) {
      Write-Log "Command '$Command' was not found!" -IsError
    }
  }

  $ErrorActionPreference = $oldPreference
  return $exists;
}

# Ensure directory exists, create if needed
function Test-Directory {
  param(
    [string] $Path
  )
  
  if (-Not (Test-Path $Path)) {
    CreateDir -Dir $Path
  }
}

# Get LTS version information from nodejs.org
function Get-LtsVersions {
  try {
    $indexJson = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing
    $ltsVersions = $indexJson | Where-Object { $_.lts -ne $false }
    $latestLts = $ltsVersions | Select-Object -First 1
    $latestLtsShort = $latestLts.version -replace "v(\d+)\..*", '$1'
    
    $allLtsVersionsShort = $ltsVersions | ForEach-Object { 
      $_.version -replace "v(\d+)\..*", '$1' 
    } | Select-Object -Unique
    
    return @{
      latestLtsFull = $latestLts.version
      latestLtsShort = $latestLtsShort
      allLtsVersions = $allLtsVersionsShort
    }
  }
  catch {
    return $null
  }
}

# Check for LTS updates and prompt user
function Check-LtsUpdate {
  param(
    [PSCustomObject] $Config
  )
  
  if (-Not $Config.autoUpdate) {
    return
  }
  
  $today = Get-Date -Format "yyyy-MM-dd"
  
  # Check if we already checked today
  if ($Config.lastUpdateCheck -eq $today) {
    return
  }
  
  Write-Log "Checking for Node.js LTS updates..." -ForegroundColor Cyan
  $ltsInfo = Get-LtsVersions
  
  if (-Not $ltsInfo) {
    Write-Log "Could not check for updates." -ForegroundColor Yellow
    return
  }
  
  $Config.lastUpdateCheck = $today
  Set-Config $Config
  
  if ($ltsInfo.latestLtsShort -ne $Config.defaultVersion) {
    Write-Log ""
    Write-Host "Node.js " -NoNewline
    Write-Host $ltsInfo.latestLtsFull -NoNewline -ForegroundColor Green
    Write-Host " is the new latest LTS version! Do you want to upgrade? [y/N]: " -NoNewline
    $response = Read-Host
    
    if ($response -eq 'y' -or $response -eq 'Y') {
      $Config.defaultVersion = $ltsInfo.latestLtsShort
      Set-Config $Config
      Write-Log "Default version updated to $($ltsInfo.latestLtsShort)" -ForegroundColor Green
    } else {
      Write-Log "Alright, I'll let you know again tomorrow." -ForegroundColor Cyan
      Write-Log "If you don't want me to bother you again, set 'ron -autoupdate false'" -ForegroundColor Gray
    }
    Write-Log ""
  }
}

# Calculate Levenshtein distance between two strings for fuzzy matching
function Get-StringDistance {
  param(
    [string] $String1,
    [string] $String2
  )
  
  $len1 = $String1.Length
  $len2 = $String2.Length
  $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
  
  for ($i = 0; $i -le $len1; $i++) { $matrix[$i, 0] = $i }
  for ($j = 0; $j -le $len2; $j++) { $matrix[0, $j] = $j }
  
  for ($i = 1; $i -le $len1; $i++) {
    for ($j = 1; $j -le $len2; $j++) {
      $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
      $matrix[$i, $j] = [Math]::Min(
        [Math]::Min($matrix[$i - 1, $j] + 1, $matrix[$i, $j - 1] + 1),
        $matrix[$i - 1, $j - 1] + $cost
      )
    }
  }
  
  return $matrix[$len1, $len2]
}

# Find the closest matching command
function Find-ClosestCommand {
  param(
    [string] $Input
  )
  
  $validCommands = @(
    @{name="init"; aliases=@("i")},
    @{name="version"; aliases=@("v")},
    @{name="list"; aliases=@("l")},
    @{name="change"; aliases=@("c")},
    @{name="dir"; aliases=@()},
    @{name="default"; aliases=@("d")},
    @{name="help"; aliases=@("h")},
    @{name="remote"; aliases=@("r")},
    @{name="arch"; aliases=@("a")},
    @{name="force"; aliases=@("F")}
  )
  
  $cleanInput = $Input.ToLower().TrimStart('-')
  $bestMatch = $null
  $bestDistance = [int]::MaxValue
  
  foreach ($cmd in $validCommands) {
    $distance = Get-StringDistance -String1 $cleanInput -String2 $cmd.name
    if ($distance -lt $bestDistance -and $distance -le 3) {
      $bestDistance = $distance
      $bestMatch = $cmd.name
    }
    
    foreach ($alias in $cmd.aliases) {
      $distance = Get-StringDistance -String1 $cleanInput -String2 $alias
      if ($distance -lt $bestDistance -and $distance -le 2) {
        $bestDistance = $distance
        $bestMatch = $cmd.name
      }
    }
  }
  
  return $bestMatch
}

# Add or update PATH entry for Node directory
function Set-NodePathEntry {
  param(
    [string] $NodeDirectory
  )
  
  if ($env:Path -notlike "*$NodeDirectory*") {
    $env:Path = "$NodeDirectory;" + $env:Path
  } else {
    # Remove old entry and add new one at the beginning
    $env:Path = ($env:Path -split ';' | Where-Object { $_ -notlike "*node*" }) -join ';'
    $env:Path = "$NodeDirectory;" + $env:Path
  }
}

# ============ MAIN RON FUNCTION ============

function ron {
  [CmdletBinding()]
  param(
    [Alias('c')]
    [string] $Change = "",    
    [Alias('i')]
    [switch] $Init,
    [Alias('v')]
    [switch] $Version,
    [Alias('f')]
    [switch] $Force,
    [Alias('l')]
    [switch] $List,
    [Alias('r')]
    [switch] $Remote,
    [Alias('h')]
    [switch] $Help,
    [Alias('a')]
    [string] $Arch = "",
    [switch] $Dir,
    [Alias('d')]
    [switch] $Default,
    [switch] $AutoUpdate
  )

  # Load configuration
  $config = Get-Config

  # Handle special case: if -Dir or -AutoUpdate is present, $Change contains their value
  $dirArg = $null
  $autoUpdateArg = $null
  
  if ($Dir.IsPresent -and -Not [string]::IsNullOrWhiteSpace($Change)) {
    $dirArg = $Change
    $Change = ""
  }
  
  if ($AutoUpdate.IsPresent -and -Not [string]::IsNullOrWhiteSpace($Change)) {
    $autoUpdateArg = $Change
    $Change = ""
  }

  # Validate that $Change is not a command name (user forgot the dash)
  $commandNames = @("init", "version", "list", "change", "dir", "default", "help", "remote", "arch", "force")
  if (-Not [string]::IsNullOrEmpty($Change) -and $commandNames -contains $Change.ToLower()) {
    Write-Log "Invalid command: '$Change'. Did you mean '-$Change'?" -IsError
    return
  }

  # Validate architecture parameter
  $validArchitectures = @("win-x64", "win-x86", "win-arm64")
  if (-Not [string]::IsNullOrEmpty($Arch)) {
    if ($validArchitectures -notcontains $Arch) {
      # Check if it looks like a version number (likely user error)
      if ($Arch -match '^\d+$') {
        Write-Log "Invalid command usage. Did you mean 'ron -change $Arch'?" -IsError
        return
      }
      Write-Log "Invalid architecture: '$Arch'. Valid options are: $($validArchitectures -join ', ')" -IsError
      return
    }
    $config.architecture = $Arch
    Set-Config $config
  }

  $nodeDir = $config.nodeDirectory
  $defaultVersion = $config.defaultVersion
  $arch = if ([string]::IsNullOrEmpty($Arch)) { $config.architecture } else { $Arch }

  # -------- INNER FUNCTIONS --------
  
  function nInit {
    Test-Directory -Path $nodeDir

    $defaultNodeDir = Join-Path $nodeDir $defaultVersion
    
    if (-Not (Test-Path $defaultNodeDir)) {
      Write-Log "Default Node version $defaultVersion not found. Installing..." -ForegroundColor Yellow
      try {
        nChange -Version $defaultVersion -Arch $arch -Force $false
      }
      catch {
        Write-Log "Error installing Node version $defaultVersion : $_" -IsError
      }
    }

    if ((Test-Path $defaultNodeDir) -And (Test-Path "$defaultNodeDir\node.exe")) {
      Set-NodePathEntry -NodeDirectory $defaultNodeDir
    }
  }

  function nChange {
    param (
      [string] $Version = '',
      [string] $Arch = "win-x64",
      [bool] $Force = $false
    )
    
    if ($Version -eq '') {
      Write-Log "Please specify a version. Example: ron -change 18" -IsError
      return
    }

    $versionDir = Join-Path $nodeDir $Version
    
    if ((Test-Path $versionDir) -And -Not $Force) {
      Write-Log "Changed to Node.js $Version"
      Set-NodePathEntry -NodeDirectory $versionDir
      return
    }

    # Download and install
    try {
      $remoteNodeVersions = (Invoke-WebRequest -Uri "https://nodejs.org/dist/" -UseBasicParsing).Links.Href

      $versionExists = $remoteNodeVersions | Where-Object { $_ -like "latest-v$Version.x/*" }
      
      if (-Not $versionExists) {
        throw "Version $Version is invalid! Run 'ron -list -remote' to see available versions."
      }

      # Clean up old installation if force is true
      if (Test-Path $versionDir) {
        Remove-Item -Path $versionDir -Recurse -Force | Out-Null
      }

      $tempDir = Join-Path $nodeDir "temp"
      if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force | Out-Null
      }

      New-Item -ItemType Directory -Path $tempDir | Out-Null
      
      # Get download URL
      $downloadUrl = "https://nodejs.org/dist/latest-v$Version.x/"
      $response = Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing
      $fullPath = ($response.Links.Href | Where-Object { $_ -like "*node-v$Version.*-$Arch.zip" } | Select-Object -First 1)
      
      if ([string]::IsNullOrEmpty($fullPath)) {
        throw "No matching Node.js file found for version $Version and architecture $Arch"
      }

      # Extract just the filename from the full path
      $fileName = Split-Path -Leaf $fullPath
      $downloadUrl = $downloadUrl + $fileName
      Write-Log "Downloading Node.js $Version from $downloadUrl" -ForegroundColor Cyan
      
      Invoke-WebRequest -Uri $downloadUrl -OutFile "$tempDir\$Version.zip" -UseBasicParsing
      Write-Log "Downloaded successfully" -ForegroundColor Green
      
      Start-Sleep -Milliseconds 500

      Write-Log "Extracting to $versionDir" -ForegroundColor Cyan
      Expand-Archive -Path "$tempDir\$Version.zip" -DestinationPath $versionDir -Force
      
      # Move extracted files up one directory
      Get-ChildItem -Path "$versionDir\node-v*" -Directory | ForEach-Object {
        Get-ChildItem -Path $_.FullName | Move-Item -Destination $versionDir -Force
      }
      Remove-Item -Path "$versionDir\node-v*" -Recurse -Force -ErrorAction SilentlyContinue

      Remove-Item -Path $tempDir -Recurse -Force | Out-Null
      Write-Log "Installation complete" -ForegroundColor Green

      # Update PATH
      Set-NodePathEntry -NodeDirectory $versionDir
      
      if (Test-CommandExists -Command node -Silent) {
        node -v
      } else {
        Write-Log "Node installed but not yet accessible. Please restart your terminal." -ForegroundColor Yellow
      }
    }
    catch {
      Write-Log "Error during installation: $_" -IsError
    }
  }

  function nList {
    param ([switch] $Remote)
    
    if ($Remote.IsPresent) {
      Write-Log "Fetching available Node.js versions..." -ForegroundColor Cyan
      (Invoke-WebRequest -Uri "https://nodejs.org/dist/" -UseBasicParsing).Links.Href | 
        Where-Object { $_ -like "latest-v*" -and $_ -notlike "latest-v0*" } | 
        ForEach-Object {
          $_.Replace('latest-', '').Replace('.x/', '')
        }
      Write-Log "These are current available Node.js versions (latest)" -ForegroundColor Green
    } else {
      if (Test-Path $nodeDir) {
        Write-Log "Installed Node.js versions:" -ForegroundColor Green
        Get-ChildItem -Path $nodeDir -Directory | Where-Object { $_.Name -notlike "temp" } | ForEach-Object { Write-Host $_.Name }
      } else {
        Write-Log "Node directory does not exist: $nodeDir" -IsError
      }
    }
  }

  function Show-NodeVersion {
    Write-Host "ron " -ForegroundColor Cyan -NoNewline
    Write-Log $ronVersion
    Write-Log "-----------------------------------------------"
    
    # Get the current node version in use
    $nodeInUse = "Not installed"
    $nodeInUseVersion = $null
    if (Test-CommandExists -Command node -Silent) {
      $nodeInUseVersion = node -v
      $nodeInUse = $nodeInUseVersion
    } else {
      Write-Log "Node.js is not installed! Run 'ron -help' for installation options." -ForegroundColor Yellow
    }
    
    # Show default and in-use versions with color coding
    if ($config) {
      $defaultVersion = $config.defaultVersion
      $defaultNodeDir = Join-Path $nodeDir $defaultVersion
      
      # Try to get the actual version number for the default version
      $defaultFullVersion = "v$defaultVersion.x.x"
      if (Test-Path "$defaultNodeDir\node.exe") {
        try {
          $defaultFullVersion = & "$defaultNodeDir\node.exe" -v
        } catch {
          $defaultFullVersion = "v$defaultVersion.x.x"
        }
      }
      
      # Get LTS version info for color coding
      $ltsInfo = Get-LtsVersions
      
      Write-Host "Node.js (Default) " -NoNewline
      
      # Color code default version
      if ($ltsInfo) {
        if ($defaultVersion -eq $ltsInfo.latestLtsShort) {
          # Latest LTS - Green
          Write-Host $defaultFullVersion -NoNewline -ForegroundColor Green
        } elseif ($ltsInfo.allLtsVersions -contains $defaultVersion) {
          # Is LTS but not latest - Cyan
          Write-Host $defaultFullVersion -NoNewline -ForegroundColor Cyan
        } else {
          # Not an LTS - Red
          Write-Host $defaultFullVersion -NoNewline -ForegroundColor Red
        }
      } else {
        Write-Host $defaultFullVersion -NoNewline -ForegroundColor Cyan
      }
      
      Write-Host " | (In Use) " -NoNewline
      
      # Color code in-use version
      if ($nodeInUseVersion) {
        # Extract major version numbers for comparison
        $inUseMajor = [int]($nodeInUseVersion -replace 'v(\d+)\..*', '$1')
        $defaultMajor = [int]$defaultVersion
        
        if ($inUseMajor -lt $defaultMajor) {
          Write-Host $nodeInUseVersion -ForegroundColor Red
        } else {
          Write-Host $nodeInUseVersion -ForegroundColor Green
        }
      } else {
        Write-Host $nodeInUse -ForegroundColor Yellow
      }
    }
  }

  function Show-Help {
    Write-Log "Run on Node - Help" -ForegroundColor Cyan
    Write-Log ""
    Write-Host "-init" -NoNewline -ForegroundColor White
    Write-Host " (-i)" -NoNewline -ForegroundColor DarkGray
    Write-Host "              | Initialize ron with config file and install default version."
    Write-Host "  -force" -NoNewline -ForegroundColor Yellow
    Write-Host " (-f)" -NoNewline -ForegroundColor DarkGray
    Write-Host "           | (with -init) Force recreate configuration file."
    
    Write-Host "-version" -NoNewline -ForegroundColor White
    Write-Host " (-v)" -NoNewline -ForegroundColor DarkGray
    Write-Host "           | Display current ron and node versions."
    
    Write-Host "-list" -NoNewline -ForegroundColor White
    Write-Host " (-l)" -NoNewline -ForegroundColor DarkGray
    Write-Host "              | List all installed Node.js versions."
    
    Write-Host "  -remote" -NoNewline -ForegroundColor White
    Write-Host " (-r)" -NoNewline -ForegroundColor DarkGray
    Write-Host "          | List all available Node.js versions for installation."
    
    Write-Host "-change" -NoNewline -ForegroundColor White
    Write-Host " (-c)" -NoNewline -ForegroundColor DarkGray
    Write-Host " <version>  | Switch to a Node.js version (auto-installs if needed)."
    Write-Log "                       Ex: ron -change 22 (installs latest v22.x.x)" -ForegroundColor Cyan
    
    Write-Host "  -default" -NoNewline -ForegroundColor Yellow
    Write-Host " (-d)" -NoNewline -ForegroundColor DarkGray
    Write-Host "        | (with version) Also set as default version in .ronrc."
    Write-Log "                       Ex: ron 22 -default or ron -change 22 -default" -ForegroundColor Cyan
    
    Write-Host "-autoupdate [val]" -NoNewline -ForegroundColor White
    Write-Host "   | Show or set auto-update (true/false). Checks daily for LTS updates."
    
    Write-Host "-help" -NoNewline -ForegroundColor White
    Write-Host " (-h)" -NoNewline -ForegroundColor DarkGray
    Write-Host "              | Display this help page."
  }

  # -------- COMMAND ROUTING --------
  
  if ($Help.IsPresent) {
    Show-Help
  } elseif ($List.IsPresent) {
    nList -Remote:$Remote.IsPresent
  } elseif ($Change -ne "" -and -Not $Dir.IsPresent) {
    nChange -Version $Change -Arch $arch -Force $Force.IsPresent
    if ($Default.IsPresent) {
      $config = Get-Config
      $config.defaultVersion = $Change
      Set-Config $config
      Write-Log "Default Node.js version set to $Change" -ForegroundColor Green
    }
  } elseif ($Dir.IsPresent) {
    if (-Not [string]::IsNullOrWhiteSpace($dirArg)) {
      # Clean up user input and ensure it ends with \node\
      $dirArg = $dirArg.Trim().TrimEnd('\')
      $nodeDirectory = $dirArg + "\node\"
      $config.nodeDirectory = $nodeDirectory
      Set-Config $config
      Write-Log "Node.js installation directory set to $nodeDirectory" -ForegroundColor Green
    } else {
      Write-Log "Node.js installation directory: $($config.nodeDirectory)" -ForegroundColor Green
    }
  } elseif ($AutoUpdate.IsPresent) {
    if (-Not [string]::IsNullOrWhiteSpace($autoUpdateArg)) {
      $boolValue = $autoUpdateArg -eq "true" -or $autoUpdateArg -eq "1" -or $autoUpdateArg -eq "yes" -or $autoUpdateArg -eq "y"
      $config.autoUpdate = $boolValue
      Set-Config $config
      if ($boolValue) {
        Write-Log "Auto-update enabled. Ron will check daily for Node.js LTS updates." -ForegroundColor Green
      } else {
        Write-Log "Auto-update disabled. Ron will not check for updates automatically." -ForegroundColor Yellow
      }
    } else {
      $status = if ($config.autoUpdate) { "enabled" } else { "disabled" }
      Write-Log "Auto-update is currently $status" -ForegroundColor Cyan
    }
  } elseif ($Version.IsPresent) {
    Show-NodeVersion
  } elseif ($Init.IsPresent) {
    try {
      if ($Force.IsPresent) {
        # Force initialization - delete and recreate config
        Initialize-Config -Force $true
        # Reload config after recreation
        $config = Get-Config
        $nodeDir = $config.nodeDirectory
        $defaultVersion = $config.defaultVersion
        $arch = $config.architecture
      }
      nInit
      if (-Not $silentInit) {
        Show-NodeVersion
      }
    }
    catch {
      Write-Log "Error during initialization: $_" -IsError
    }
  } else {
    # Default behavior - check if .ronrc exists
    if (Test-Path $ronrc) {
      # Config exists, show version
      Show-NodeVersion
    } else {
      # Config doesn't exist, initialize
      Write-Log "Configuration not found. Initializing ron..." -ForegroundColor Yellow
      try {
        $silentInit = $false
        nInit
        Show-NodeVersion
      }
      catch {
        Write-Log "Error during initialization: $_" -IsError
      }
    }
  }
}

# ============ INITIALIZATION ============

# Initialize configuration file
Initialize-Config

# Auto-initialize on module import
ron -init

# Check for LTS updates (once per day)
$config = Get-Config
Check-LtsUpdate -Config $config

Export-ModuleMember -Function ron -Variable ronrc




