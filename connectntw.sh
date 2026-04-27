#!/bin/bash

# РУЧНОЙ РЕЖИМ - укажите вашу сеть здесь
NETWORK="192.168.1.0/24"  # ИЗМЕНИТЕ ЭТО НА ВАШУ СЕТЬ
USER="user"
OUTPUT="hosts.txt"

# Определяем ваш IP автоматически
MY_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)

echo "====================================="
echo "Ваш IP: $MY_IP"
echo "Сканирую сеть: $NETWORK"
echo "Пользователь: $USER"
echo "====================================="

# Проверка наличия fping
if ! command -v fping &> /dev/null; then
    echo "Устанавливаю fping..."
    sudo apt install fping -y 2>/dev/null || sudo yum install fping -y 2>/dev/null
fi

# Сканирование
echo "Сканирование активных хостов..."
ACTIVE_HOSTS=$(sudo fping -ag $NETWORK 2>/dev/null)

if [ -z "$ACTIVE_HOSTS" ]; then
    ACTIVE_HOSTS=$(fping -ag $NETWORK 2>/dev/null)
fi

> "$OUTPUT"
COUNT=0

for IP in $ACTIVE_HOSTS; do
    echo -n "Проверка $IP... "
    if nc -z -w 1 "$IP" 22 2>/dev/null; then
        if ssh -o ConnectTimeout=1 -o BatchMode=yes -o StrictHostKeyChecking=no $USER@$IP "exit" 2>/dev/null; then
            echo "$USER@$IP" >> "$OUTPUT"
            echo "ДОСТУП ЕСТЬ ✓"
            ((COUNT++))
        else
            echo "SSH порт открыт, но нет ключа ✗"
        fi
    else
        ((COUNT++))
        echo "SSH порт закрыт ✗"
        echo "$USER@$IP" >> "$OUTPUT"
    fi
done

echo ""
echo "Найдено хостов с доступом: $COUNT"
echo "Результат в $OUTPUT"
