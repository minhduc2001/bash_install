#!/bin/bash

# Cập nhật hệ thống
sudo apt-get update

# Cài đặt các gói cần thiết
sudo apt install -y xfce4 xfce4-goodies novnc websockify python3-numpy build-essential net-tools curl git software-properties-common tightvncserver tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer dbus-x11 gnome-session-flashback metacity

# Sao lưu file xstartup
mv ~/.vnc/xstartup ~/.vnc/xstartup.bak 2>/dev/null || echo "Không tìm thấy file xstartup để sao lưu"

# Khởi động VNC server lần đầu để tạo cấu hình
echo "Khởi động VNC server để thiết lập mật khẩu..."
vncserver

# Tự động thiết lập mật khẩu VNC (mật khẩu: Vnc@2025)
echo -e "Vnc@2025\nVnc@2025" | vncpasswd

# Hỏi xem có muốn thiết lập mật khẩu view-only không
echo "Thiết lập mật khẩu view-only (mật khẩu: Node123@)..."
echo -e "y\nNode123@\nNode123@" | vncpasswd

# Tắt VNC server
echo "Tắt VNC server trên :1..."
vncserver -kill :1 2>/dev/null || echo "Không có VNC server nào đang chạy trên :1"

# Tạo file xstartup mới
echo "Tạo file xstartup mới..."
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

startxfce4
EOF

# Phân quyền cho file xstartup
chmod +x ~/.vnc/xstartup

# Khởi động VNC server
echo "Khởi động VNC server trên :1 với độ phân giải 1200x768..."
vncserver :1 -geometry 1200x768 -localhost no

# Kiểm tra port VNC (5900 hoặc 5901)
echo "Kiểm tra port VNC đang lắng nghe..."
sudo netstat -tulpn | grep LISTEN | grep -E '5900|5901'

# Khởi động websockify để kết nối NoVNC
echo "Khởi động websockify cho NoVNC trên port 6080..."
websockify -D --web=/usr/share/novnc/ 6080 localhost:5901

echo "Cài đặt hoàn tất! Truy cập NoVNC qua trình duyệt tại: http://<IP_CUA_MAY>:6080/vnc.html"
