#!/bin/bash

# Функция для генерации имени файла профиля
generate_profile_name() {
    echo "$HOME/.local/share/remmina/connection_$(date +%s%N).remmina"
}

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
    profile_file=$(generate_profile_name)

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
PROFILE=$(ls -t ~/.local/share/remmina/*.remmina 2>/dev/null | head -1)
if [ -f "$PROFILE" ]; then
    /usr/bin/remmina -c "$PROFILE" &
fi
exit 0
EOL

    chmod +x "$startup_script"

    # Добавляем в автозагрузку через crontab
    (crontab -l 2>/dev/null; echo "@reboot sleep 5 && export DISPLAY=:0 && bash $startup_script") | crontab -
    

    echo "Автозагрузка настроена через crontab"
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
