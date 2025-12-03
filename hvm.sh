#!/bin/bash

set -euo pipefail

show_spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='|/-\'
    
    echo -n "$message "
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r$message [%c] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    printf "\r$message ✅ Done!\n"
}

run_with_spinner() {
    local cmd="$1"
    local message="$2"
    
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!
    
    show_spinner "$pid" "$message"
    
    wait "$pid"
    
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to execute: $cmd"
        exit 1
    fi
}

print_line_by_line() {
    local lines=("$@")
    for line in "${lines[@]}"; do
        echo "$line"
    done
    echo ""
}

clear

lines1=(
"================================================"
"       ______                           "
"      |___  /                           "
"         / /_   _  ___ _ __ ___  _ __   "
"        / /| | | |/ __| '__/ _ \| '_ \  "
"       / /_| |_| | (__| | | (_) | | | | "
"      /_____\__, |\___|_|  \___/|_| |_| "
"            __/ |                      "
"            |___/                      "
"================================================"
)
print_line_by_line "${lines1[@]}"
sleep 1
clear

lines2=(
"================================================="
" __  __ _      _                _ "
" |  \/  (_)    | |              | |"
" | \  / |_  ___| |__   __ _  ___| |"
" | |\/| | |/ __| '_ \ / _\` |/ _ \ |"
" | |  | | | (__| | | | (_| |  __/ |"
" |_|  |_|_|\___|_| |_|\__,_|\___|_|"
"                                   "
"                                   "
"================================================="
)
print_line_by_line "${lines2[@]}"
sleep 1
clear

lines3=(
"============================"
"  _    ___      ____  __ "
" | |  | \ \    / /  \/  |"
" | |__| |\ \  / /| \  / |"
" |  __  | \ \/ / | |\/| |"
" | |  | |  \  /  | |  | |"
" |_|  |_|   \/   |_|  |_|"
"============================"
)
print_line_by_line "${lines3[@]}"
sleep 1
clear

lines4=(
"==================================================================="
"  _    ___      ____  __    _____           _        _ _           "
" | |  | \ \    / /  \/  |  |_   _|         | |      | | |          "
" | |__| |\ \  / /| \  / |    | |  _ __  ___| |_ __ _| | | ___ _ __ "
" |  __  | \ \/ / | |\/| |    | | | '_ \/ __| __/ _\` | | |/ _ \ '__|"
" | |  | |  \  /  | |  | |   _| |_| | | \__ \ || (_| | | |  __/ |   "
" |_|  |_|   \/   |_|  |_|  |_____|_| |_|___/\__\__,_|_|_|\___|_|   "
"                                                                   "
"===================================================================="
)
print_line_by_line "${lines4[@]}"

echo ""
echo "🚀 Starting Installation Process..."
echo ""

run_with_spinner "sudo apt update" "Updating package lists"
run_with_spinner "sudo apt upgrade -y" "Upgrading installed packages"

echo ""
echo "📦 Installing System Dependencies..."
run_with_spinner "sudo apt install -y python3 python3-pip python3-venv git unzip docker.io docker-compose" "Installing system packages"

echo ""
echo "🐍 Installing Python Dependencies..."
run_with_spinner "pip3 install cryptography pycryptodome flask flask-socketio flask-login docker paramiko psutil python-dotenv email-validator flask_limiter" "Installing Python packages"

echo ""
echo "📥 Cloning Hvm-Official Repository..."
run_with_spinner "git clone https://github.com/StriderCraft315/Hvm-Official" "Cloning repository from GitHub"

echo ""
echo "📁 Changing to Hvm-Official directory..."
if cd "Hvm-Official" 2>/dev/null || cd "hvm-official" 2>/dev/null; then
    echo "✅ Directory changed successfully"
else
    echo "⚠️  Could not find Hvm-Official directory, trying case-insensitive..."
    found_dir=$(find . -maxdepth 1 -type d -iname "*hvm*" | head -1)
    if [ -n "$found_dir" ]; then
        cd "$found_dir"
        echo "✅ Found and entered directory: $found_dir"
    else
        echo "❌ Error: Could not find Hvm-Official directory"
        exit 1
    fi
fi

echo ""
echo "📦 Looking for Hvm.zip..."
if [ -f "Hvm.zip" ]; then
    run_with_spinner "unzip -q Hvm.zip" "Extracting Hvm.zip"
    echo "✅ Extraction completed"
elif [ -f "hvm.zip" ]; then
    run_with_spinner "unzip -q hvm.zip" "Extracting hvm.zip"
    echo "✅ Extraction completed"
else
    echo "⚠️  Hvm.zip not found in current directory"
    echo "📂 Contents of current directory:"
    ls -la
fi

clear

lines5=(
"======================================================="
"   _____              _            _   _       _      "
"  / ____|            | |          | | (_)     | |     "
" | |     _ __ ___  __| | ___ _ __ | |_ _  __ _| |___  "
" | |    | '__/ _ \/ _\` |/ _ \ '_ \| __| |/ _\` | / __| "
" | |____| | |  __/ (_| |  __/ | | | |_| | (_| | \__ \ "
"  \_____|_|  \___|\__,_|\___/|_| |_|\__|_|\__,_|_|___/ "
"                                                      "
"                  Username : admin                    "
"                  Password : admin                    "
"========================================================"
)
print_line_by_line "${lines5[@]}"

echo ""
echo "🔧 Setting up Docker..."
run_with_spinner "sudo systemctl start docker" "Starting Docker service"
run_with_spinner "sudo systemctl enable docker" "Enabling Docker on boot"

echo ""
echo "🔍 Checking for required Python files..."
if [ -f "update_keys.py" ]; then
    echo "   ✅ update_keys.py found"
else
    echo "   ⚠️  update_keys.py not found"
fi

if [ -f "lmaker.py" ]; then
    echo "   ✅ lmaker.py found"
else
    echo "   ⚠️  lmaker.py not found"
fi

if [ -f "hvm.py" ]; then
    echo "   ✅ hvm.py found"
else
    echo "   ⚠️  hvm.py not found"
fi

echo ""
echo "📋 Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo ""
echo "📦 Installing project-specific dependencies..."
if [ -f "requirements.txt" ]; then
    run_with_spinner "pip install -r requirements.txt" "Installing from requirements.txt"
fi

deactivate

echo ""
echo "🎉 Hvm Panel Installed Successfully!"
echo ""
echo "📝 Next Steps:"
echo "   1. Change the encryption keys by running: python3 update_keys.py"
echo "   2. Generate a license using: python3 lmaker.py"
echo "   3. Start the panel with: python3 hvm.py"
echo ""
echo "💡 Tip: Make sure to change the default credentials for security!"
echo ""
echo "🛠️  Additional Setup:"
echo "   - To use Docker features, add your user to docker group:"
echo "     sudo usermod -aG docker \$USER"
echo "   - Then log out and log back in"
echo ""

echo "✅ Installation completed successfully!"
echo ""
