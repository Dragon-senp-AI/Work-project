#!/bin/bash

# Загрузка переменных из .env
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

BACKUP_DIR="$(dirname "$0")/../backups"
CONTAINER_NAME="${CONTAINER_DB:-taskzilla-db}"
DB_NAME="${POSTGRES_DB:-tasksdb}"
DB_USER="${POSTGRES_USER:-taskuser}"
DB_PASSWORD="${POSTGRES_PASSWORD:-dbpass}"
KEEP_BACKUPS=5

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_${TIMESTAMP}.sql"

echo "=========================================="
echo "Начало резервного копирования БД"
echo "Время: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    pg_dump -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✓ Бэкап создан: $BACKUP_FILE ($BACKUP_SIZE)"
    
    gzip "$BACKUP_FILE"
    echo "✓ Бэкап сжат: ${BACKUP_FILE}.gz"
else
    echo "✗ Ошибка при создании бэкапа!"
    exit 1
fi

# Очистка старых бэкапов
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$KEEP_BACKUPS" ]; then
    ls -1t "$BACKUP_DIR"/backup_*.sql.gz | tail -n +$((KEEP_BACKUPS + 1)) | xargs rm -f
    echo "✓ Старые бэкапы удалены"
fi

echo "=========================================="
echo "Резервное копирование завершено"
echo "=========================================="
