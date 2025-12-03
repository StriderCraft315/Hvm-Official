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
        return 1
    fi
    return 0
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
"================================================="
"       ______                           "
"      |___  /                           "
"         / /_   _  ___ _ __ ___  _ __   "
"        / /| | | |/ __| '__/ _ \| '_ \  "
"       / /_| |_| | (__| | | (_) | | | | "
"     /_____\__, |\___|_|  \___/|_| |_| "
"            __/ |                      "
"            |___/                      "
"================================================="
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
"                         "
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
run_with_spinner "sudo apt install -y python3 python3-pip python3-venv git unzip curl apt-transport-https ca-certificates software-properties-common" "Installing system packages"

echo ""
echo "🐋 Installing Docker..."
# Remove old versions
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install Docker using official script
if ! command -v docker &> /dev/null; then
    echo "📥 Downloading Docker installer..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    echo "🔧 Installing Docker..."
    sudo sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker is already installed"
fi

# Install Docker Compose
echo ""
echo "📦 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "📥 Downloading Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose is already installed"
fi

echo ""
echo "🐍 Installing Python Dependencies..."
run_with_spinner "pip3 install cryptography pycryptodome flask flask-socketio flask-login docker paramiko psutil python-dotenv email-validator flask_limiter" "Installing Python packages"

echo ""
echo "📥 Cloning Hvm-Official Repository..."
if [ ! -d "Hvm-Official" ]; then
    run_with_spinner "git clone https://github.com/StriderCraft315/Hvm-Official" "Cloning repository from GitHub"
else
    echo "✅ Hvm-Official directory already exists"
fi

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

echo ""
echo "🔧 Setting up Docker service..."
run_with_spinner "sudo systemctl start docker" "Starting Docker service"
run_with_spinner "sudo systemctl enable docker" "Enabling Docker on boot"

# Add current user to docker group
if ! groups $USER | grep -q '\bdocker\b'; then
    echo "👤 Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo "✅ User added to docker group. Please log out and back in for changes to take effect."
else
    echo "✅ User is already in docker group"
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
echo "📦 Installing project-specific dependencies..."
if [ -f "requirements.txt" ]; then
    run_with_spinner "pip3 install -r requirements.txt" "Installing from requirements.txt"
fi

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
echo "🛠️  Docker Setup Complete:"
docker --version
docker-compose --version
echo "   - Docker service is running"
echo "   - Your user has been added to the docker group"
echo "   - Log out and back in to use docker without sudo"
echo ""

echo "✅ Installation completed successfully!"
echo ""
