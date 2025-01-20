#!/bin/bash

# Tạo file test.txt
file="test.txt"

# Xóa nội dung cũ của file (nếu có)
> "$file"

echo "Nhập nội dung cho file $file (nhập 'DONE' để kết thúc):"

while :; do
    read -r line
    if [ "$line" = "DONE" ]; then
        break
    fi
    echo "$line" >> "$file"
done

echo "Đã ghi nội dung vào $file."
