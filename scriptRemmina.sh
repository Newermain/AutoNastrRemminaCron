#!/bin/bash

# Функция для установки Remmina и Cron
install_remmina_and_cron() {
    echo "Установка Remmina и настройка Cron..."
    sudo apt update
    sudo apt install -y remmina remmina-plugin-rdp remmina-plugin-vnc
    echo "Remmina установлен."

    if ! command -v cron &> /dev/null; then
        sudo apt install -y cron
    fi
    sudo systemctl enable cron
    sudo systemctl start cron
    echo "Cron настроен."
}

# Функция для создания профиля Remmina
create_remmina_profile() {
    echo "Создание профиля Remmina..."
    read -p "Введите IP-адрес сервера: " server_ip
    read -p "Введите логин: " username
    read -s -p "Введите пароль: " password
    echo

    mkdir -p ~/.local/share/remmina
    profile_file="$HOME/.local/share/remmina/$(uuidgen).remmina"

    cat > "$profile_file" <<EOL
[remmina]
name=${server_ip}
server=${server_ip}
protocol=RDP
username=${username}
password=${password}
colordepth=32
quality=9
window_maximize=1
disableautoreconnect=0
EOL

    echo "Профиль сохранён в: $profile_file"
}

# Функция для добавления в автозагрузку
add_to_autostart() {
    echo "Добавление Remmina в автозагрузку..."

    startup_script="$HOME/remmina_autostart.sh"

    cat > "$startup_script" <<'EOL'
#!/bin/bash

# Ждём полной загрузки системы (включая графическую среду)
while [ -z "$(pgrep xfce4-session  pgrep gnome-session  pgrep plasma-desktop)" ]; do
    sleep 2
done

# Дополнительная задержка для надёжности
sleep 5

# Проверяем доступность сети
while ! ping -c1 8.8.8.8 &>/dev/null; do
    sleep 1
done

# Ищем последний профиль
latest_profile=$(ls -t "$HOME"/.local/share/remmina/*.remmina 2>/dev/null | head -1)

if [ -f "$latest_profile" ]; then
    # Экспортируем необходимые переменные окружения
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
    remmina -c "$latest_profile" &
else
    remmina &
fi
EOL

    chmod +x "$startup_script"

    # Добавляем в автозагрузку через crontab
    (crontab -l 2>/dev/null; echo "@reboot $startup_script") | crontab -
    
    # Альтернативно: добавляем в автозапуск графической среды
    if [ -d ~/.config/autostart ]; then
        cat > ~/.config/autostart/remmina.desktop <<EOL
[Desktop Entry]
Type=Application
Exec=$startup_script
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Remmina Autostart
EOL
    fi

    echo "Автозагрузка настроена двумя способами: через crontab и графическую среду"
}

# Основное меню
while true; do
    clear
    echo "=== Настройка автоматического подключения Remmina ==="
    echo "1. Установить Remmina и Cron"
    echo "2. Создать профиль подключения"
    echo "3. Настроить автозагрузку"
    echo "4. Выход"
    read -p "Выберите пункт (1-4): " choice

    case $choice in
        1) install_remmina_and_cron ;;
        2) create_remmina_profile ;;
        3) add_to_autostart ;;
        4) exit 0 ;;
        *) echo "Неверный выбор. Попробуйте снова." ;;
    esac

    read -p "Нажмите Enter, чтобы продолжить..."
done
