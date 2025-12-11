#!/bin/bash

# Get the absolute path to AlexScript directory
ALEXSCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing AlexScript..."
echo "Installation directory: $ALEXSCRIPT_ROOT"

# Create wrapper script that preserves user's working directory
cat > /tmp/alexscript << 'WRAPPER_EOF'
#!/usr/bin/env ruby

# KRYTYCZNE: Zapisz katalog użytkownika PRZED jakimikolwiek zmianami
ENV['ALEXSCRIPT_USER_PWD'] = Dir.pwd

# Path to AlexScript installation
ALEXSCRIPT_ROOT = "INSTALL_PATH_PLACEHOLDER"

# Add to load path
$LOAD_PATH.unshift(File.join(ALEXSCRIPT_ROOT, "lib"))

# Change to AlexScript directory
Dir.chdir(ALEXSCRIPT_ROOT)

# Load and run (używamy konkatenacji zamiast interpolacji)
load File.join(ALEXSCRIPT_ROOT, "bin", "alexscript.rb")
WRAPPER_EOF

# Replace placeholder with actual path (macOS compatible)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|INSTALL_PATH_PLACEHOLDER|${ALEXSCRIPT_ROOT}|g" /tmp/alexscript
else
    sed -i "s|INSTALL_PATH_PLACEHOLDER|${ALEXSCRIPT_ROOT}|g" /tmp/alexscript
fi

# Install to /usr/local/bin
if [ -w /usr/local/bin ]; then
    cp /tmp/alexscript /usr/local/bin/alexscript
    chmod +x /usr/local/bin/alexscript
    echo "Installed to /usr/local/bin/alexscript"
else
    echo "Cannot write to /usr/local/bin (try: sudo ./install.sh)"
    echo "Alternative: Install to ~/.local/bin (no sudo needed)"
    exit 1
fi

rm /tmp/alexscript
echo "Installation complete!"
echo ""
echo "Verify installation:"
echo "  cat /usr/local/bin/alexscript"
echo ""
echo "Test:"
echo "  cd /tmp"
echo "  alexscript"