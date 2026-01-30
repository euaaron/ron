<#
.SYNOPSIS
    Updates the module version in both the .psd1 manifest and .psm1 module files.
    
.DESCRIPTION
    Automatically bumps the patch version unless the version was manually changed in the current commit.
    Checks if ModuleVersion in the manifest differs from the previous commit to detect manual changes.
    
.PARAMETER BumpType
    Type of version bump: 'major', 'minor', or 'patch' (default: 'patch')
    
.EXAMPLE
    .\Update-ModuleVersion.ps1 -BumpType patch
#>

param(
    [ValidateSet('major', 'minor', 'patch')]
    [string]$BumpType = 'patch'
)

$ErrorActionPreference = 'Stop'

# Paths
$manifestPath = Join-Path $PSScriptRoot '../../ron.psd1'
$modulePath = Join-Path $PSScriptRoot '../../ron.psm1'

Write-Host "Checking if version was manually changed..." -ForegroundColor Cyan

# Check if version was manually modified in the current commit
$versionManuallyChanged = $false
try {
    $currentVersion = (Test-ModuleManifest -Path $manifestPath).Version.ToString()
    $previousVersion = git show HEAD:ron.psd1 | Select-String "ModuleVersion\s*=" | ForEach-Object { 
        [regex]::Match($_, "'([^']+)'").Groups[1].Value 
    }
    
    if ($currentVersion -ne $previousVersion -and -not [string]::IsNullOrEmpty($previousVersion)) {
        Write-Host "Version was manually changed from $previousVersion to $currentVersion" -ForegroundColor Green
        $versionManuallyChanged = $true
    }
}
catch {
    Write-Host "Could not determine if version was manually changed, will proceed with auto-bump" -ForegroundColor Yellow
}

if ($versionManuallyChanged) {
    Write-Host "Skipping automatic version bump (version was manually updated)" -ForegroundColor Green
    exit 0
}

# Parse current version
$manifestContent = Get-Content $manifestPath -Raw
$versionMatch = [regex]::Match($manifestContent, "ModuleVersion\s*=\s*'([^']+)'")
$currentVersion = $versionMatch.Groups[1].Value

Write-Host "Current version: $currentVersion" -ForegroundColor Cyan

# Parse version components
$versionParts = $currentVersion -split '\.'
[int]$major = $versionParts[0]
[int]$minor = if ($versionParts.Count -gt 1) { $versionParts[1] } else { 0 }
[int]$patch = if ($versionParts.Count -gt 2) { $versionParts[2] } else { 0 }

# Bump version
switch ($BumpType) {
    'major' {
        $major++
        $minor = 0
        $patch = 0
    }
    'minor' {
        $minor++
        $patch = 0
    }
    'patch' {
        $patch++
    }
}

$newVersion = "$major.$minor.$patch"
Write-Host "New version: $newVersion" -ForegroundColor Green

# Update manifest file
$newManifestContent = $manifestContent -replace "ModuleVersion\s*=\s*'[^']+'", "ModuleVersion = '$newVersion'"
Set-Content -Path $manifestPath -Value $newManifestContent -Encoding UTF8
Write-Host "Updated $manifestPath" -ForegroundColor Green

# Update module file version variable
$moduleContent = Get-Content $modulePath -Raw
$newModuleContent = $moduleContent -replace '\$ronVersion\s*=\s*"v[^"]+"', "`$ronVersion = `"v$newVersion`""
Set-Content -Path $modulePath -Value $newModuleContent -Encoding UTF8
Write-Host "Updated $modulePath" -ForegroundColor Green

# Set output for GitHub Actions
if ($env:GITHUB_OUTPUT) {
    "NEW_VERSION=$newVersion" | Add-Content $env:GITHUB_OUTPUT
}

Write-Host "Version successfully updated to $newVersion" -ForegroundColor Green
