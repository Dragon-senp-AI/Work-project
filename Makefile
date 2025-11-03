.PHONY: help start stop restart build logs status clean backup restore test health borg-backup borg-restore borg-list borg-info

COMPOSE = docker-compose
BACKUP_SCRIPT = ./scripts/backup.sh
RESTORE_SCRIPT = ./scripts/restore.sh
BORG_BACKUP_SCRIPT = ./scripts/borg-scripts/borg-backup.sh
BORG_RESTORE_SCRIPT = ./scripts/borg-scripts/borg-restore.sh
BORG_LIST_SCRIPT = ./scripts/borg-scripts/borg-list.sh
BORG_INFO_SCRIPT = ./scripts/borg-scripts/borg-info.sh

GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m

help:
	@echo "$(GREEN)========================================"
	@echo "TaskZilla - Команды управления"
	@echo "========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Основные команды:$(NC)"
	@echo "  start          - Запустить все сервисы"
	@echo "  stop           - Остановить все сервисы"
	@echo "  restart        - Перезапустить сервисы"
	@echo "  build          - Пересобрать образы"
	@echo "  status         - Показать статус сервисов"
	@echo "  health         - Проверить здоровье сервисов"
	@echo "  logs           - Показать логи"
	@echo ""
	@echo "$(YELLOW)Резервное копирование (pg_dump):$(NC)"
	@echo "  backup         - Создать резервную копию (pg_dump)"
	@echo "  restore        - Восстановить из бэкапа (pg_dump)"
	@echo "  list-backups   - Список бэкапов pg_dump"
	@echo ""
	@echo "$(YELLOW)BorgBackup (дедупликация + шифрование):$(NC)"
	@echo "  borg-backup    - Создать бэкап в Borg"
	@echo "  borg-restore   - Восстановить из Borg"
	@echo "  borg-list      - Список архивов Borg"
	@echo "  borg-info      - Информация об архиве Borg"
	@echo ""
	@echo "$(YELLOW)Тестирование:$(NC)"
	@echo "  test           - Быстрый тест API"
	@echo "  test-full      - Полное тестирование"
	@echo ""
	@echo "$(YELLOW)Утилиты:$(NC)"
	@echo "  shell-web      - Войти в контейнер API"
	@echo "  shell-db       - Войти в контейнер БД"
	@echo "  psql           - Подключиться к PostgreSQL"
	@echo "  monitor        - Мониторинг ресурсов"
	@echo ""


start: check-env
	@echo "$(GREEN)Запуск сервисов...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)✓ Сервисы запущены$(NC)"

check-env:
	@bash scripts/check-env.sh	

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

# Резервное копирование через pg_dump
backup:
	@echo "$(GREEN)Создание резервной копии (pg_dump)...$(NC)"
	@bash $(BACKUP_SCRIPT)

restore:
	@echo "$(YELLOW)Восстановление из бэкапа (pg_dump)...$(NC)"
	@bash $(RESTORE_SCRIPT)

list-backups:
	@echo "$(GREEN)Доступные бэкапы pg_dump:$(NC)"
	@ls -lht backups/backup_*.sql.gz 2>/dev/null | nl || echo "Бэкапов нет"

# BorgBackup команды
borg-backup:
	@echo "$(GREEN)Создание резервной копии через BorgBackup...$(NC)"
	@bash $(BORG_BACKUP_SCRIPT)

borg-restore:
	@echo "$(YELLOW)Восстановление из BorgBackup...$(NC)"
	@bash $(BORG_RESTORE_SCRIPT)

borg-list:
	@bash $(BORG_LIST_SCRIPT)

borg-info:
	@if [ -z "$(ARCHIVE)" ]; then \
		echo "$(YELLOW)Использование: make borg-info ARCHIVE=имя_архива$(NC)"; \
		echo ""; \
		bash $(BORG_LIST_SCRIPT); \
	else \
		bash $(BORG_INFO_SCRIPT) $(ARCHIVE); \
	fi

# Тестирование полного цикла Borg
borg-test:
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Тестирование BorgBackup$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Создание тестовых данных...$(NC)"
	@curl -s -X POST -H "Content-Type: application/json" -d '{"description": "Borg тест 1", "status": "в процессе"}' http://localhost:5041/tasks
	@curl -s -X POST -H "Content-Type: application/json" -d '{"description": "Borg тест 2", "status": "завершено"}' http://localhost:5041/tasks
	@echo ""
	@echo "$(YELLOW)2. Создание бэкапа...$(NC)"
	@make borg-backup
	@echo ""
	@echo "$(YELLOW)3. Удаление данных...$(NC)"
	@for id in $$(curl -s http://localhost:5041/tasks | jq -r '.[].id'); do \
		curl -s -X DELETE http://localhost:5041/tasks/$$id; \
		echo "Удалена задача $$id"; \
	done
	@echo ""
	@echo "$(YELLOW)4. Проверка пустой БД:$(NC)"
	@curl -s http://localhost:5041/tasks
	@echo ""
	@echo "$(YELLOW)5. Восстановление...$(NC)"
	@echo "yes" | make borg-restore
	@echo ""
	@echo "$(YELLOW)6. Проверка восстановленных данных:$(NC)"
	@curl -s http://localhost:5041/tasks | jq
	@echo ""
	@echo "$(GREEN)✓ Тестирование завершено$(NC)"

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
	@mkdir -p backups scripts/borg-scripts
	@chmod +x scripts/*.sh 2>/dev/null || true
	@chmod +x scripts/borg-scripts/*.sh 2>/dev/null || true
	@make build
	@make start
	@echo "$(GREEN)✓ Проект готов к работе!$(NC)"

dev:
	$(COMPOSE) up

monitor:
	@docker stats taskzilla-web taskzilla-db

images:
	@docker images | grep -E "REPOSITORY|taskzilla|postgres"
