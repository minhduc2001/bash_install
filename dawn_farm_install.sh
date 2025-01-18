#!/bin/bash

# Script cần chạy với quyền root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or switch to the root user."
    exit 1
fi

# Kiểm tra xem python3.12-venv đã cài đặt chưa
if ! dpkg -l | grep -q "python3.12-venv"; then
    echo "python3.12-venv is not installed. Installing it now..."
    sudo apt install -y python3.12-venv
else
    echo "python3.12-venv is already installed."
fi

# Đường dẫn thư mục cài đặt
INSTALL_DIR="/home/nodeerse/Desktop/"

# Tên thư mục sau khi clone
CLONE_DIR="dawn"

# URL GitHub repo
REPO_URL="https://github.com/TruongTrReal/dawn_bot_nodeverse.git"

# Bước 1: Di chuyển đến thư mục cài đặt
echo "Navigating to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Bước 2: Clone repo
echo "Cloning repository from $REPO_URL..."
git clone "$REPO_URL" "$CLONE_DIR"

# Bước 3: Di chuyển vào thư mục dự án
cd "$CLONE_DIR"

# Bước 4: Tạo virtual environment
echo "Creating virtual environment..."
python3 -m venv venv

# Bước 5: Kích hoạt virtual environment và cài đặt dependencies
echo "Activating virtual environment and installing requirements..."
source venv/bin/activate
pip install -r requirements.txt

# Bước 6: Sao chép các file cấu hình từ Desktop vào thư mục config/data
CONFIG_FILES=("farm.txt" "proxies.txt")
SOURCE_DIR="/home/nodeerse/Desktop/"

for FILE in "${CONFIG_FILES[@]}"; do
    echo "Copying $FILE from $SOURCE_DIR to $INSTALL_DIR$CLONE_DIR/config/data/..."
    
    if [ ! -f "$SOURCE_DIR$FILE" ]; then
        echo "Error: $SOURCE_DIR$FILE does not exist. Please make sure the file is on the Desktop."
        exit 1
    fi

    # Tạo thư mục đích nếu chưa có
    mkdir -p "$(dirname "$INSTALL_DIR$CLONE_DIR/config/data/$FILE")"
    
    # Sao chép file vào thư mục đích
    cp "$SOURCE_DIR$FILE" "$INSTALL_DIR$CLONE_DIR/config/data/$FILE"
done

# Thông báo cho người dùng về việc sao chép file
echo -e "\nConfiguration files have been copied successfully."
echo -e "\nTo continue, press Enter..."
read -p "Press Enter to continue..."

# Bước 7: Chạy script Python
echo "Running farm.py..."
python3 farm.py
