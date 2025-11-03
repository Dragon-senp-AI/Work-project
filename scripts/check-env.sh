#!/bin/bash

# Проверка наличия и корректности .env файла

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=========================================="
echo "Проверка конфигурации .env"
echo "=========================================="

# Проверка существования .env
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ Файл .env не найден!${NC}"
    echo ""
    echo "Создайте его на основе .env.example:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

echo -e "${GREEN}✓ Файл .env найден${NC}"

# Проверка прав доступа
PERMS=$(stat -c %a "$ENV_FILE" 2>/dev/null || stat -f %A "$ENV_FILE")
if [ "$PERMS" != "600" ]; then
    echo -e "${YELLOW}⚠ Небезопасные права доступа: $PERMS${NC}"
    echo "  Рекомендуется: chmod 600 .env"
else
    echo -e "${GREEN}✓ Права доступа корректны (600)${NC}"
fi

# Проверка обязательных переменных
echo ""
echo "Проверка обязательных переменных:"

REQUIRED_VARS=(
    "POSTGRES_DB"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "POSTGRES_HOST"
    "BORG_PASSPHRASE"
    "BORG_REPO"
)

set -a
source "$ENV_FILE"
set +a

MISSING=0
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo -e "${RED}✗ $var - НЕ УСТАНОВЛЕНА${NC}"
        MISSING=1
    else
        # Скрыть значение паролей
        if [[ "$var" == *"PASSWORD"* ]] || [[ "$var" == *"PASSPHRASE"* ]]; then
            echo -e "${GREEN}✓ $var - установлена (****)${NC}"
        else
            echo -e "${GREEN}✓ $var = ${!var}${NC}"
        fi
    fi
done

# Проверка слабых паролей
echo ""
echo "Проверка безопасности паролей:"

if [ "${POSTGRES_PASSWORD:-}" == "taskpass123" ] || [ "${POSTGRES_PASSWORD:-}" == "change_me_in_production" ]; then
    echo -e "${RED}✗ POSTGRES_PASSWORD - используется дефолтный пароль!${NC}"
    echo "  Установите надежный пароль в .env"
    MISSING=1
else
    echo -e "${GREEN}✓ POSTGRES_PASSWORD - кастомный пароль${NC}"
fi

if [ "${BORG_PASSPHRASE:-}" == "change_me_strong_password" ] || [ "${BORG_PASSPHRASE:-}" == "YourStrongPassword123!" ]; then
    echo -e "${RED}✗ BORG_PASSPHRASE - используется дефолтный пароль!${NC}"
    echo "  Установите надежный пароль в .env"
    MISSING=1
else
    echo -e "${GREEN}✓ BORG_PASSPHRASE - кастомный пароль${NC}"
fi

echo ""
echo "=========================================="

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ Конфигурация .env корректна${NC}"
    exit 0
else
    echo -e "${RED}✗ Обнаружены проблемы в конфигурации${NC}"
    exit 1
fi
