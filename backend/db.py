# db.py
import mysql.connector

db = mysql.connector.connect(
    host="mysql.railway.internal",
    user="root",
    password="ikuHPVzXkwJJyWBWlfiGJWOmuatObixw@",
    database="railway"
)

def get_db():
    return mysql.connector.connect(
        host="mysql.railway.internal",
        user="root",
        password="ikuHPVzXkwJJyWBWlfiGJWOmuatObixw@",
        database="railway"
    )