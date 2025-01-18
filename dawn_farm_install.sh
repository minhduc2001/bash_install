#!/bin/bash

# Script cần chạy với quyền root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or switch to the root user."
    exit 1
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

# Bước 6: Tạo các file cấu hình với nội dung mẫu
CONFIG_FILES=("config/data/farm.txt" "config/data/proxies.txt")

for FILE in "${CONFIG_FILES[@]}"; do
    echo "Creating $FILE with default content..."
    mkdir -p "$(dirname "$FILE")"
    if [ ! -f "$FILE" ]; then
        echo "# Enter your content here" > "$FILE"
    fi
done

# Thông báo cho người dùng chỉnh sửa file
echo -e "\nConfiguration files have been created. Please edit the following files:"
for FILE in "${CONFIG_FILES[@]}"; do
    echo "  - $FILE"
done

echo -e "\nTo edit the files, you can use the following commands:"
for FILE in "${CONFIG_FILES[@]}"; do
    echo "  nano $INSTALL_DIR$CLONE_DIR/$FILE"
done

# Dừng script để người dùng chỉnh sửa file
echo -e "\nPress Enter after editing the configuration files to continue..."
read -p "Press Enter to continue..."

# Bước 7: Chạy script Python sau khi người dùng chỉnh sửa xong
echo "Running farm.py..."
python3 farm.py
