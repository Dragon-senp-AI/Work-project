#!/bin/bash

# Строгий режим: прерывать при ошибках
set -euo pipefail

# Загрузка переменных из .env
ENV_FILE="$HOME/Work-project/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Файл .env не найден: $ENV_FILE"
    echo "Создайте файл .env на основе .env.example"
    exit 1
fi

# Загрузка переменных
set -a  # автоматически экспортировать переменные
source "$ENV_FILE"
set +a

# Проверка обязательных переменных
REQUIRED_VARS=(
    "BORG_REPO"
    "BORG_PASSPHRASE"
    "CONTAINER_DB"
    "POSTGRES_DB"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "ERROR: Отсутствуют обязательные переменные в .env:"
    printf '  - %s\n' "${MISSING_VARS[@]}"
    exit 1
fi

# Конфигурация
LOG_FILE="$HOME/Work-project/backups/borg-backup.log"
BACKUP_NAME="postgres-$(date +%Y-%m-%d_%H-%M-%S)"

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

echo "========================================" | tee -a "$LOG_FILE"
log "Начало резервного копирования PostgreSQL"
echo "========================================" | tee -a "$LOG_FILE"

# Проверка контейнера
if ! docker ps | grep -q "$CONTAINER_DB"; then
    log_error "Контейнер $CONTAINER_DB не запущен!"
    exit 1
fi

log "✓ Контейнер $CONTAINER_DB работает"

# Проверка БД
if ! docker exec "$CONTAINER_DB" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" > /dev/null 2>&1; then
    log_error "База данных недоступна!"
    exit 1
fi

log "✓ База данных доступна"

# Создание дампа и архивация
log "Создание SQL дампа и архивация в Borg..."

# Используем переменную окружения для пароля (безопаснее чем -e в docker exec)
export PGPASSWORD="$POSTGRES_PASSWORD"

docker exec -e PGPASSWORD "$CONTAINER_DB" \
    pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" 2>> "$LOG_FILE" | \
    borg create \
        --verbose \
        --stats \
        --compression lz4 \
        "$BORG_REPO::$BACKUP_NAME" \
        - 2>&1 | tee -a "$LOG_FILE"

# Очистить переменную с паролем
unset PGPASSWORD

if [ $? -eq 0 ]; then
    log "✓ Архив успешно создан: $BACKUP_NAME"
else
    log_error "Ошибка при создании архива!"
    exit 1
fi

# Прореживание
log "Прореживание старых архивов..."
borg prune \
    --verbose \
    --list \
    --prefix 'postgres-' \
    --keep-daily=7 \
    --keep-weekly=4 \
    --keep-monthly=2 \
    "$BORG_REPO" 2>&1 | tee -a "$LOG_FILE"

log "✓ Прореживание завершено"

# Компактирование
log "Компактирование репозитория..."
borg compact "$BORG_REPO" 2>&1 | tee -a "$LOG_FILE"

echo "========================================" | tee -a "$LOG_FILE"
log "Резервное копирование завершено успешно"
echo "========================================" | tee -a "$LOG_FILE"

exit 0
