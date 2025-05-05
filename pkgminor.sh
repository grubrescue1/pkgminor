#!/bin/bash

# Function to search and install package
search_and_install() {
    local pkg="$1"

    # Try pacman if enabled
    if [ "$use_pacman" == "enabled" ] && pacman -Si "$pkg" &>/dev/null; then
        echo "Found in pacman! Installing..."
        sudo pacman -S "$pkg"
        return 0
    fi

    # Try AUR if enabled
    if [ "$use_aur" == "enabled" ] && command -v "$aur_manager" &>/dev/null && "$aur_manager" -Si "$pkg" &>/dev/null; then
        echo "Found in AUR! Installing via $aur_manager..."
        "$aur_manager" -S "$pkg"
        return 0
    fi

    # Try Flatpak if enabled
    if [ "$use_flatpak" == "enabled" ] && command -v flatpak &>/dev/null && flatpak search "$pkg" | grep -q "$pkg"; then
        echo "Found in Flatpak. Installing..."
        flatpak install -y "$pkg"
        return 0
    fi

    # Try apt if enabled
    if [ "$use_apt" == "enabled" ] && command -v apt &>/dev/null && apt-cache show "$pkg" &>/dev/null; then
        echo "Found in apt! Installing..."
        sudo apt install "$pkg"
        return 0
    fi

    # Try pkg if enabled (FreeBSD)
    if [ "$use_pkg" == "enabled" ] && command -v pkg &>/dev/null && pkg search -q "^${pkg}$" &>/dev/null; then
        echo "Found in pkg! Installing..."
        sudo pkg install "$pkg"
        return 0
    fi

    # If package not found, show error
    if [ "$figlet_disabled" != "enabled" ]; then
        figlet "$figlet_error_text"
    fi

    echo "______________________________________________"
    echo "Package not found anywhere. Maybe touch grass instead?"
    sleep 1
    return 1
}
CONFIG_DIR="$HOME/.config/pkgminor"
CONFIG_FILE="$CONFIG_DIR/config.cfg"

# Default configuration values
DEFAULT_CLEAR="enabled"
DEFAULT_FIGLET_DISABLED="disabled"
DEFAULT_FIGLET_GREETING="PKGMINOR"
DEFAULT_FIGLET_ERROR="ERROR!"
DEFAULT_PACKAGE_TEXT="Enter package name:"
DEFAULT_USE_PACMAN="enabled"
DEFAULT_USE_AUR="enabled"
DEFAULT_AUR_MANAGER="yay"
DEFAULT_USE_FLATPAK="enabled"
DEFAULT_USE_APT="disabled"
DEFAULT_USE_PKG="disabled"

# Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

# Create or load config file
if [ ! -f "$CONFIG_FILE" ]; then
    # Create default config file
    cat > "$CONFIG_FILE" << EOF
# pkgminor configuration
clear=$DEFAULT_CLEAR
figlet_disabled=$DEFAULT_FIGLET_DISABLED
figlet_greeting_text=$DEFAULT_FIGLET_GREETING
figlet_error_text=$DEFAULT_FIGLET_ERROR
package_text=$DEFAULT_PACKAGE_TEXT
use_pacman=$DEFAULT_USE_PACMAN
use_aur=$DEFAULT_USE_AUR
aur_manager=$DEFAULT_AUR_MANAGER
use_flatpak=$DEFAULT_USE_FLATPAK
use_apt=$DEFAULT_USE_APT
use_pkg=$DEFAULT_USE_PKG
EOF
    echo "Created default config at $CONFIG_FILE"
fi

# Load configuration values
clear_screen="$DEFAULT_CLEAR"
figlet_disabled="$DEFAULT_FIGLET_DISABLED"
figlet_greeting_text="$DEFAULT_FIGLET_GREETING"
figlet_error_text="$DEFAULT_FIGLET_ERROR"
package_text="$DEFAULT_PACKAGE_TEXT"
use_pacman="$DEFAULT_USE_PACMAN"
use_aur="$DEFAULT_USE_AUR"
aur_manager="$DEFAULT_AUR_MANAGER"
use_flatpak="$DEFAULT_USE_FLATPAK"
use_apt="$DEFAULT_USE_APT"
use_pkg="$DEFAULT_USE_PKG"

# Read config file line by line
while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]] && continue
    
    # Extract key and value
    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        
        # Remove whitespace from key only, preserve value's spaces
        key=$(echo "$key" | tr -d '[:space:]')
        # Trim leading/trailing whitespace from value but preserve internal spaces
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Set the appropriate variable based on key
        case "$key" in
            clear) clear_screen="$value" ;;
            figlet_disabled) figlet_disabled="$value" ;;
            figlet_greeting_text) figlet_greeting_text="$value" ;;
            figlet_error_text) figlet_error_text="$value" ;;
            package_text) package_text="$value" ;;
            use_pacman) use_pacman="$value" ;;
            use_aur) use_aur="$value" ;;
            aur_manager) aur_manager="$value" ;;
            use_flatpak) use_flatpak="$value" ;;
            use_apt) use_apt="$value" ;;
            use_pkg) use_pkg="$value" ;;
        esac
    fi
done < "$CONFIG_FILE"

# Clear screen if enabled
if [ "$clear_screen" == "enabled" ]; then
    clear
fi

# Print debug info if needed (comment this out in production)
# echo "Debug: figlet_greeting_text = '$figlet_greeting_text'"

# Show greeting with figlet if enabled
if [ "$figlet_disabled" != "enabled" ]; then
    figlet "$figlet_greeting_text"
fi

echo "______________________________________________"

# Prompt for package name or use command line argument
if [ $# -gt 0 ]; then
    # Use first argument as package name
    pkg="$1"
    echo "Looking for package: $pkg"
else
    # No arguments provided, prompt for package name
    read -p "$package_text " pkg
fi

# Call search and install function
search_and_install "$pkg"
exit $?
