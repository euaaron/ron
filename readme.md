# Run On Node (ron)

Run On Node, or just ron, is a PowerShell-based Node.js version manager for Windows, that makes it easy to install, switch, and manage multiple Node.js versions. 

## Why use ron?

The reason why I made this version manager is because back in February of 2023 I needed to update Node.js at my work's machine, but I did not had Administrator access to install anything... in fact every time I needed to install or update something I needed to open a support ticket and wait hours or days until someone could access my machine and remote control it to do that for me.

Annoyed with this, I tried to install a popular node version manager like volta, fnm, nvm... but they did not approved me to do it.
So I opened Powershell's $profile on VSCode and wrote a script with a few functions that was able to list all available node.js versions, directly from [nodejs.org](nodejs.org), download, create a folder outside ProgramFiles (so I don't need Admin access to manipulate files in it), extract files and change $env:Path inside the Powershell section. This way I was able to use whatever nodejs version I wanted, without requiring elevate access.

The script worked so well that other teammates decided to use it in their daily routine, but it wasn't complete, it required a few manual tweaks to work, and every user found a new issue that I needed to fix, so I created [this gist](https://gist.github.com/euaaron/8b0a2497244b3711e65ad798bdc5873f), where I could update and share the fixes easily with others.

Now ron does even more!
In the first run it checks for the latest LTS version and set it as default in it's new config file .ronrc, it also detects your machine architecture so you don't need to check yourself if it is ARM or AMD, 32 or 64 bits, and asks you the directory to save the node.js versions, so you never need to open the script and edit it.

Now ron has even a node.js **auto-update** feature: every day it search at nodejs.org once to check if there is a new LTS version, if so, it will prompt you if you would like to upgrade or not.

ron is now my go-to solution to install Node.js in a machine, being a work machine, or my own.

So... why don't you try it yourself?

## Requirements

- Windows PowerShell 5.1 or PowerShell Core 7+
- Windows OS (x64, x86, or ARM64)
- Internet connection for downloading Node.js

## Supported Architectures

- `win-x64` (64-bit, default)
- `win-x86` (32-bit)*
- `win-arm64` (ARM 64-bit)*

> Note that not all Node.js versions support architectures win-x86 or win-arm64.

## Installation

### From PowerShell Gallery

> Not available yet

### Manual Installation

0. Create a folder somewhere, for example `~\.ron`
1. Clone or download this repository and paste everything inside that folder
2. Import the module by writing the following inside your Powershell `$profile`:
  ```powershell
  Import-Module "path\to\folder\ron.psm1"
  ```
3. Run `. $profile` or close Powershell and open it again, so it can load the changes.

> You can open `$profile` by running `notepad $profile` or `code $profile`.

## Usage

### Initialize ron

The first time you open Powershell after adding ron to `$profile`, it will automatically run `ron -init` to create `.ronrc` and set the default configs, but if you missed it, you can run `ron -init` or `ron -init -force`. I have also added some shorthands, like `ron -i -f`

### View Current Version

```powershell
ron -version # or -v
```

>  This displays ron version, the default node.js version and the version of the note.js that is currently in use.

### List Installed Versions

```powershell
ron -list # or -l
```

### List Available Versions (Remote)

```powershell
ron -list -remote # or -l -r
```

### Install/Switch to a Version

```powershell
ron -change 22 # or ron -c 22 or just ron 22
```

### Force Reinstall

```powershell
ron -change 18 -force # or just ron 18 -f
```

### Set Default Version

```powershell
ron -default 20 # or ron -d 20
```

### Change Installation Directory

```powershell
ron -dir "C:\.ron\" # Write the full path
```

### Specify Architecture

```powershell
ron -change 18 -arch win-x86
```

### Display Help

```powershell
ron -help
```

## Configuration

ron stores its configuration in `.ronrc` (JSON format) in the module directory.

Default configuration:
```json
{
  "nodeDirectory": "C:\\Users\\YourUser\\.ron\\node\\",
  "defaultVersion": "24",
  "architecture": "win-x64",
  "autoUpdate": true,
  "lastUpdateCheck": "AAAA-MM-DD"
}
```

## License

[MIT License](./LICENSE) - see LICENSE file for details

## Author

Aaron Carneiro ([@euaaron](https://github.com/euaaron))

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## TODO

- [ ] Add a function to verify on load if a new version of ron is available and suggest to autoupdate
- [ ] Add support to automatically switch the current node version based on project's package.json when a version is set on it.
- [ ] Create automated tests to ensure reliability

## Troubleshooting

### Many errors on first run

Check if you're using Windows Powershell or Powershell 7.x aka `pwsh.exe` (not `powershell.exe`).
This script was built for Powershell 7.

### Node command not found after installation

Restart your PowerShell terminal to refresh the PATH environment variable, or run `. $profile` (that dot with a space is not a typo).

### Permission errors

- Run `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser`, or set it to **Unrestricted** instead of **Bypass**.
- Run PowerShell as Administrator or change the installation directory to a location where you have write permissions.

## Related Projects

- [nvm (Node Version Manager)](https://github.com/nvm-sh/nvm) - For Linux/macOS
- [nvm-windows](https://github.com/coreybutler/nvm-windows) - Alternative Node Version Manager for Windows

---

Made with ❤️ for the Node.js community
