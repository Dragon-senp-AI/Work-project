#!/bin/bash

#############################################
# BorgBackup скрипт для PostgreSQL в Docker
#############################################

# Конфигурация
BORG_REPO="$HOME/Work-project/backups/borg-repo"
CONTAINER_NAME="taskzilla-db"
DB_NAME="tasksdb"
DB_USER="taskuser"
DB_PASSWORD="dbpass"
BACKUP_NAME="postgres-$(date +%Y-%m-%d_%H-%M-%S)"
LOG_FILE="$HOME/Work-project/backups/borg-backup.log"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

echo "========================================" | tee -a "$LOG_FILE"
log "Начало резервного копирования PostgreSQL"
echo "========================================" | tee -a "$LOG_FILE"

# Проверка контейнера
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log_error "Контейнер $CONTAINER_NAME не запущен!"
    exit 1
fi

log "✓ Контейнер $CONTAINER_NAME работает"

# Проверка БД
if ! docker exec "$CONTAINER_NAME" pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
    log_error "База данных недоступна!"
    exit 1
fi

log "✓ База данных доступна"

# Создание дампа и архивация
log "Создание SQL дампа и архивация в Borg..."

# Сначала создаем дамп, затем архивируем
docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    pg_dump -U "$DB_USER" -d "$DB_NAME" 2>> "$LOG_FILE" | \
    borg create \
        --verbose \
        --stats \
        --compression lz4 \
        "$BORG_REPO::$BACKUP_NAME" \
        - 2>&1 | tee -a "$LOG_FILE"

# Проверяем только код возврата borg
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

if [ $? -eq 0 ]; then
    log "✓ Прореживание завершено"
else
    log_warning "Ошибка при прореживании"
fi

# Компактирование
log "Компактирование репозитория..."
borg compact "$BORG_REPO" 2>&1 | tee -a "$LOG_FILE"

# Статистика
log "Информация о репозитории:"
borg info "$BORG_REPO" 2>&1 | tee -a "$LOG_FILE"

echo "========================================" | tee -a "$LOG_FILE"
log "Резервное копирование завершено успешно"
echo "========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

exit 0