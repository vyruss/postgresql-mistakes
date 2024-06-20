#!/usr/bin/env/python3
import psycopg, datetime

with psycopg.connect("dbname=frogge user=frogge") as conn:
    with conn.cursor(row_factory=psycopg.rows.dict_row) as cur:
        t1 = datetime.datetime.now()
        cur.execute('''SELECT *
                       FROM tickets''')
        res = cur.fetchmany(10000)
        while (res):
            tkts = []
            for row in res:
                if row['status'] == 10:
                    tkts += row['id'],
            res = cur.fetchmany(10000)
        t2 = datetime.datetime.now()
        print(f'"SELECT *" with no predicate took {t2-t1} seconds.')
