#!/bin/bash

# Direct curl installer for pkgminor
# Usage: curl -fsSL https://raw.githubusercontent.com/yourusername/pkgminor/main/install.sh | bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Installing pkgminor...${NC}"

# Installation paths
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.config/pkgminor"
SCRIPT_URL="https://raw.githubusercontent.com/grubrescue1/pkgminor/refs/heads/main/pkgminor.sh"
TEMP_DIR="/tmp/pkgminor-install-$(date +%s)"

# Check for required dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"

# Core dependencies
CORE_DEPS=("figlet" "curl")
MISSING_DEPS=()

# Check for core dependencies
for dep in "${CORE_DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

# If there are missing core dependencies, alert the user
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}Error: Missing required dependencies: ${MISSING_DEPS[*]}${NC}"
    echo "Please install them using your package manager:"
    
    # Detect the package manager and suggest installation commands
    if command -v pacman &> /dev/null; then
        echo "  sudo pacman -S ${MISSING_DEPS[*]}"
    elif command -v apt &> /dev/null; then
        echo "  sudo apt install ${MISSING_DEPS[*]}"
    elif command -v dnf &> /dev/null; then
        echo "  sudo dnf install ${MISSING_DEPS[*]}"
    else
        echo "  Please install the missing dependencies using your package manager"
    fi
    
    exit 1
fi

# Check for optional dependencies based on user's system
if ! command -v yay &> /dev/null && command -v pacman &> /dev/null; then
    echo -e "${YELLOW}Note: 'yay' is not installed. AUR packages won't be available.${NC}"
    echo "If you want to use AUR, install 'yay' from AUR."
fi

if ! command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}Note: 'flatpak' is not installed. Flatpak packages won't be available.${NC}"
    echo "If you want to use Flatpak, install it from your package manager."
fi

# Create temporary directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# Download pkgminor script
echo -e "${YELLOW}Downloading pkgminor...${NC}"
if ! curl -fsSL "$SCRIPT_URL" -o pkgminor.sh; then
    echo -e "${RED}Error: Failed to download pkgminor.${NC}"
    echo "Please check your internet connection."
    exit 1
fi

# Check if sudo is available
if command -v sudo &> /dev/null; then
    USE_SUDO=1
else
    USE_SUDO=0
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: Cannot install to $INSTALL_DIR without sudo.${NC}"
        echo "Please run this script as root or install sudo."
        exit 1
    fi
fi

# Make script executable
chmod +x pkgminor.sh

# Install the script
echo -e "${YELLOW}Installing to $INSTALL_DIR...${NC}"
if [ "$USE_SUDO" -eq 1 ]; then
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp pkgminor.sh "$INSTALL_DIR/pkgminor"
    sudo chmod +x "$INSTALL_DIR/pkgminor"
else
    mkdir -p "$INSTALL_DIR"
    cp pkgminor.sh "$INSTALL_DIR/pkgminor" 
    chmod +x "$INSTALL_DIR/pkgminor"
fi

# Create config directory and default config file
echo -e "${YELLOW}Creating configuration...${NC}"
mkdir -p "$CONFIG_DIR"

# Create default config file if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.cfg" ]; then
    cat > "$CONFIG_DIR/config.cfg" << EOF
# pkgminor configuration
clear=enabled
figlet_disabled=disabled
figlet_greeting_text=PKGMINOR
figlet_error_text=ERROR!
package_text=Enter package name:
use_pacman=enabled
use_aur=enabled
aur_manager=yay
use_flatpak=enabled
use_apt=disabled
use_pkg=disabled
EOF
    echo -e "${GREEN}Created default config at $CONFIG_DIR/config.cfg${NC}"
fi

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Installation complete!${NC}"
echo "Usage:"
echo "  pkgminor                # Interactive mode"
echo "  pkgminor package-name   # Direct mode"
echo -e "\nConfiguration: Edit $CONFIG_DIR/config.cfg to customize pkgminor"
