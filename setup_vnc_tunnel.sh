#!/bin/bash

# Hàm kiểm tra lệnh có thành công không
check_status() {
    if [ $? -ne 0 ]; then
        echo "Lỗi: $1"
        exit 1
    fi
}

# Hàm yêu cầu người dùng nhập thông tin
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local hidden="$3"
    if [ "$hidden" == "hidden" ]; then
        read -r -s -p "$prompt" REPLY
        echo
    else
        read -r -p "$prompt" REPLY
    fi
    eval "$var_name=\"$REPLY\""
}

# Yêu cầu thông tin từ người dùng
echo "Nhập thông tin cấu hình cho tunnel server (nhấn Enter để sử dụng giá trị mặc định):"
prompt_input "Tên người dùng trên tunnel server (mặc định: ubuntu): " TUNNEL_USER
TUNNEL_USER=${TUNNEL_USER:-ubuntu}
prompt_input "Địa chỉ IP của tunnel server: " TUNNEL_IP
prompt_input "Cổng SSH của tunnel server (mặc định: 24700): " TUNNEL_SSH_PORT
TUNNEL_SSH_PORT=${TUNNEL_SSH_PORT:-24700}
prompt_input "Mật khẩu SSH của tunnel server: " TUNNEL_PASSWORD hidden
prompt_input "Cổng NoVNC trên tunnel server (mặc định: 7013): " TUNNEL_NOVNC_PORT
TUNNEL_NOVNC_PORT=${TUNNEL_NOVNC_PORT:-7013}

# Thiết lập giá trị mặc định
LOCAL_NOVNC_PORT=6080
LOCAL_VNC_PORT=5901
EMAIL="sale01@nodeverse.ai"
VNC_PASSWORD="Vnc@2025"
VNC_VIEWONLY_PASSWORD="Node123@"
LOCAL_USER=$(whoami)

# Cập nhật hệ thống và cài đặt các gói cần thiết
echo "Cập nhật hệ thống và cài đặt các gói cần thiết..."
sudo apt-get update || check_status "Cập nhật hệ thống thất bại"
sudo apt install -y xfce4 xfce4-goodies tightvncserver autossh sshpass netcat-openbsd xfonts-base xfonts-75dpi xfonts-100dpi xfonts-scalable || check_status "Cài đặt các gói thất bại"

# Tạo SSH key nếu chưa có
echo "Kiểm tra SSH key..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f ~/.ssh/id_rsa -N "" || check_status "Tạo SSH key thất bại"
fi

# Kiểm tra kết nối tunnel server
nc -zv $TUNNEL_IP $TUNNEL_SSH_PORT 2>/dev/null || check_status "Không thể kết nối đến $TUNNEL_IP trên cổng $TUNNEL_SSH_PORT. Kiểm tra firewall và trạng thái server."

# Sao chép SSH key lên tunnel server
echo "Sao chép khóa công khai lên tunnel server..."
sshpass -p "$TUNNEL_PASSWORD" ssh -o StrictHostKeyChecking=no -p $TUNNEL_SSH_PORT $TUNNEL_USER@$TUNNEL_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_rsa.pub || check_status "Sao chép khóa SSH thất bại"

# Kiểm tra kết nối không mật khẩu
ssh -o BatchMode=yes -p $TUNNEL_SSH_PORT $TUNNEL_USER@$TUNNEL_IP "echo 'Kết nối thành công'" 2>/dev/null || check_status "Kết nối SSH không mật khẩu thất bại"

# Cấu hình VNC server
echo "Cấu hình VNC server..."
mkdir -p ~/.vnc || check_status "Tạo thư mục ~/.vnc thất bại"

cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
EOF
chmod +x ~/.vnc/xstartup || check_status "Tạo file xstartup thất bại"

echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd || check_status "Thiết lập mật khẩu VNC thất bại"

# Khởi động VNC server
vncserver :1 -geometry 1920x768 || check_status "Khởi động VNC server thất bại"

# Thiết lập tự động mở SSH tunnel
cat > /tmp/ssh-tunnel.service << EOF
[Unit]
Description=Persistent SSH Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$LOCAL_USER
ExecStart=/usr/bin/autossh -M 0 -T -N -R $TUNNEL_NOVNC_PORT:localhost:$LOCAL_NOVNC_PORT -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -p $TUNNEL_SSH_PORT $TUNNEL_USER@$TUNNEL_IP
Restart=always
RestartSec=5s
WorkingDirectory=/home/$LOCAL_USER
StandardOutput=append:/var/log/ssh-tunnel.log
StandardError=append:/var/log/ssh-tunnel.log

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/ssh-tunnel.service /etc/systemd/system/ssh-tunnel.service
sudo systemctl daemon-reload
sudo systemctl enable ssh-tunnel.service
sudo systemctl start ssh-tunnel.service || check_status "Thiết lập dịch vụ SSH tunnel thất bại"

# Thiết lập tự động khởi động VNC server
(crontab -l 2>/dev/null; echo "@reboot vncserver :1 -geometry 1920x768") | crontab - || check_status "Thiết lập crontab thất bại"

echo "Cài đặt hoàn tất!"
echo "Truy cập NoVNC qua: http://$TUNNEL_IP:$TUNNEL_NOVNC_PORT/vnc.html"
echo "Kiểm tra log nếu có lỗi:"
echo "  - SSH tunnel: /var/log/ssh-tunnel.log"
echo "  - VNC server: ~/.vnc/*.log"
