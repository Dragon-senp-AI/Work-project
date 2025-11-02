#!/bin/bash

BORG_REPO="$HOME/Work-project/backups/borg-repo"
CONTAINER_NAME="taskzilla-db"
DB_NAME="tasksdb"
DB_USER="taskuser"
DB_PASSWORD="dbpass"
LOG_FILE="$HOME/Work-project/backups/borg-restore.log"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

echo "========================================" | tee -a "$LOG_FILE"
log "Восстановление из BorgBackup"
echo "========================================" | tee -a "$LOG_FILE"

# Показать архивы
log "Доступные архивы:"
borg list "$BORG_REPO" | tee -a "$LOG_FILE"
echo ""

# Выбор архива
if [ -n "$1" ]; then
    ARCHIVE_NAME="$1"
    log "Выбран архив: $ARCHIVE_NAME"
else
    ARCHIVE_NAME=$(borg list "$BORG_REPO" --last 1 --format '{archive}')
    log "Использован последний архив: $ARCHIVE_NAME"
fi

if [ -z "$ARCHIVE_NAME" ]; then
    echo -e "${RED}Архивы не найдены!${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Подтверждение
echo ""
echo -e "${YELLOW}ВНИМАНИЕ: Это заменит текущие данные в БД!${NC}"
read -p "Продолжить восстановление? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log "Восстановление отменено"
    exit 0
fi

# ВАЖНО: Сначала очистить БД, затем восстановить
log "Очистка текущих данных в БД..."

docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" -c "DROP TABLE IF EXISTS tasks CASCADE;" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "✓ БД очищена"
else
    echo -e "${RED}✗ Ошибка при очистке БД${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Восстановление
log "Извлечение и восстановление данных..."

borg extract --stdout "$BORG_REPO::$ARCHIVE_NAME" 2>> "$LOG_FILE" | \
    docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" 2>&1 | tee -a "$LOG_FILE"

# Проверяем только последний код возврата (psql)
if [ $? -eq 0 ]; then
    log "✓ Данные успешно восстановлены из: $ARCHIVE_NAME"
else
    echo -e "${RED}✗ Ошибка при восстановлении${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Проверка
TASK_COUNT=$(docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM tasks;" 2>/dev/null | xargs)

log "Количество задач в БД: $TASK_COUNT"

echo "========================================" | tee -a "$LOG_FILE"
log "Восстановление завершено"
echo "========================================" | tee -a "$LOG_FILE"

exit 0