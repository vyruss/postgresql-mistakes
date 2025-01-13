#!/usr/bin/env/python3
import psycopg

with psycopg.connect("dbname=frogge user=frogge") as conn:
    with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
        cur.execute('''SELECT id, content::bytea FROM support.tickets''')
        res = cur.fetchall()
        for row in res:
            print(row['id'], row['content'].decode('UTF-8'))
