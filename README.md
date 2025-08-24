# YEP CLI Installer

A simple bash installer script for the YEP CLI tool that handles downloading, dependency installation, and system-wide deployment.

## Quick Install

```bash
# Download and run the installer
curl -fsSL https://yep-pkg.github.io/install/i.sh | bash
```

## Requirements

- **Node.js 16+** - The installer will check and require Node.js version 16 or higher
- **pnpm** (preferred) or **npm** - For dependency installation
- **curl** and **tar** - For downloading and extracting source
- **sudo privileges** - Required for system-wide installation

## Installation Process

The installer performs these steps:

1. **System Check** - Verifies Node.js version and required tools
2. **Download Source** - Downloads the latest YEP CLI source code
3. **Copy Files** - Copies source files to `/usr/local/lib/yep-cli/`:
   - `index.js` (main executable)
   - `lib/` directory (library files)
   - `package.json` (dependencies manifest)
4. **Install Dependencies** - Runs `pnpm install --production` in the target directory
5. **Create Command** - Creates wrapper script at `/usr/local/bin/yep`
6. **Verify** - Tests that the `yep` command is available

## Usage

### Basic Installation

```bash
# Install latest version
./install.sh
```

### Install Specific Version

```bash
# Install version 1.2.3
./install.sh 1.2.3
```

### Uninstall

```bash
# Remove yep-cli completely
./install.sh --uninstall
```

### Help

```bash
# Show usage information
./install.sh --help
```

## Installation Locations

- **Main files**: `/usr/local/lib/yep-cli/`
  - `index.js` - Main executable script
  - `lib/` - Library directory with modules
  - `node_modules/` - Dependencies (installed by pnpm)
  - `package.json` - Package configuration

- **Command**: `/usr/local/bin/yep`
  - Wrapper script that runs the main executable

## Manual Installation

If you prefer to install manually, the installer essentially does:

```bash
# Create directory
sudo mkdir -p /usr/local/lib/yep-cli

# Copy source files
sudo cp index.js /usr/local/lib/yep-cli/
sudo cp -r lib /usr/local/lib/yep-cli/
sudo cp package.json /usr/local/lib/yep-cli/

# Install dependencies
cd /usr/local/lib/yep-cli
sudo pnpm install --production

# Create command wrapper
sudo tee /usr/local/bin/yep << 'EOF'
#!/bin/bash
cd "/usr/local/lib/yep-cli" && node index.js "$@"
EOF
sudo chmod +x /usr/local/bin/yep
```

## Configuration

### Customize Installation

Edit the installer script to change default locations:

```bash
# Configuration variables at the top of install.sh
REPO_URL="https://github.com/yourusername/yep-cli"
INSTALL_DIR="/usr/local/lib/yep-cli"
BIN_DIR="/usr/local/bin"
BINARY_NAME="yep"
```

### Repository Setup

Update `REPO_URL` to point to your actual repository. The installer expects:

- **Main branch**: Available at `/archive/refs/heads/main.tar.gz`
- **Tagged versions**: Available at `/archive/refs/tags/v{VERSION}.tar.gz`

## Troubleshooting

### Permission Denied

```bash
# Make sure the installer is executable
chmod +x install.sh

# Or run with bash directly
bash install.sh
```

### Node.js Not Found

```bash
# Install Node.js first
# macOS with Homebrew:
brew install node

# Ubuntu/Debian:
sudo apt update && sudo apt install nodejs npm

# Or download from: https://nodejs.org/
```

### pnpm Not Found

The installer will fall back to npm, but for best results install pnpm:

```bash
# Install pnpm globally
npm install -g pnpm

# Or via curl:
curl -fsSL https://get.pnpm.io/install.sh | sh
```

### Command Not Found After Install

The installation adds `yep` to `/usr/local/bin/`, which should be in your PATH. Try:

```bash
# Reload your shell
source ~/.bashrc
# or
source ~/.zshrc

# Or restart your terminal

# Check if /usr/local/bin is in PATH
echo $PATH | grep -o "/usr/local/bin"
```

### Dependency Installation Fails

If `pnpm install` fails in the target directory:

```bash
# Try manual installation
cd /usr/local/lib/yep-cli
sudo pnpm install --production

# Or with npm
sudo npm install --production
```

### Uninstall Issues

Manual cleanup if uninstaller fails:

```bash
# Remove command
sudo rm -f /usr/local/bin/yep

# Remove installation directory
sudo rm -rf /usr/local/lib/yep-cli
```

## Development

### Testing the Installer

Test the installer without affecting your system:

```bash
# Test with different install directory
INSTALL_DIR="/tmp/test-yep" ./install.sh

# Test specific version
./install.sh 1.0.0

# Test uninstall
./install.sh --uninstall
```

### Customizing for Your Project

1. **Update repository URL** in the `REPO_URL` variable
2. **Modify file copying** in the `install_files()` function if you have different source structure
3. **Adjust requirements** in `check_requirements()` if you need different Node.js versions
4. **Customize wrapper script** if your main file isn't `index.js`

## Security Notes

- The installer requires sudo privileges for system-wide installation
- Downloaded files are verified during extraction
- Temporary files are cleaned up after installation
- Source code is downloaded from the specified repository only

## License

This installer script is provided as-is. Modify and distribute according to your project's license.

## Support

For issues with the installer:

1. Check the troubleshooting section above
2. Verify your system meets the requirements
3. Try manual installation steps
4. Open an issue in the project repository
