# BORG

# 1. Установил Borg

# 2. Создал скрипты и папку для бекапов
app@app-virtual-machine:~/Work-project$ chmod +x ~/Work-project/scripts/borg-scripts/borg-backup.sh
app@app-virtual-machine:~/Work-project$ chmod +x ~/Work-project/scripts/borg-scripts/borg-restore.sh
app@app-virtual-machine:~/Work-project$ chmod +x ~/Work-project/scripts/borg-scripts/borg-list.sh
app@app-virtual-machine:~/Work-project$ chmod +x ~/Work-project/scripts/borg-scripts/borg-info.sh

# Прописал в crontab

app@app-virtual-machine:~/Work-project$ (crontab -l 2>/dev/null; echo "0 2 * * * $HOME/Work-project/borg-scripts/borg-backup.sh >> $HOME/Work-project/backups/borg-cron.log 2>&1") | crontab -

app@app-virtual-machine:~/Work-project$ crontab -l

0 * * * * /$HOME/Work-project/scripts/backup.sh >> $HOME/Work-project/backups/backup.log 2>&1
0 2 * * * $HOME/Work-project/borg-scripts/borg-backup.sh >> $HOME/Work-project/backups/borg-cron.log 2>&1"

# Тестим бекапы

app@app-virtual-machine:~/Work-project$ make start

Запуск сервисов...
docker-compose up -d
Creating network "taskzilla-network" with the default driver
Creating taskzilla-db ... done
Creating taskzilla-web ... done
✓ Сервисы запущены

app@app-virtual-machine:~/Work-project$ docker ps

CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS                    PORTS                                         NAMES
848ba0865af0   work-project_web     "python app.py"          25 seconds ago   Up 25 seconds (healthy)   0.0.0.0:5041->5041/tcp, [::]:5041->5041/tcp   taskzilla-web
9837f45a6e43   postgres:14-alpine   "docker-entrypoint.s…"   31 seconds ago   Up 31 seconds (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   taskzilla-db


app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   529  100   529    0     0  15169      0 --:--:-- --:--:-- --:--:-- 15558
[
  {
    "description": "Задача 1 - Тестовая",
    "id": 3,
    "status": "в процессе"
  },
  {
    "description": "Задача 2 - Важная",
    "id": 4,
    "status": "в процессе"
  },
  {
    "description": "Задача 3 - Срочная",
    "id": 5,
    "status": "завершено"
  }
]
app@app-virtual-machine:~/Work-project$ echo "Удаление всех задач..."
for id in $(curl -s http://localhost:5041/tasks | jq -r '.[].id'); do
    curl -X DELETE http://localhost:5041/tasks/$id
    echo "Удалена задача с ID: $id"
done
Удаление всех задач...
Удалена задача с ID: 3
Удалена задача с ID: 4
Удалена задача с ID: 5

app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100     3  100     3    0     0    332      0 --:--:-- --:--:-- --:--:--   375
[]


app@app-virtual-machine:~/Work-project$ curl -X POST -H "Content-Type: application/json" \
  -d '{"description": "Важная задача 1", "status": "в процессе"}' \
  http://localhost:5041/tasks
{"description":"\u0412\u0430\u0436\u043d\u0430\u044f \u0437\u0430\u0434\u0430\u0447\u0430 1","id":6,"status":"\u0432 \u043f\u0440\u043e\u0446\u0435\u0441\u0441\u0435"}


app@app-virtual-machine:~/Work-project$ curl -X POST -H "Content-Type: application/json" \
  -d '{"description": "Важная задача 2", "status": "завершено"}' \
  http://localhost:5041/tasks
{"description":"\u0412\u0430\u0436\u043d\u0430\u044f \u0437\u0430\u0434\u0430\u0447\u0430 2","id":7,"status":"\u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u043e"}


app@app-virtual-machine:~/Work-project$ curl -X POST -H "Content-Type: application/json"   -d '{"description": "Важная задача 3", "status": "завершено"}'   http://localhost:5041/tasks
{"description":"\u0412\u0430\u0436\u043d\u0430\u044f \u0437\u0430\u0434\u0430\u0447\u0430 3","id":8,"status":"\u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u043e"}


app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   504  100   504    0     0  38582      0 --:--:-- --:--:-- --:--:-- 42000
[
  {
    "description": "Важная задача 1",
    "id": 6,
    "status": "в процессе"
  },
  {
    "description": "Важная задача 2",
    "id": 7,
    "status": "завершено"
  },
  {
    "description": "Важная задача 3",
    "id": 8,
    "status": "завершено"
  }
]

# Запуск скрипта Borg-backup.sh

app@app-virtual-machine:~/Work-project$ scripts/borg-scripts/borg-backup.sh
========================================
[2025-11-02 16:49:22] Начало резервного копирования PostgreSQL
========================================
[2025-11-02 16:49:22] ✓ Контейнер taskzilla-db работает
[2025-11-02 16:49:22] ✓ База данных доступна
[2025-11-02 16:49:22] Создание SQL дампа и архивация в Borg...
Creating archive at "/home/app/Work-project/backups/borg-repo::postgres-2025-11-02_16-49-22"
------------------------------------------------------------------------------
Repository: /home/app/Work-project/backups/borg-repo
Archive name: postgres-2025-11-02_16-49-22
Archive fingerprint: 372da43f3f8cd3f3d5d0e69e0bd4d38dff14eda83f9fa10c23c94f0635a854a7
Time (start): Sun, 2025-11-02 16:49:23
Time (end):   Sun, 2025-11-02 16:49:23
Duration: 0.00 seconds
Number of files: 1
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:                2.81 kB              1.83 kB              1.83 kB
All archives:                7.40 kB              4.13 kB              6.44 kB

                       Unique chunks         Total chunks
Chunk index:                       9                    9
------------------------------------------------------------------------------
[2025-11-02 16:49:23] ✓ Архив успешно создан: postgres-2025-11-02_16-49-22
[2025-11-02 16:49:23] Прореживание старых архивов...
Keeping archive (rule: daily #1):        postgres-2025-11-02_16-49-22         Sun, 2025-11-02 16:49:23 [372da43f3f8cd3f3d5d0e69e0bd4d38dff14eda83f9fa10c23c94f0635a854a7]
Pruning archive (1/1):                   postgres-2025-11-02_16-48-16         Sun, 2025-11-02 16:48:17 [121bec8a89e74ef0b47852f18de552c06ad6eaf6864477e72eed8cb937b6679b]
Keeping archive (rule: daily[oldest] #2): postgres-2025-11-02_16-33-32         Sun, 2025-11-02 16:33:33 [281b4a2cda3110663fa88736c38b69381697249ab3939485e92bf3334b06a642]
[2025-11-02 16:49:23] ✓ Прореживание завершено
[2025-11-02 16:49:23] Компактирование репозитория...
[2025-11-02 16:49:23] Информация о репозитории:
Repository ID: e007007f24841617885f1da71fd2ec8b047c83941b3c5464ad9cd913fc8015f3
Location: /home/app/Work-project/backups/borg-repo
Encrypted: Yes (repokey BLAKE2b)
Cache: /home/app/.cache/borg/e007007f24841617885f1da71fd2ec8b047c83941b3c5464ad9cd913fc8015f3
Security dir: /home/app/.config/borg/security/e007007f24841617885f1da71fd2ec8b047c83941b3c5464ad9cd913fc8015f3
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
All archives:                4.80 kB              2.69 kB              4.23 kB

                       Unique chunks         Total chunks
Chunk index:                       6                    6
========================================
[2025-11-02 16:49:24] Резервное копирование завершено успешно
========================================


# Полная автоматизация через Make

app@app-virtual-machine:~/Work-project$ make borg-test
========================================
Тестирование BorgBackup
========================================

1. Создание тестовых данных...
{"description":"Borg \u0442\u0435\u0441\u0442 1","id":11,"status":"\u0432 \u043f\u0440\u043e\u0446\u0435\u0441\u0441\u0435"}
{"description":"Borg \u0442\u0435\u0441\u0442 2","id":12,"status":"\u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u043e"}

2. Создание бэкапа...
make[1]: Entering directory '/home/app/Work-project'
Создание резервной копии через BorgBackup...
========================================
[2025-11-02 16:59:11] Начало резервного копирования PostgreSQL
========================================
[2025-11-02 16:59:11] ✓ Контейнер taskzilla-db работает
[2025-11-02 16:59:11] ✓ База данных доступна
[2025-11-02 16:59:11] Создание SQL дампа и архивация в Borg...
Creating archive at "/home/app/Work-project/backups/borg-repo::postgres-2025-11-02_16-59-11"
------------------------------------------------------------------------------
Repository: /home/app/Work-project/backups/borg-repo
Archive name: postgres-2025-11-02_16-59-11
Archive fingerprint: faa50623148b5aa4ad8100a14542dd5d7b3fca4bc242cfe7ff970601cc302152
Time (start): Sun, 2025-11-02 16:59:12
Time (end):   Sun, 2025-11-02 16:59:12
Duration: 0.01 seconds
Number of files: 1
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:                2.96 kB              1.88 kB              1.88 kB
All archives:                7.22 kB              4.00 kB              6.31 kB

                       Unique chunks         Total chunks
Chunk index:                       9                    9
------------------------------------------------------------------------------
[2025-11-02 16:59:12] ✓ Архив успешно создан: postgres-2025-11-02_16-59-11
[2025-11-02 16:59:12] Прореживание старых архивов...
Keeping archive (rule: daily #1):        postgres-2025-11-02_16-59-11         Sun, 2025-11-02 16:59:12 [faa50623148b5aa4ad8100a14542dd5d7b3fca4bc242cfe7ff970601cc302152]
Pruning archive (1/1):                   postgres-2025-11-02_16-55-05         Sun, 2025-11-02 16:55:05 [eb812030e53b26ea61073879add0ce82c6a31e6048492edee59c384eee680f99]
Keeping archive (rule: daily[oldest] #2): postgres-2025-11-02_16-33-32         Sun, 2025-11-02 16:33:33 [281b4a2cda3110663fa88736c38b69381697249ab3939485e92bf3334b06a642]
[2025-11-02 16:59:12] ✓ Прореживание завершено
[2025-11-02 16:59:12] Компактирование репозитория...
[2025-11-02 16:59:12] Информация о репозитории:
Repository ID: e007007f24841617885f1da71fd2ec8b047c83941b3c5464ad9cd913fc8015f3
Location: /home/app/Work-project/backups/borg-repo
Encrypted: Yes (repokey BLAKE2b)
Cache: /home/app/.cache/borg/e007007f24841617885f1da71fd2ec8b047c83941b3c5464ad9cd913fc8015f3
Security dir: /home/app/.config/borg/security/e007007f24841617885f1da71fd2ec8b047c83941b3c5464ad9cd913fc8015f3
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
All archives:                4.95 kB              2.73 kB              4.27 kB

                       Unique chunks         Total chunks
Chunk index:                       6                    6
========================================
[2025-11-02 16:59:13] Резервное копирование завершено успешно
========================================

make[1]: Leaving directory '/home/app/Work-project'

3. Удаление данных...
Удалена задача 6
Удалена задача 7
Удалена задача 8
Удалена задача 9
Удалена задача 10
Удалена задача 11
Удалена задача 12

4. Проверка пустой БД:
[]

5. Восстановление...
make[1]: Entering directory '/home/app/Work-project'
Восстановление из BorgBackup...
========================================
[2025-11-02 16:59:13] Восстановление из BorgBackup
========================================
[2025-11-02 16:59:13] Доступные архивы:
postgres-2025-11-02_16-33-32         Sun, 2025-11-02 16:33:33 [281b4a2cda3110663fa88736c38b69381697249ab3939485e92bf3334b06a642]
postgres-2025-11-02_16-59-11         Sun, 2025-11-02 16:59:12 [faa50623148b5aa4ad8100a14542dd5d7b3fca4bc242cfe7ff970601cc302152]

[2025-11-02 16:59:13] Использован последний архив: postgres-2025-11-02_16-59-11

ВНИМАНИЕ: Это заменит текущие данные в БД!
[2025-11-02 16:59:13] Очистка текущих данных в БД...
DROP TABLE
[2025-11-02 16:59:13] ✓ БД очищена
[2025-11-02 16:59:13] Извлечение и восстановление данных...
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 row)

SET
SET
SET
SET
SET
SET
CREATE TABLE
ALTER TABLE
CREATE SEQUENCE
ALTER TABLE
ALTER SEQUENCE
ALTER TABLE
COPY 7
 setval 
--------
     12
(1 row)

ALTER TABLE
[2025-11-02 16:59:14] ✓ Данные успешно восстановлены из: postgres-2025-11-02_16-59-11
[2025-11-02 16:59:14] Количество задач в БД: 7
========================================
[2025-11-02 16:59:14] Восстановление завершено
========================================
make[1]: Leaving directory '/home/app/Work-project'

6. Проверка восстановленных данных:
[
  {
    "description": "Важная задача 1",
    "id": 6,
    "status": "в процессе"
  },
  {
    "description": "Важная задача 2",
    "id": 7,
    "status": "завершено"
  },
  {
    "description": "Важная задача 3",
    "id": 8,
    "status": "завершено"
  }
]

✓ Тестирование завершено
