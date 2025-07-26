# db.py
import mysql.connector

def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="Dlwldms0708@",
        database="my_diary"
    )