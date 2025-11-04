from flask import Flask, request, jsonify
import sqlite3

app = Flask(__name__)

def get_db():
    conn = sqlite3.connect(":memory:")
    conn.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)")
    conn.execute("INSERT OR IGNORE INTO users (id, name) VALUES (1, 'alice')")
    return conn

@app.route("/user")
def user():
    # ❌ Intentional SQL injection via string concatenation added
    name = request.args.get("name", "")
    db = get_db()
    db.execute("SELECT id, name FROM users WHERE name = '" + name + "'")
    sql = "SELECT id, name FROM users WHERE name = '" + name + "'"
    cur = db.execute(sql)
    rows = [{"id": r[0], "name": r[1]} for r in cur.fetchall()]
    return jsonify(rows)
