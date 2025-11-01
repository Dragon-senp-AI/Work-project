.PHONY: help start stop restart build logs status clean backup restore test health

COMPOSE = docker-compose
BACKUP_SCRIPT = ./scripts/backup.sh
RESTORE_SCRIPT = ./scripts/restore.sh

GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m

help:
	@echo "$(GREEN)========================================"
	@echo "TaskZilla - Команды управления"
	@echo "========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)start$(NC)          - Запустить все сервисы"
	@echo "$(YELLOW)stop$(NC)           - Остановить все сервисы"
	@echo "$(YELLOW)restart$(NC)        - Перезапустить сервисы"
	@echo "$(YELLOW)build$(NC)          - Пересобрать образы"
	@echo "$(YELLOW)status$(NC)         - Показать статус сервисов"
	@echo "$(YELLOW)health$(NC)         - Проверить здоровье сервисов"
	@echo "$(YELLOW)logs$(NC)           - Показать логи"
	@echo "$(YELLOW)backup$(NC)         - Создать резервную копию"
	@echo "$(YELLOW)restore$(NC)        - Восстановить из бэкапа"
	@echo "$(YELLOW)test$(NC)           - Запустить тесты"
	@echo "$(YELLOW)shell-web$(NC)      - Войти в контейнер API"
	@echo "$(YELLOW)shell-db$(NC)       - Войти в контейнер БД"
	@echo "$(YELLOW)psql$(NC)           - Подключиться к PostgreSQL"
	@echo ""

start:
	@echo "$(GREEN)Запуск сервисов...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Сервисы запущены$(NC)"

stop:
	@echo "$(YELLOW)Остановка сервисов...$(NC)"
	$(COMPOSE) down
	@echo "$(YELLOW)✓ Сервисы остановлены$(NC)"

restart:
	@make stop
	@make start

build:
	@echo "$(GREEN)Сборка образов...$(NC)"
	$(COMPOSE) build --no-cache
	@echo "$(GREEN)✓ Образы собраны$(NC)"

rebuild:
	@make stop
	@make build
	@make start

logs:
	$(COMPOSE) logs -f

logs-web:
	$(COMPOSE) logs -f web

logs-db:
	$(COMPOSE) logs -f db

status:
	@echo "$(GREEN)Статус контейнеров:$(NC)"
	@$(COMPOSE) ps

health:
	@echo "$(GREEN)Проверка здоровья сервисов$(NC)"
	@echo ""
	@echo "$(YELLOW)PostgreSQL:$(NC)"
	@docker exec taskzilla-db pg_isready -U taskuser -d tasksdb && echo "$(GREEN)✓ БД доступна$(NC)" || echo "$(RED)✗ БД недоступна$(NC)"
	@echo ""
	@echo "$(YELLOW)API:$(NC)"
	@curl -s http://localhost:5041/ > /dev/null && echo "$(GREEN)✓ API доступен$(NC)" || echo "$(RED)✗ API недоступен$(NC)"

backup:
	@echo "$(GREEN)Создание резервной копии...$(NC)"
	@bash $(BACKUP_SCRIPT)

restore:
	@echo "$(YELLOW)Восстановление из бэкапа...$(NC)"
	@bash $(RESTORE_SCRIPT)

list-backups:
	@echo "$(GREEN)Доступные бэкапы:$(NC)"
	@ls -lht backups/backup_*.sql.gz 2>/dev/null | nl || echo "Бэкапов нет"

clean:
	@echo "$(RED)ВНИМАНИЕ: Будут удалены ВСЕ данные!$(NC)"
	@read -p "Продолжить? (yes/no): " confirm && [ "$$confirm" = "yes" ] && $(COMPOSE) down -v || echo "Отменено"

test:
	@echo "$(GREEN)Тестирование API$(NC)"
	@echo ""
	@curl -s -X POST -H "Content-Type: application/json" -d '{"description": "Тест", "status": "в процессе"}' http://localhost:5041/tasks
	@echo ""
	@curl -s http://localhost:5041/tasks

test-full:
	@bash scripts/full_test.sh

shell-web:
	@docker exec -it taskzilla-web /bin/sh

shell-db:
	@docker exec -it taskzilla-db /bin/sh

psql:
	@docker exec -it taskzilla-db psql -U taskuser -d tasksdb

init:
	@echo "$(GREEN)Инициализация проекта TaskZilla$(NC)"
	@mkdir -p backups scripts
	@chmod +x scripts/*.sh 2>/dev/null || true
	@make build
	@make start
	@echo "$(GREEN)✓ Проект готов к работе!$(NC)"

dev:
	$(COMPOSE) up

monitor:
	@docker stats taskzilla-web taskzilla-db

images:
	@docker images | grep -E "REPOSITORY|taskzilla|postgres"
