import os
import sqlite3
from flask import Flask, request, redirect, url_for
from markupsafe import escape 

app = Flask(__name__)

DB_PATH = "/data/todos.db"
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    conn.execute("CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY, text TEXT NOT NULL)")
    conn.commit()
    conn.close()

@app.route("/")
def index():
    conn = get_db()
    todos = conn.execute("SELECT * FROM todos ORDER BY id DESC").fetchall()
    conn.close()
    html = "<h1>Todo</h1><form method='POST' action='/add'>"
    html += "<input name='todo' placeholder='new todo'><button>Add</button></form><ul>"
    for t in todos:
        html += f"<li>{escape(t['text'])} <a href='/delete/{t['id']}'>[delete]</a></li>"
    html += "</ul>"
    return html

@app.route("/add", methods=["POST"])
def add():
    text = request.form["todo"]
    conn = get_db()
    conn.execute("INSERT INTO todos (text) VALUES (?)", (text,))
    conn.commit()
    conn.close()
    return redirect(url_for("index"))

@app.route("/delete/<int:todo_id>")
def delete(todo_id):
    conn = get_db()
    conn.execute("DELETE FROM todos WHERE id=?", (todo_id,))
    conn.commit()
    conn.close()
    return redirect(url_for("index"))

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)