#!/bin/bash

# Kiểm tra Chromium Browser
if ! command -v chromium-browser &> /dev/null; then
    echo "Chromium Browser chưa được cài đặt. Đang tiến hành cài đặt..."
    sudo apt update
    sudo apt install -y chromium-browser
    echo "Chromium Browser đã được cài đặt."
else
    echo "Chromium Browser đã được cài đặt. Phiên bản:"
    chromium-browser --version
fi

# Kiểm tra Chromedriver
if ! command -v chromedriver &> /dev/null; then
    echo "Chromedriver chưa được cài đặt. Đang tiến hành cài đặt..."
    sudo apt update
    sudo apt install -y chromium-chromedriver
    echo "Chromedriver đã được cài đặt."
else
    echo "Chromedriver đã được cài đặt. Phiên bản:"
    chromedriver --version
fi
