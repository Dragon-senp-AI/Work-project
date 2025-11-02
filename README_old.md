# OS Ubuntu 22


# ЗАДАНИЕ 1
# Поднять PostgreSQL

# Отчет что всё выводит

app@app-virtual-machine:~$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   180  100   180    0     0  15165      0 --:--:-- --:--:-- --:--:-- 16363
[
  {
    "description": "Сделать домашку",
    "id": 1,
    "status": "в процессе"
  }
]

app@app-virtual-machine:~$ curl -X POST -H "Content-Type: application/json" \
  -d '{"description": "Изучить Docker", "status": "в процессе"}' \
  http://localhost:5041/tasks
{"description":"\u0418\u0437\u0443\u0447\u0438\u0442\u044c Docker","id":2,"status":"\u0432 \u043f\u0440\u043e\u0446\u0435\u0441\u0441\u0435"}


app@app-virtual-machine:~$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   322  100   322    0     0  28660      0 --:--:-- --:--:-- --:--:-- 29272
[
  {
    "description": "Сделать домашку",
    "id": 1,
    "status": "в процессе"
  },
  {
    "description": "Изучить Docker",
    "id": 2,
    "status": "в процессе"
  }
]

app@app-virtual-machine:~$ curl -X PUT -H "Content-Type: application/json" \
  -d '{"description": "Домашка выполнена", "status": "завершено"}' \
  http://localhost:5041/tasks/1
{"description":"\u0414\u043e\u043c\u0430\u0448\u043a\u0430 \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u0430","id":1,"status":"\u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u043e"}

app@app-virtual-machine:~$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   333  100   333    0     0  29009      0 --:--:-- --:--:-- --:--:-- 30272
[
  {
    "description": "Домашка выполнена",
    "id": 1,
    "status": "завершено"
  },
  {
    "description": "Изучить Docker",
    "id": 2,
    "status": "в процессе"
  }
]

# Удаляем задачу

app@app-virtual-machine:~$ curl -X DELETE http://localhost:5041/tasks/2 -v

*   Trying 127.0.0.1:5041...
* Connected to localhost (127.0.0.1) port 5041 (#0)
> DELETE /tasks/2 HTTP/1.1
> Host: localhost:5041
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
* HTTP 1.0, assume close after body
< HTTP/1.0 204 NO CONTENT
< Content-Type: text/html; charset=utf-8
< Server: Werkzeug/2.0.3 Python/3.10.12
< Date: Sat, 01 Nov 2025 20:15:31 GMT
< 
* Closing connection 0
* 
app@app-virtual-machine:~$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   191  100   191    0     0  12451      0 --:--:-- --:--:-- --:--:-- 12733
[
  {
    "description": "Домашка выполнена",
    "id": 1,
    "status": "завершено"
  }
]


# ЗАДАНИЕ 2
# Перевести в контейнеры Docker

app@app-virtual-machine:~/Work-project$ sudo systemctl stop postgresql

app@app-virtual-machine:~/Work-project$ docker build -t taskzilla-api .

app@app-virtual-machine:~/Work-project$ docker-compose up -d

app@app-virtual-machine:~/Work-project$ docker images

REPOSITORY                    TAG         IMAGE ID       CREATED          SIZE
taskzilla-api                 latest      a3ad44717e5e   20 minutes ago   141MB
work-project_web              latest      a3ad44717e5e   20 minutes ago   141MB
postgres                      14-alpine   1d3a64896a65   2 weeks ago      272MB
gcr.io/k8s-minikube/kicbase   v0.0.48     c6b5532e987b   7 weeks ago      1.31GB

app@app-virtual-machine:~/Work-project$ docker ps

CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS                    PORTS                                         NAMES

c2e82d71405c   work-project_web     "python app.py"          18 minutes ago   Up 18 minutes             0.0.0.0:5041->5041/tcp, [::]:5041->5041/tcp   taskzilla-web

e1692b76a936   postgres:14-alpine   "docker-entrypoint.s…"   18 minutes ago   Up 18 minutes (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   taskzilla-db


# Проверка доступности контейнеров

app@app-virtual-machine:~/Work-project$ docker exec taskzilla-web python -c "
import socket
try:
    ip = socket.gethostbyname('db')
    print(f'Контейнер db доступен по адресу: {ip}')
except:
    print('Ошибка: не удалось разрешить имя db')
"

Контейнер db доступен по адресу: 172.18.0.2


# По DNS

app@app-virtual-machine:~/Work-project$ docker exec taskzilla-web getent hosts db

172.18.0.2      db


# Проверка БД

app@app-virtual-machine:~/Work-project$ curl -X POST -H "Content-Type: application/json" \
  -d '{"description": "Сделать домашку в Docker", "status": "в процессе"}' \
  http://localhost:5041/tasks
{"description":"\u0421\u0434\u0435\u043b\u0430\u0442\u044c \u0434\u043e\u043c\u0430\u0448\u043a\u0443 \u0432 Docker","id":1,"status":"\u0432 \u043f\u0440\u043e\u0446\u0435\u0441\u0441\u0435"}


app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   194  100   194    0     0  14574      0 --:--:-- --:--:-- --:--:-- 14923
[
  {
    "description": "Сделать домашку в Docker",
    "id": 1,
    "status": "в процессе"
  }
]

app@app-virtual-machine:~/Work-project$ curl -X POST -H "Content-Type: application/json" \
  -d '{"description": "Изучить Docker Compose", "status": "в процессе"}' \
  http://localhost:5041/tasks
{"description":"\u0418\u0437\u0443\u0447\u0438\u0442\u044c Docker Compose","id":2,"status":"\u0432 \u043f\u0440\u043e\u0446\u0435\u0441\u0441\u0435"}

app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   344  100   344    0     0  32264      0 --:--:-- --:--:-- --:--:-- 34400
[
  {
    "description": "Сделать домашку в Docker",
    "id": 1,
    "status": "в процессе"
  },
  {
    "description": "Изучить Docker Compose",
    "id": 2,
    "status": "в процессе"
  }
]

app@app-virtual-machine:~/Work-project$ curl -X PUT -H "Content-Type: application/json" \
  -d '{"description": "Домашка в Docker выполнена", "status": "завершено"}' \
  http://localhost:5041/tasks/1
{"description":"\u0414\u043e\u043c\u0430\u0448\u043a\u0430 \u0432 Docker \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u0430","id":1,"status":"\u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u043e"}

app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   355  100   355    0     0  20095      0 --:--:-- --:--:-- --:--:-- 20882
[
  {
    "description": "Домашка в Docker выполнена",
    "id": 1,
    "status": "завершено"
  },
  {
    "description": "Изучить Docker Compose",
    "id": 2,
    "status": "в процессе"
  }
]

app@app-virtual-machine:~/Work-project$ curl -X DELETE http://localhost:5041/tasks/2 -v

*   Trying 127.0.0.1:5041...
* Connected to localhost (127.0.0.1) port 5041 (#0)
> DELETE /tasks/2 HTTP/1.1
> Host: localhost:5041
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
* HTTP 1.0, assume close after body
< HTTP/1.0 204 NO CONTENT
< Content-Type: text/html; charset=utf-8
< Server: Werkzeug/2.0.3 Python/3.10.19
< Date: Sat, 01 Nov 2025 20:43:40 GMT
< 
* Closing connection 0

app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   205  100   205    0     0  17874      0 --:--:-- --:--:-- --:--:-- 20500
[
  {
    "description": "Домашка в Docker выполнена",
    "id": 1,
    "status": "завершено"
  }
]


# ЗАДАЧА 3

# Создание бекапа

app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   529  100   529    0     0  32362      0 --:--:-- --:--:-- --:--:-- 33062
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


app@app-virtual-machine:~/Work-project$ ./scripts/backup.sh

==========================================
Начало резервного копирования БД
Время: 2025-11-02 00:17:23
==========================================
✓ Бэкап успешно создан: /home/app/Work-project/backups/backup_tasksdb_20251102_001723.sql
✓ Размер файла: 4,0K
✓ Бэкап сжат: /home/app/Work-project/backups/backup_tasksdb_20251102_001723.sql.gz
✓ Размер после сжатия: 4,0K

Очистка старых бэкапов (оставляем последние 5)...
✓ Всего бэкапов: 1 (чистка не требуется)

Текущие бэкапы:
/home/app/Work-project/backups/backup_tasksdb_20251102_001723.sql.gz (965)

==========================================
Резервное копирование завершено
==========================================


app@app-virtual-machine:~/Work-project$ ls -lh backups/

total 4,0K
-rw-rw-r-- 1 app app 965 ноя  2 00:17 backup_tasksdb_20251102_001723.sql.gz

# Удаление и Восстановление 

app@app-virtual-machine:~/Work-project$ curl -X DELETE http://localhost:5041/tasks/4

app@app-virtual-machine:~/Work-project$ curl -X DELETE http://localhost:5041/tasks/5

app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100     3  100     3    0     0    244      0 --:--:-- --:--:-- --:--:--   250
[]



app@app-virtual-machine:~/Work-project$ ./scripts/restore.sh

==========================================
Восстановление базы данных из бэкапа
==========================================

Доступные бэкапы:
     1  -rw-rw-r-- 1 app app 965 ноя  2 00:17 /home/app/Work-project/backups/backup_tasksdb_20251102_001723.sql.gz

Выбран бэкап: backup_tasksdb_20251102_001723.sql.gz

Продолжить восстановление? (yes/no): yes

Восстановление данных...
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
ERROR:  relation "tasks" already exists
ALTER TABLE
ERROR:  relation "tasks_id_seq" already exists
ALTER TABLE
ALTER SEQUENCE
ALTER TABLE
COPY 3
 setval 
--------
      5
(1 row)

ERROR:  multiple primary keys for table "tasks" are not allowed
✓ База данных успешно восстановлена!
✓ Количество задач в БД:      3

==========================================
Восстановление завершено
==========================================


app@app-virtual-machine:~/Work-project$ curl http://localhost:5041/tasks | jq

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   529  100   529    0     0  39351      0 --:--:-- --:--:-- --:--:-- 40692
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

# Настройка crontab
crontab -e

0 * * * * /home/app/Work-project/scripts/backup.sh >> /home/app/Work-project/backups/backup.log 2>&1



# ЗАДАЧА 4

# Создал Makefile (УВАУУУУУ!!! Это пушка))))

app@app-virtual-machine:~/Work-project$ make start

Запуск сервисов...
docker-compose up 
Creating network "taskzilla-network" with the default driver
Creating taskzilla-db ... done
Creating taskzilla-web ... done
✓ Сервисы запущены

app@app-virtual-machine:~/Work-project$ make status

Статус контейнеров:
    Name                   Command                 State                        Ports                  
-------------------------------------------------------------------------------------------------------
taskzilla-db    docker-entrypoint.sh postgres   Up (healthy)   0.0.0.0:5432->5432/tcp,:::5432->5432/tcp
taskzilla-web   python app.py                   Up (healthy)   0.0.0.0:5041->5041/tcp,:::5041->5041/tcp

app@app-virtual-machine:~/Work-project$ make health

Проверка здоровья сервисов

PostgreSQL:
/var/run/postgresql:5432 - accepting connections
✓ БД доступна

API:
✓ API доступен

# Logs

app@app-virtual-machine:~/Work-project$ make logs

docker-compose logs -f
Attaching to taskzilla-web, taskzilla-db
taskzilla-web |  * Serving Flask app 'app' (lazy loading)
taskzilla-web |  * Environment: production
taskzilla-web |    WARNING: This is a development server. Do not use it in a production deployment.
taskzilla-web |    Use a production WSGI server instead.
taskzilla-web |  * Debug mode: off
taskzilla-web |  * Running on all addresses.
taskzilla-web |    WARNING: This is a development server. Do not use it in a production deployment.
taskzilla-web |  * Running on http://172.18.0.3:5041/ (Press CTRL+C to quit)
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:49:15] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:49:30] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:49:45] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:50:00] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:50:15] "GET / HTTP/1.1" 200 -
taskzilla-web | 172.18.0.1 - - [01/Nov/2025 21:50:21] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:50:30] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:50:45] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:51:00] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:51:15] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:51:30] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:51:45] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:52:00] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:52:16] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:52:31] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:52:46] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:53:01] "GET / HTTP/1.1" 200 -
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:53:16] "GET / HTTP/1.1" 200 -
taskzilla-db | 
taskzilla-db | PostgreSQL Database directory appears to contain a database; Skipping initialization
taskzilla-db | 
taskzilla-db | 2025-11-01 21:49:04.727 UTC [1] LOG:  starting PostgreSQL 14.19 on x86_64-pc-linux-musl, compiled by gcc (Alpine 14.2.0) 14.2.0, 64-bit
taskzilla-db | 2025-11-01 21:49:04.727 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
taskzilla-db | 2025-11-01 21:49:04.728 UTC [1] LOG:  listening on IPv6 address "::", port 5432
taskzilla-db | 2025-11-01 21:49:04.730 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
taskzilla-db | 2025-11-01 21:49:04.739 UTC [26] LOG:  database system was shut down at 2025-11-01 21:48:49 UTC
taskzilla-db | 2025-11-01 21:49:04.748 UTC [1] LOG:  database system is ready to accept connections
taskzilla-web | 127.0.0.1 - - [01/Nov/2025 21:53:31] "GET / HTTP/1.1" 200 -
