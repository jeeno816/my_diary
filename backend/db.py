# db.py
import mysql.connector

db = mysql.connector.connect(
    host="mydiary-main.up.railway.app",
    user="root",
    password="ikuHPVzXkwJJyWBWlfiGJWOmuatObixw",
    database="railway"
)

def get_db():
    return mysql.connector.connect(
        host="mydiary-main.up.railway.app",
        user="root",
        password="ikuHPVzXkwJJyWBWlfiGJWOmuatObixw",
        database="railway"
    )