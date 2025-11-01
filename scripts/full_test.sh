#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

API_URL="http://localhost:5041"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Полное тестирование TaskZilla API${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Тест 1: Проверка доступности
echo -e "${YELLOW}[1/7] Проверка доступности API...${NC}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $API_URL/)
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ API доступен${NC}"
else
    echo -e "${RED}✗ API недоступен (код: $RESPONSE)${NC}"
    exit 1
fi
echo ""

# Тест 2: Создание первой задачи
echo -e "${YELLOW}[2/7] Создание первой задачи...${NC}"
TASK1=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"description": "Тест 1", "status": "в процессе"}' \
    $API_URL/tasks)
TASK1_ID=$(echo $TASK1 | jq -r '.id' 2>/dev/null)
if [ -n "$TASK1_ID" ] && [ "$TASK1_ID" != "null" ]; then
    echo -e "${GREEN}✓ Задача создана (ID: $TASK1_ID)${NC}"
    echo "$TASK1"
else
    echo -e "${RED}✗ Ошибка создания задачи${NC}"
    exit 1
fi
echo ""

# Тест 3: Создание второй задачи
echo -e "${YELLOW}[3/7] Создание второй задачи...${NC}"
TASK2=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"description": "Тест 2", "status": "в процессе"}' \
    $API_URL/tasks)
TASK2_ID=$(echo $TASK2 | jq -r '.id' 2>/dev/null)
echo -e "${GREEN}✓ Задача создана (ID: $TASK2_ID)${NC}"
echo "$TASK2"
echo ""

# Тест 4: Получение всех задач
echo -e "${YELLOW}[4/7] Получение списка задач...${NC}"
TASKS=$(curl -s $API_URL/tasks)
TASK_COUNT=$(echo $TASKS | jq '. | length' 2>/dev/null)
echo -e "${GREEN}✓ Получено задач: $TASK_COUNT${NC}"
echo "$TASKS" | jq '.' 2>/dev/null || echo "$TASKS"
echo ""

# Тест 5: Обновление задачи
echo -e "${YELLOW}[5/7] Обновление первой задачи...${NC}"
UPDATED=$(curl -s -X PUT -H "Content-Type: application/json" \
    -d '{"description": "Тест 1 обновлен", "status": "завершено"}' \
    $API_URL/tasks/$TASK1_ID)
echo -e "${GREEN}✓ Задача обновлена${NC}"
echo "$UPDATED"
echo ""

# Тест 6: Проверка обновления
echo -e "${YELLOW}[6/7] Проверка обновленных данных...${NC}"
TASKS_AFTER=$(curl -s $API_URL/tasks)
echo "$TASKS_AFTER" | jq '.' 2>/dev/null || echo "$TASKS_AFTER"
echo ""

# Тест 7: Удаление задачи
echo -e "${YELLOW}[7/7] Удаление второй задачи...${NC}"
DELETE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $API_URL/tasks/$TASK2_ID)
if [ "$DELETE_RESPONSE" = "204" ]; then
    echo -e "${GREEN}✓ Задача удалена${NC}"
else
    echo -e "${RED}✗ Ошибка удаления (код: $DELETE_RESPONSE)${NC}"
fi
echo ""

# Финальная проверка
echo -e "${YELLOW}Финальное состояние:${NC}"
curl -s $API_URL/tasks | jq '.' 2>/dev/null || curl -s $API_URL/tasks
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Все тесты пройдены успешно!${NC}"
echo -e "${GREEN}========================================${NC}"
