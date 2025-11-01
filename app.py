from flask import Flask, request, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)


def get_db_connection():
    conn = psycopg2.connect(
        dbname="tasksdb",
        user="taskuser",
        password="dbpass",
        host="db",
        port="5432"
    )
    return conn

@app.route('/')
def index():
    return 'TaskZilla API is running. Use /tasks endpoint.'

@app.route('/tasks', methods=['GET'])
def get_tasks():
    conn = get_db_connection()
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT * FROM tasks ORDER BY id;")
        tasks = cur.fetchall()
    conn.close()
    return jsonify(tasks)


@app.route('/tasks', methods=['POST'])
def create_task():
    data = request.json
    description = data.get('description')
    status = data.get('status', 'в процессе')

    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO tasks (description, status) VALUES (%s, %s) RETURNING id;",
            (description, status))
        task_id = cur.fetchone()[0]
        conn.commit()
    conn.close()
    return jsonify({"id": task_id, "description": description, "status": status}), 201

@app.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    data = request.json
    description = data.get('description')
    status = data.get('status')

    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE tasks SET description = %s, status = %s WHERE id = %s;",
            (description, status, task_id))
        conn.commit()
    conn.close()
    return jsonify({"id": task_id, "description": description, "status": status})

@app.route('/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    conn = get_db_connection()
    with conn.cursor() as cur:
        cur.execute("DELETE FROM tasks WHERE id = %s;", (task_id,))
        conn.commit()
    conn.close()
    return '', 204

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5041)
