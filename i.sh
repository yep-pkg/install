#!/bin/bash

# YEP CLI Installer Script
# Usage: curl -fsSL https://your-domain.com/install.sh | bash
# Or: bash install.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/yep-pkg/YEP"  # Update this
INSTALL_DIR="/usr/local/lib/yep-cli"
BIN_DIR="/usr/local/bin"
BINARY_NAME="yep"
TEMP_DIR="/tmp/yep-cli-install"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        if command -v sudo &> /dev/null; then
            SUDO="sudo"
            log_info "This installer requires sudo privileges to install to system directories"
        else
            log_error "This installer requires root privileges or sudo to install system-wide"
            exit 1
        fi
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required but not installed"
        log_info "Please install Node.js from https://nodejs.org/"
        exit 1
    fi
    
    local node_version=$(node --version | cut -d 'v' -f 2)
    local major_version=$(echo $node_version | cut -d '.' -f 1)
    
    if [ "$major_version" -lt 16 ]; then
        log_error "Node.js version 16 or higher is required (current: $node_version)"
        exit 1
    fi
    
    log_success "Node.js $node_version detected"
    
    # Check for required tools
    for tool in curl tar; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done
}

# Download and extract source
download_source() {
    log_info "Downloading yep-cli source..."
    
    # Create temp directory
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download source (adjust based on your distribution method)
    if [[ -n "$1" && "$1" != "latest" ]]; then
        VERSION="$1"
        DOWNLOAD_URL="$REPO_URL/archive/refs/tags/v$VERSION.tar.gz"
    else
        DOWNLOAD_URL="$REPO_URL/archive/refs/heads/main.tar.gz"
    fi
    
    if ! curl -fsSL "$DOWNLOAD_URL" -o yep-cli.tar.gz; then
        log_error "Failed to download yep-cli source"
        exit 1
    fi
    
    # Extract
    if ! tar -xzf yep-cli.tar.gz --strip-components=1; then
        log_error "Failed to extract yep-cli source"
        exit 1
    fi
    
    log_success "Source downloaded and extracted"
}

# Copy files and install dependencies
install_files() {
    log_info "Installing yep-cli files..."
    
    cd "$TEMP_DIR"
    
    # Remove old installation
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warning "Removing existing installation"
        $SUDO rm -rf "$INSTALL_DIR"
    fi
    
    if [[ -f "$BIN_DIR/$BINARY_NAME" ]]; then
        $SUDO rm -f "$BIN_DIR/$BINARY_NAME"
    fi
    
    # Create install directory
    $SUDO mkdir -p "$INSTALL_DIR"
    
    # Copy index.js
    $SUDO cp index.js "$INSTALL_DIR/"
    $SUDO chmod +x "$INSTALL_DIR/index.js"
    
    # Copy lib directory
    if [[ -d "lib" ]]; then
        $SUDO cp -r lib "$INSTALL_DIR/"
        log_success "Copied lib directory"
    fi
    
    # Copy package.json
    if [[ -f "package.json" ]]; then
        $SUDO cp package.json "$INSTALL_DIR/"
        log_success "Copied package.json"
    fi
    
    log_success "Files copied to $INSTALL_DIR"
}

# Install dependencies in the target directory
install_dependencies() {
    log_info "Installing dependencies in $INSTALL_DIR..."
    
    # Change to the install directory
    cd "$INSTALL_DIR"
    
    # Check for pnpm first
    if command -v pnpm &> /dev/null; then
        log_info "Using pnpm to install dependencies"
        $SUDO pnpm install --production
    elif command -v npm &> /dev/null; then
        log_info "pnpm not found, using npm instead"
        $SUDO npm install --production
    else
        log_error "No package manager found (pnpm or npm required)"
        exit 1
    fi
    
    log_success "Dependencies installed in $INSTALL_DIR"
    
    # Create wrapper script in bin directory
    $SUDO tee "$BIN_DIR/$BINARY_NAME" > /dev/null << 'EOF'
#!/bin/bash
cd "/usr/local/lib/yep-cli" && node index.js "$@"
EOF
    
    $SUDO chmod +x "$BIN_DIR/$BINARY_NAME"
    log_success "Wrapper script created at $BIN_DIR/$BINARY_NAME"
}

# Cleanup
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    log_success "Cleanup completed"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    if command -v "$BINARY_NAME" &> /dev/null; then
        local version_output=$($BINARY_NAME --version 2>/dev/null || echo "installed")
        log_success "yep-cli is successfully installed and available in PATH"
        log_info "Version: $version_output"
        log_info "Try running: $BINARY_NAME --help"
    else
        log_error "Installation verification failed - $BINARY_NAME not found in PATH"
        log_info "You may need to restart your shell or run: source ~/.bashrc"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo "YEP CLI Installer"
    echo ""
    echo "Usage: $0 [OPTIONS] [VERSION]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --uninstall    Uninstall yep-cli"
    echo ""
    echo "Examples:"
    echo "  $0                    # Install latest version"
    echo "  $0 1.2.3              # Install specific version"
    echo "  $0 --uninstall        # Uninstall"
}

# Uninstall function
uninstall() {
    log_info "Uninstalling yep-cli..."
    
    check_permissions
    
    # Remove wrapper script
    if [[ -f "$BIN_DIR/$BINARY_NAME" ]]; then
        $SUDO rm -f "$BIN_DIR/$BINARY_NAME"
        log_success "Removed $BIN_DIR/$BINARY_NAME"
    fi
    
    # Remove installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        $SUDO rm -rf "$INSTALL_DIR"
        log_success "Removed $INSTALL_DIR"
    fi
    
    log_success "yep-cli has been uninstalled"
}

# Main installation function
main() {
    local version="latest"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --uninstall)
                uninstall
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                version="$1"
                shift
                ;;
        esac
    done
    
    log_info "Starting yep-cli installation..."
    
    check_permissions
    check_requirements
    download_source "$version"
    install_files
    install_dependencies
    cleanup
    verify_installation
    
    log_success "Installation completed successfully!"
    echo ""
    echo "🎉 yep-cli is now installed and ready to use!"
    echo "   Run 'yep help' to get started"
}

# Run main function with all arguments
main "$@"
