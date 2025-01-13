#!/usr/bin/env/python3
import psycopg, datetime

with psycopg.connect("dbname=frogge user=frogge") as conn:
    with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
        t1 = datetime.datetime.now()
        cur.execute('''SELECT *
                       FROM support.tickets
                       WHERE status = 10''')
        res = cur.fetchall()
        tkts = []
        for row in res:
            tkts += row['id'],
        t2 = datetime.datetime.now()
        print(f'"SELECT *"  took {t2-t1} seconds.')
    with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
        t3 = datetime.datetime.now()
        cur.execute('''SELECT id
                       FROM support.tickets
                       WHERE status = 10''')
        res = cur.fetchall()
        tkts = []
        for row in res:
            tkts += row['id'],
        t4 = datetime.datetime.now()
        print(f'"SELECT id" took {t4-t3} seconds.')
