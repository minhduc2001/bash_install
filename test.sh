#!/bin/bash

# Kiểm tra xem có hỗ trợ gnome-terminal hoặc xfce4-terminal không
if command -v gnome-terminal &>/dev/null; then
    TERMINAL="gnome-terminal"
elif command -v xfce4-terminal &>/dev/null; then
    TERMINAL="xfce4-terminal"
else
    echo "Không tìm thấy gnome-terminal hoặc xfce4-terminal. Không thể mở trình soạn thảo."
    exit 1
fi

# Chuyển đến thư mục Desktop
cd /home/nodeerse/Desktop || exit

# Mở test.txt với trình soạn thảo trong terminal mới
$TERMINAL -- bash -c "nano test.txt; exec bash"

# Mở test1.txt với trình soạn thảo trong terminal mới
$TERMINAL -- bash -c "nano test1.txt; exec bash"

echo "Đã mở các file trong trình soạn thảo. Nhập xong thì quay lại script này."
