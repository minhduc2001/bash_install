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
        read -s -p "$prompt" $var_name
        echo
    else
        read -p "$prompt" $var_name
    fi
}

# Yêu cầu người dùng nhập thông tin cấu hình
echo "Nhập thông tin cấu hình (nhấn Enter để sử dụng giá trị mặc định nếu có):"
prompt_input "Tên người dùng trên tunnel server (mặc định: ubuntu): " TUNNEL_USER
TUNNEL_USER=${TUNNEL_USER:-ubuntu}
prompt_input "Địa chỉ IP của tunnel server: " TUNNEL_IP
prompt_input "Cổng SSH của tunnel server (mặc định: 24700): " TUNNEL_SSH_PORT
TUNNEL_SSH_PORT=${TUNNEL_SSH_PORT:-24700}
prompt_input "Mật khẩu SSH của tunnel server: " TUNNEL_PASSWORD hidden
prompt_input "Cổng NoVNC trên tunnel server (ví dụ: 7013, đảm bảo cổng này chưa được dùng): " TUNNEL_NOVNC_PORT
TUNNEL_NOVNC_PORT=${TUNNEL_NOVNC_PORT:-7013}
prompt_input "Cổng NoVNC trên máy local (mặc định: 6080): " LOCAL_NOVNC_PORT
LOCAL_NOVNC_PORT=${LOCAL_NOVNC_PORT:-6080}
prompt_input "Cổng VNC trên máy local (mặc định: 5901): " LOCAL_VNC_PORT
LOCAL_VNC_PORT=${LOCAL_VNC_PORT:-5901}
prompt_input "Email cho SSH key (mặc định: sale01@nodeverse.ai): " EMAIL
EMAIL=${EMAIL:-sale01@nodeverse.ai}
prompt_input "Mật khẩu VNC: " VNC_PASSWORD hidden
prompt_input "Xác nhận mật khẩu VNC: " VNC_PASSWORD_CONFIRM hidden
if [ "$VNC_PASSWORD" != "$VNC_PASSWORD_CONFIRM" ]; then
    echo "Mật khẩu VNC không khớp!"
    exit 1
fi
prompt_input "Bạn có muốn thiết lập mật khẩu view-only không? (y/n): " answer
if [ "$answer" == "y" ]; then
    prompt_input "Mật khẩu view-only: " VNC_VIEWONLY_PASSWORD hidden
    prompt_input "Xác nhận mật khẩu view-only: " VNC_VIEWONLY_PASSWORD_CONFIRM hidden
    if [ "$VNC_VIEWONLY_PASSWORD" != "$VNC_VIEWONLY_PASSWORD_CONFIRM" ]; then
        echo "Mật khẩu view-only không khớp!"
        exit 1
    fi
else
    VNC_VIEWONLY_PASSWORD=""
fi

# Lấy tên người dùng hiện tại trên máy local
LOCAL_USER=$(whoami)

# Cập nhật hệ thống và cài đặt các gói cần thiết
echo "Cập nhật hệ thống và cài đặt các gói cần thiết..."
sudo apt-get update
sudo apt install -y xfce4 xfce4-goodies tightvncserver autossh openssh-client sshpass netcat-openbsd
check_status "Cài đặt các gói thất bại"

# Bước 1: Tạo SSH key
echo "Bước 1: Tạo cặp khóa SSH..."
if [ -f ~/.ssh/id_rsa ]; then
    echo "SSH key đã tồn tại tại ~/.ssh/id_rsa. Bỏ qua bước tạo key."
else
    ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f ~/.ssh/id_rsa -N ""
    check_status "Tạo SSH key thất bại"
    echo "Khóa SSH đã được tạo tại ~/.ssh/id_rsa và ~/.ssh/id_rsa.pub"
fi

# Kiểm tra kết nối đến tunnel server trước khi sao chép khóa
echo "Kiểm tra kết nối đến tunnel server..."
nc -zv $TUNNEL_IP $TUNNEL_SSH_PORT 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Lỗi: Không thể kết nối đến $TUNNEL_IP trên cổng $TUNNEL_SSH_PORT."
    echo "Vui lòng kiểm tra firewall, security group, hoặc trạng thái server."
    exit 1
fi

# Bước 2: Sao chép khóa công khai vào tunnel server
echo "Bước 2: Sao chép khóa công khai vào tunnel server..."
sshpass -p "$TUNNEL_PASSWORD" ssh -p $TUNNEL_SSH_PORT $TUNNEL_USER@$TUNNEL_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_rsa.pub 2> /tmp/sshpass_error.log
check_status "Sao chép khóa công khai thất bại. Kiểm tra mật khẩu hoặc cấu hình SSH trên tunnel server. Chi tiết lỗi: $(cat /tmp/sshpass_error.log)"

# Kiểm tra kết nối không cần mật khẩu
echo "Kiểm tra kết nối SSH không cần mật khẩu..."
ssh -o BatchMode=yes -p $TUNNEL_SSH_PORT $TUNNEL_USER@$TUNNEL_IP "echo 'Kết nối thành công'" 2>/dev/null
check_status "Kết nối SSH không cần mật khẩu thất bại (có thể cần kiểm tra file authorized_keys trên tunnel server)"

# Bước 3: Cấu hình VNC server
echo "Bước 3: Cấu hình VNC server..."
# Đảm bảo thư mục ~/.vnc/ tồn tại
mkdir -p ~/.vnc/
check_status "Tạo thư mục ~/.vnc/ thất bại"

if [ -f ~/.vnc/xstartup ]; then
    mv ~/.vnc/xstartup ~/.vnc/xstartup.bak
    echo "Đã sao lưu file xstartup cũ thành xstartup.bak"
fi

# Tạo file xstartup mới
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

startxfce4
EOF

chmod +x ~/.vnc/xstartup
check_status "Tạo file xstartup thất bại"

# Thiết lập mật khẩu VNC
echo "Thiết lập mật khẩu VNC..."
if [ -n "$VNC_VIEWONLY_PASSWORD" ]; then
    echo -e "$VNC_PASSWORD\n$VNC_PASSWORD\ny\n$VNC_VIEWONLY_PASSWORD\n$VNC_VIEWONLY_PASSWORD" | vncpasswd
else
    echo -e "$VNC_PASSWORD\n$VNC_PASSWORD\nn" | vncpasswd
fi
check_status "Thiết lập mật khẩu VNC thất bại"

# Khởi động VNC server lần đầu
echo "Khởi động VNC server lần đầu..."
vncserver :1 -geometry 1920x768 -localhost no
check_status "Khởi động VNC server thất bại"

# Bước 4: Thiết lập tự động mở SSH tunnel khi khởi động lại máy
echo "Bước 4: Thiết lập tự động mở SSH tunnel khi khởi động lại máy..."
cat > /tmp/ssh-tunnel.service << EOF
[Unit]
Description=Persistent SSH Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$LOCAL_USER
ExecStart=/usr/bin/autossh -M 0 -T -N -R $TUNNEL_NOVNC_PORT:localhost:$LOCAL_NOVNC_PORT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -p $TUNNEL_SSH_PORT $TUNNEL_USER@$TUNNEL_IP
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
sudo systemctl start ssh-tunnel.service
check_status "Thiết lập dịch vụ SSH tunnel thất bại"

# Bước 5: Thiết lập tự động khởi động VNC server khi khởi động lại máy
echo "Bước 5: Thiết lập tự động khởi động VNC server khi khởi động lại máy..."
(crontab -l 2>/dev/null; echo "@reboot vncserver :1 -geometry 1920x768 -localhost no") | crontab -
check_status "Thiết lập crontab thất bại"

# Hoàn tất
echo "Cài đặt hoàn tất!"
echo "Truy cập NoVNC qua: http://$TUNNEL_IP:$TUNNEL_NOVNC_PORT/vnc.html"
echo "Kiểm tra log nếu có lỗi:"
echo "  - SSH tunnel: /var/log/ssh-tunnel.log"
