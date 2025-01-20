#!/bin/bash

# Tạo file test.txt
file="test.txt"

# Xóa nội dung cũ của file (nếu có)
> "$file"

echo "Nhập nội dung cho file $file (nhập 'DONE' để kết thúc):"

while :; do
    read -r line
    # Xóa khoảng trắng thừa và kiểm tra nếu người dùng nhập "DONE"
    if [[ "${line//[[:space:]]/}" == "DONE" ]]; then
        break
    fi
    echo "$line" >> "$file"
done

echo "Đã ghi nội dung vào $file."
