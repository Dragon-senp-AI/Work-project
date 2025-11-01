#!/bin/bash

# Конфигурация
BACKUP_DIR="/home/app/Work-project/backups"
CONTAINER_NAME="taskzilla-db"
DB_NAME="tasksdb"
DB_USER="taskuser"
DB_PASSWORD="taskpass123"
KEEP_BACKUPS=5  # Количество хранимых бэкапов

# Создать директорию для бэкапов, если не существует
mkdir -p "$BACKUP_DIR"

# Имя файла с датой и временем
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_${TIMESTAMP}.sql"

echo "=========================================="
echo "Начало резервного копирования БД"
echo "Время: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# Создать дамп базы данных
docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    pg_dump -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"

# Проверить успешность создания бэкапа
if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✓ Бэкап успешно создан: $BACKUP_FILE"
    echo "✓ Размер файла: $BACKUP_SIZE"
    
    # Сжать бэкап
    gzip "$BACKUP_FILE"
    COMPRESSED_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
    echo "✓ Бэкап сжат: ${BACKUP_FILE}.gz"
    echo "✓ Размер после сжатия: $COMPRESSED_SIZE"
else
    echo "✗ Ошибка при создании бэкапа!"
    exit 1
fi

# Удалить старые бэкапы (оставить только последние N)
echo ""
echo "Очистка старых бэкапов (оставляем последние $KEEP_BACKUPS)..."
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$KEEP_BACKUPS" ]; then
    ls -1t "$BACKUP_DIR"/backup_*.sql.gz | tail -n +$((KEEP_BACKUPS + 1)) | while read old_backup; do
        echo "✓ Удален старый бэкап: $(basename "$old_backup")"
        rm -f "$old_backup"
    done
else
    echo "✓ Всего бэкапов: $BACKUP_COUNT (чистка не требуется)"
fi

# Список текущих бэкапов
echo ""
echo "Текущие бэкапы:"
ls -lh "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | awk '{print $9, "("$5")"}'

echo ""
echo "=========================================="
echo "Резервное копирование завершено"
echo "=========================================="
