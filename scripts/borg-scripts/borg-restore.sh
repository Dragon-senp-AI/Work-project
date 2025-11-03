#!/bin/bash

set -euo pipefail

# Загрузка .env
ENV_FILE="$HOME/Work-project/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Файл .env не найден: $ENV_FILE"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

# Проверка переменных
REQUIRED_VARS=("BORG_REPO" "BORG_PASSPHRASE" "CONTAINER_DB" "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "ERROR: Отсутствуют обязательные переменные:"
    printf '  - %s\n' "${MISSING_VARS[@]}"
    exit 1
fi

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

log "Доступные архивы:"
borg list "$BORG_REPO" | tee -a "$LOG_FILE"
echo ""

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

echo ""
echo -e "${YELLOW}ВНИМАНИЕ: Это заменит текущие данные в БД!${NC}"
read -p "Продолжить восстановление? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log "Восстановление отменено"
    exit 0
fi

log "Очистка текущих данных в БД..."

export PGPASSWORD="$POSTGRES_PASSWORD"

docker exec -e PGPASSWORD "$CONTAINER_DB" \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP TABLE IF EXISTS tasks CASCADE;" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "✓ БД очищена"
else
    echo -e "${RED}✗ Ошибка при очистке БД${NC}" | tee -a "$LOG_FILE"
    unset PGPASSWORD
    exit 1
fi

log "Извлечение и восстановление данных..."

borg extract --stdout "$BORG_REPO::$ARCHIVE_NAME" 2>> "$LOG_FILE" | \
    docker exec -i -e PGPASSWORD "$CONTAINER_DB" \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" 2>&1 | tee -a "$LOG_FILE"

unset PGPASSWORD

if [ $? -eq 0 ]; then
    log "✓ Данные успешно восстановлены из: $ARCHIVE_NAME"
else
    echo -e "${RED}✗ Ошибка при восстановлении${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

TASK_COUNT=$(docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER_DB" \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM tasks;" 2>/dev/null | xargs)

log "Количество задач в БД: $TASK_COUNT"

echo "========================================" | tee -a "$LOG_FILE"
log "Восстановление завершено"
echo "========================================" | tee -a "$LOG_FILE"

exit 0
