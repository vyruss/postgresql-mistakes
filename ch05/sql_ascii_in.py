#!/usr/bin/env/python3
import psycopg

english_text = ("Good evening, I would like to return my last order "
                + "please.").encode('iso-8859-1')
greek_text = ("Καλησπέρα, θα ήθελα να επιστρέψω την τελευταία μου παραγγελία "
              + "παρακαλώ.").encode('windows-1253')
japanese_text = ("こんばんは、前回の注文を返品したいのですがお願いします。"
                 ).encode('shift_jis')

with psycopg.connect("dbname=frogge user=frogge") as conn:
    with conn.cursor() as cur:
        cur.execute('''INSERT INTO support.tickets (content, status)
                       VALUES (%s, 20), (%s, 20), (%s, 20)''',
                       (english_text, greek_text, japanese_text))
