#!/usr/bin/env bash
# AlexScript Quick Installer
# Run this from AlexScript root directory

set -e

echo  "Installing AlexScript..."

# Get current directory (should be AlexScript root)
ALEXSCRIPT_ROOT="$(pwd)"

# Check if we're in the right place
if [ ! -f "bin/alexscript.rb" ] || [ ! -d "lib" ]; then
    echo "Error: Please run this script from AlexScript root directory"
    echo "(The directory that contains bin/ and lib/)"
    exit 1
fi

# Installation target
INSTALL_DIR="/usr/local/bin"

# Check if we need sudo
if [ ! -w "$INSTALL_DIR" ]; then
    SUDO="sudo"
    echo "Requires sudo for installation to $INSTALL_DIR"
else
    SUDO=""
fi

# Create the alexscript executable
echo "Creating alexscript command..."
cat > /tmp/alexscript << EOF
#!/usr/bin/env ruby
# AlexScript Global Command

# Path to AlexScript installation
ALEXSCRIPT_ROOT = "${ALEXSCRIPT_ROOT}"

# Add to load path
\$LOAD_PATH.unshift("\#{ALEXSCRIPT_ROOT}/lib")

# Change to AlexScript directory
Dir.chdir(ALEXSCRIPT_ROOT)

# Load and run
load ALEXSCRIPT_ROOT + "/bin/alexscript.rb"
EOF

# Install
$SUDO mv /tmp/alexscript "$INSTALL_DIR/alexscript"
$SUDO chmod +x "$INSTALL_DIR/alexscript"

echo "AlexScript installed successfully!"
echo ""
echo "Usage:"
echo "  alexscript script.as           # Run script"
echo "  alexscript script.as -t        # With timing"
echo "  alexscript script.as -f        # Full debug mode"
echo ""
echo "Try: alexscript --help"
echo ""
echo "To uninstall: sudo rm /usr/local/bin/alexscript"
