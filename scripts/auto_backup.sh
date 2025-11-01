#!/bin/bash

# Конфигурация
BACKUP_INTERVAL=300  # Интервал в секундах (300 = 5 минут)
SCRIPT_DIR="/home/app/Work-project/scripts"

echo "=========================================="
echo "Автоматическое резервное копирование"
echo "Интервал: $BACKUP_INTERVAL секунд"
echo "=========================================="
echo ""
echo "Для остановки нажмите Ctrl+C"
echo ""

# Бесконечный цикл
while true; do
    # Выполнить бэкап
    bash "$SCRIPT_DIR/backup.sh"
    
    # Подождать до следующего бэкапа
    echo ""
    echo "Следующий бэкап через $BACKUP_INTERVAL секунд..."
    echo ""
    sleep "$BACKUP_INTERVAL"
done
