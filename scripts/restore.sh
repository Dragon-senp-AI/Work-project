#!/bin/bash

# Загрузка переменных из .env
ENV_FILE="$HOME/Work-project/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Файл .env не найден: $ENV_FILE"
    echo "Создайте файл .env на основе .env.example"
    exit 1
fi

echo "=========================================="
echo "Восстановление базы данных из бэкапа"
echo "=========================================="

# Показать доступные бэкапы
echo ""
echo "Доступные бэкапы:"
ls -lht "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | nl

# Если передан аргумент - номер бэкапа
if [ -n "$1" ]; then
    BACKUP_FILE=$(ls -1t "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | sed -n "${1}p")
else
    # Использовать последний бэкап
    BACKUP_FILE=$(ls -1t "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null | head -n 1)
fi

if [ -z "$BACKUP_FILE" ]; then
    echo "✗ Бэкапы не найдены!"
    exit 1
fi

echo ""
echo "Выбран бэкап: $(basename "$BACKUP_FILE")"
echo ""
read -p "Продолжить восстановление? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Отменено пользователем"
    exit 0
fi

echo ""
echo "Восстановление данных..."

# Распаковать бэкап во временный файл
TEMP_FILE="/tmp/restore_temp.sql"
gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"

# Удалить существующие данные и восстановить из бэкапа
docker exec -i -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" < "$TEMP_FILE"

if [ $? -eq 0 ]; then
    echo "✓ База данных успешно восстановлена!"
    rm -f "$TEMP_FILE"
else
    echo "✗ Ошибка при восстановлении базы данных!"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Показать количество задач после восстановления
TASK_COUNT=$(docker exec -e PGPASSWORD="$DB_PASSWORD" "$CONTAINER_NAME" \
    psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM tasks;")

echo "✓ Количество задач в БД: $TASK_COUNT"
echo ""
echo "=========================================="
echo "Восстановление завершено"
echo "=========================================="
