<p align="center">
  <img src="assets/davinci-resolve.png" width="64" alt="DaVinci Resolve">
</p>

<h1 align="center">DaVinci Resolve Studio Web Installer</h1>

An NSIS-based web installer for DaVinci Resolve Studio 21.1.1 on Windows. It downloads the official Blackmagic Design package, displays download and extraction progress, and launches the official installer.

## 🆕 What's New in v1.1

- **Live progress** is shown while downloading and extracting the package
- **Automatic cleanup** removes temporary installation files
- **Official package only** — no third-party DLL replacement or post-install patching
- **Silent mode support** is preserved for automated deployment

> ⚠️ **Important:** This project is an automation wrapper. DaVinci Resolve Studio still requires a valid Blackmagic Design license or activation key.

## Features

* 🚀 Downloads the official installer from Blackmagic Design
* 📊 Shows live download speed, size and percentage
* 📦 Extracts the package with visible progress
* 🎯 Launches the official Blackmagic Design setup
* 💾 Resumes interrupted downloads
* 🧹 Uses a temporary working directory and cleans it afterwards
* 🔒 Validates the download host and TLS certificate chain
* 📝 Provides detailed installation logging

## Installation

1. Build the installer or download it from the repository releases.
2. Run the generated executable as Administrator.
3. Accept the notice and wait for the official package to download.
4. Complete the official Blackmagic Design installation.
5. Activate DaVinci Resolve Studio with a valid license.

## Building

### Requirements

* [NSIS 3.x](https://nsis.sourceforge.io/)
* Windows 10 or Windows 11
* PowerShell 5.1
* At least 33 GB of free space recommended

### Compile

Open the `installer` directory and run:

```cmd
cd installer
build.cmd
```

The compiled executable is created in the same directory. Generated `.exe` files are intentionally excluded from Git.

## How It Works

1. Requests a signed download URL from Blackmagic Design.
2. Downloads the official archive with resume support.
3. Extracts the archive into `%TEMP%\DaVinciResolveSetup`.
4. Launches the official Blackmagic Design installer.
5. Removes temporary files after setup finishes.

No third-party libraries, patch files or replacement binaries are downloaded.

## Project Structure

```text
.
├── assets/                    Repository artwork
├── installer/                 NSIS source, notice and build script
├── README.md                  Project overview
└── LICENSE                    MIT license
```

## License

MIT License — see the [LICENSE](LICENSE) file.

## Author

Maksym Mykhailyk

[DaVinci Resolve Club](https://davinciresolveclub.com)

## Disclaimer

This project is not affiliated with or endorsed by Blackmagic Design. DaVinci Resolve and DaVinci Resolve Studio are trademarks of Blackmagic Design Pty Ltd. Users are responsible for complying with the official license terms and must use a valid license.
