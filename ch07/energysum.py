#!/usr/bin/env/python3
import psycopg
from datetime import date, timedelta as td

with psycopg.connect("dbname=frogge user=frogge") as conn:
    try:
        while True:
            with conn.cursor() as cur:
                try:
                    # I have learned my lesson about using BETWEEN!
                    cur.execute('''WITH
                                   yesterday AS (
                                       SELECT *
                                       FROM energy_use
                                       WHERE reading_time >=
                                           date_trunc('d', now())
                                           - interval '1d'
                                       AND reading_time <
                                           date_trunc('d', now())),
                                   perbranch AS (
                                       SELECT first_value(reading) OVER w,
                                           last_value(reading) OVER w,
                                           row_number() OVER w
                                       FROM yesterday
                                       WINDOW w AS (
                                           PARTITION BY branch_id
                                           ORDER BY reading_time
                                           RANGE BETWEEN UNBOUNDED PRECEDING
                                           AND UNBOUNDED FOLLOWING))
                                   SELECT sum(last_value - first_value)
                                   FROM perbranch
                                   WHERE row_number=1''')
                    total = cur.fetchone()[0]

                    cur.execute('''INSERT INTO audit_log (what, who, tstamp)
                                   VALUES (%s, %s, now())''',
                        (f"Energy usage for {date.today() - td(days=1)}: "
                         + f"{total} kWh", "Frogge Emporium"))

                    conn.commit()
                    break
                # If this goes wrong, something must be keeping the DB busy
                # and we can just retry
                except psycopg.errors.Error:
                    conn.rollback()
    finally:
        conn.close()
