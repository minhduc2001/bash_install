#!/bin/bash

if grep -q "/swapfile" /etc/fstab; then
    echo "Tắt swap 100GB..."
    sudo swapoff /swapfile

    echo "Xóa file swap 100GB..."
    sudo rm -f /swapfile

    echo "Xóa cấu hình swap trong /etc/fstab..."
    sudo sed -i '/\/swapfile/d' /etc/fstab

    echo "Hoàn tất xóa swap 100GB!"
else
    echo "Không tìm thấy swap 100GB trong hệ thống!"
fi

echo "Trạng thái swap hiện tại:"
free -h
sudo swapon --show
