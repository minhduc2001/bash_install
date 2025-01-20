#!/bin/bash

# Tạo file test.txt
file="test.txt"

# Xóa nội dung cũ của file (nếu có)
> "$file"

echo "Nhập nội dung cho file $file (nhập 'DONE' để kết thúc):"

while true; do
    read -r line
    # Loại bỏ khoảng trắng thừa đầu và cuối dòng nhập
    line=$(echo "$line" | xargs)
    
    # Kiểm tra nếu dòng nhập chứa từ "DONE"
    if [[ "$line" == *DONE* ]]; then
        break
    fi
    
    # Ghi vào file
    echo "$line" >> "$file"
done

echo "Đã ghi nội dung vào $file."
