
#!/bin/bash

# Exit on error
set -e

# Detect OS
OS=$(uname)
ARCH=$(uname -m)

# Function to install packages
install_package() {
    local package_name=$1
    echo "Checking if $package_name is installed..."
    if ! command -v $package_name &> /dev/null; then
        echo "$package_name not found! Installing..."
        if [[ "$OS" == "Linux" ]]; then
            if command -v apt &> /dev/null; then
                apt update && apt install -y $package_name
            elif command -v dnf &> /dev/null; then
                dnf install -y $package_name
            elif command -v pacman &> /dev/null; then
                pacman -Sy $package_name
            else
                echo "No supported package manager found (apt/dnf/pacman)."
                echo "Please install $package_name manually and run this script again."
                exit 1
            fi
        elif [[ "$OS" == "Darwin" ]]; then
            if ! command -v brew &> /dev/null; then
                echo "Homebrew not found! Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install $package_name
        else
            echo "Unsupported operating system: $OS"
            exit 1
        fi
    else
        echo "$package_name is already installed!"
    fi
}

# Install required packages
install_package "curl"
install_package "git"
install_package "vim"

# Set up SSH key
SSH_KEY="/root/.ssh/sf-compute"
if [[ ! -f "$SSH_KEY" ]]; then
    echo "SSH key not found at $SSH_KEY"
    exit 1
fi

# Ensure proper SSH key permissions
chmod 600 "$SSH_KEY"

# Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

# Determine the correct Miniforge installer URL
if [[ "$OS" == "Linux" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
    elif [[ "$ARCH" == "aarch64" ]]; then
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
elif [[ "$OS" == "Darwin" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
    elif [[ "$ARCH" == "arm64" ]]; then
        MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

install_miniconda() {
    local INSTALL_DIR="$HOME/miniforge3"
    local MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
    local BASHRC_FILE="$HOME/.bashrc"

    echo "Downloading Miniforge3 installer from: $MINIFORGE_URL"
    curl -L -o Miniforge3.sh "$MINIFORGE_URL"
    
    echo "Installing Miniforge3..."
    bash Miniforge3.sh -b -p "$INSTALL_DIR"
    rm Miniforge3.sh

    # Add Conda initialization to .bashrc if not already present
    if ! grep -q "# >>> conda initialize >>>" "$BASHRC_FILE"; then
        echo "Adding Conda initialization to .bashrc..."
        echo "" >> "$BASHRC_FILE"
        echo "# >>> conda initialize >>>" >> "$BASHRC_FILE"
        echo "# !! Contents within this block are managed by 'conda init' !!" >> "$BASHRC_FILE"
        echo "__conda_setup=\"\$('$INSTALL_DIR/bin/conda' 'shell.bash' 'hook' 2> /dev/null)\"" >> "$BASHRC_FILE"
        echo "if [ \$? -eq 0 ]; then" >> "$BASHRC_FILE"
        echo "    eval \"\$__conda_setup\"" >> "$BASHRC_FILE"
        echo "else" >> "$BASHRC_FILE"
        echo "    if [ -f \"$INSTALL_DIR/etc/profile.d/conda.sh\" ]; then" >> "$BASHRC_FILE"
        echo "        . \"$INSTALL_DIR/etc/profile.d/conda.sh\"" >> "$BASHRC_FILE"
        echo "    else" >> "$BASHRC_FILE"
        echo "        export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> "$BASHRC_FILE"
        echo "    fi" >> "$BASHRC_FILE"
        echo "fi" >> "$BASHRC_FILE"
        echo "unset __conda_setup" >> "$BASHRC_FILE"
        echo "# <<< conda initialize <<<" >> "$BASHRC_FILE"
    fi

    # Source .bashrc to apply changes to current session
    source "$BASHRC_FILE"

    # Initialize shell for conda
    eval "$("$INSTALL_DIR/bin/conda" "shell.bash" "hook")"

    # Update Conda
    echo "Updating Conda..."
    conda update -y conda

    # Create the Conda environment named "ttt"
    echo "Creating the 'ttt' Conda environment..."
    conda create -y --name ttt python=3.10 uv

    # Activate the environment
    echo "Activating environment 'ttt'..."
    conda activate ttt

    # Verify the environment is activated
    echo "Current Python path: $(which python)"
    echo "Current Conda environment: $CONDA_DEFAULT_ENV"
    
    echo "Installation complete! Conda is now properly initialized in your .bashrc"
    echo "To use conda in new terminal sessions, either restart your terminal or run:"
    echo "source ~/.bashrc"
}




# Set installation directory
INSTALL_DIR="$HOME/miniforge3"

if [[ -d "$INSTALL_DIR" ]]; then
	echo "Directory exists"
else
	install_miniconda
fi


# Clone the repository using SSH
REPO_SSH_URL="git@github.com:mertyg/ttte.git"
CLONE_DIR="$HOME/ttte"

mkdir -p ~/.ssh
touch ~/.ssh/known_hosts
# Add GitHub's keys to known_hosts
ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> ~/.ssh/known_hosts

if [[ -d "$CLONE_DIR" ]]; then
    echo "Repository already exists at $CLONE_DIR. Pulling latest changes..."
    cd "$CLONE_DIR"
    # git pull origin mask-td2
else
    echo "Cloning repository into $CLONE_DIR..."
    git clone "$REPO_SSH_URL" "$CLONE_DIR"
    cd "$CLONE_DIR"
fi

source $INSTALL_DIR/etc/profile.d/conda.sh
conda init
conda activate ttt
conda install python=3.10 uv
python --version

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i cuda-keyring_1.0-1_all.deb
apt-get update -y
apt-get install -y cuda-toolkit-12-3
apt-get install -y tmux
rm cuda-keyring_1.0-1_all.deb

git checkout mask-td2

# Run setup script
echo "Running setup script..."
bash setup.sh

echo "Installation and setup complete!"

