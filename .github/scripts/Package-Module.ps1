<#
.SYNOPSIS
    Packages the ron PowerShell module as a .zip file.
    
.DESCRIPTION
    Creates a distribution-ready .zip file containing all necessary module files.
    The zip is created in a 'dist' directory.
    
.PARAMETER OutputPath
    Path where the .zip file will be created (default: ./dist)
    
.EXAMPLE
    .\Package-Module.ps1 -OutputPath ./dist
#>

param(
    [string]$OutputPath = 'dist'
)

$ErrorActionPreference = 'Stop'

# Get module root
$moduleRoot = Split-Path $PSScriptRoot -Parent
$moduleRoot = Split-Path $moduleRoot -Parent

Write-Host "Module root: $moduleRoot" -ForegroundColor Cyan

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Get version from manifest
$manifestPath = Join-Path $moduleRoot 'ron.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath
$version = $manifest.Version.ToString()

Write-Host "Packaging ron v$version" -ForegroundColor Cyan

# Define files to include
$filesToInclude = @(
    'ron.psd1',
    'ron.psm1',
    'LICENSE',
    'README.md'
)

# Create temp directory for staging
$tempStaging = Join-Path $env:TEMP "ron-staging-$([guid]::NewGuid().ToString().Substring(0, 8))"
$moduleStaging = Join-Path $tempStaging 'ron'
New-Item -ItemType Directory -Path $moduleStaging | Out-Null

Write-Host "Staging files..." -ForegroundColor Cyan

# Copy files
foreach ($file in $filesToInclude) {
    $sourcePath = Join-Path $moduleRoot $file
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $moduleStaging | Out-Null
        Write-Host "  Copied: $file" -ForegroundColor DarkGray
    }
}

# Create zip file
$zipPath = Join-Path $OutputPath "ron-$version.zip"
Write-Host "Creating zip: $zipPath" -ForegroundColor Cyan

# Remove existing zip if present
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create the zip (PowerShell 5.1+ compatible)
Compress-Archive -Path $moduleStaging -DestinationPath $zipPath -Force
Write-Host "Zip created successfully: $zipPath" -ForegroundColor Green

# Cleanup temp staging
Remove-Item $tempStaging -Recurse -Force

# Set output for GitHub Actions
if ($env:GITHUB_OUTPUT) {
    "ZIP_PATH=$zipPath" | Add-Content $env:GITHUB_OUTPUT
    "ZIP_NAME=ron-$version.zip" | Add-Content $env:GITHUB_OUTPUT
    "MODULE_VERSION=$version" | Add-Content $env:GITHUB_OUTPUT
}

Write-Host "Package ready: ron-$version.zip" -ForegroundColor Green
