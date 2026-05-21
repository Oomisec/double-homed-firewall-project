#!/usr/bin/env python3
"""
db_test.py — Testar anslutning från webbservern till PostgreSQL-databasen.
Bevisar att webbservern kan nå databasen på applikationsnivå via port 5432.
"""

import psycopg2
import sys

DB_HOST = "10.0.3.2"
DB_NAME = "appdb"
DB_USER = "webuser"
DB_PASS = "secret123"
DB_PORT = 5432

def test_connection():
    print("=" * 50)
    print(" Databas-anslutningstest — Double-homed Firewall")
    print("=" * 50)
    print(f"\n Ansluter till {DB_HOST}:{DB_PORT}...")

    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
            port=DB_PORT,
            connect_timeout=5
        )
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f" PASS  Anslutning lyckades!")
        print(f"       PostgreSQL-version: {version[0][:50]}")
        cursor.execute("SELECT current_database(), current_user;")
        db, user = cursor.fetchone()
        print(f"       Databas: {db} · Användare: {user}")
        cursor.close()
        conn.close()
        print("\n PASS  Webbservern kan nå databasen på applikationsnivå")
        print("=" * 50)
        sys.exit(0)
    except Exception as e:
        print(f" FAIL  Anslutning misslyckades: {e}")
        print("=" * 50)
        sys.exit(1)

if __name__ == "__main__":
    test_connection()