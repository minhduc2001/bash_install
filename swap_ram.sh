#!/bin/bash

# Kiểm tra RAM ảo bằng lệnh `free`
swap_size=$(free -g | awk '/^Swap:/ {print $2}')

# Ngưỡng RAM ảo cần thiết (100GB)
required_swap=100

if [ "$swap_size" -ge "$required_swap" ]; then
    echo "RAM ảo (swap) hiện tại đã đủ dung lượng (>= ${required_swap}GB)."
    free -h
    exit 0
else
    echo "RAM ảo hiện tại không đủ. Dung lượng hiện có: ${swap_size}GB."
fi

# Kiểm tra ổ đĩa có dung lượng trống >200GB
disk=$(df -h --output=avail,source | awk '$1 ~ /[0-9]+G/ && $1+0 > 200 {print $2}' | head -n 1)

if [ -n "$disk" ]; then
    echo "Tìm thấy ổ đĩa với dung lượng trống >200GB: $disk"
    echo "Đang tiến hành tạo RAM ảo (swap) 100GB..."

    # Tạo file swap
    sudo fallocate -l 100G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

    # Hiển thị thông tin swap
    echo "RAM ảo (swap) đã được kích hoạt:"
    sudo swapon --show
    sudo free -h

    # Cập nhật file fstab để kích hoạt lại swap sau khi khởi động
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    # Cấu hình tối ưu hệ thống
    echo "Đang cấu hình hệ thống để tối ưu swap..."
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    echo "Hoàn thành cài đặt RAM ảo (swap)."
else
    echo "Không tìm thấy ổ đĩa có dung lượng trống >200GB. Không thể tạo swap."
fi
