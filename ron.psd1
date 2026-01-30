@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'ron.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.1'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'a8f7c9e1-4d2b-4a3c-9f6e-1b8d7c2a4e5f'
    
    # Author of this module
    Author = 'Aaron Carneiro'
    
    # Company or vendor of this module
    CompanyName = 'Unknown'
    
    # Copyright statement for this module
    Copyright = '(c) 2026 Aaron Carneiro. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Run on Node (ron) - A PowerShell-based Node.js version manager for Windows. Easily install, switch, and manage multiple Node.js versions.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.x'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('ron')
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @('ronrc')
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Node', 'NodeJS', 'VersionManager', 'NVM', 'fnm', 'n', 'ron', 'Windows', 'JavaScript', 'Development')
            
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/euaaron/ron/blob/main/LICENSE'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/euaaron/ron'
            
            # A URL to an icon representing this module.
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
## v1.0.0
- Created ron (Run on Node) as a simlpe .ps1 script to manage Node.js versions on Windows
- Created .ronrc to store configuration settings that persist across sessions
- Converted ron to a PowerShell module (.psm1)
- Added module manifest for PowerShell Gallery publication
'@
            
            # Prerelease string of this module
            # Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}

