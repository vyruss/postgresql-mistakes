-- Customers go in this table.
CREATE TABLE customers (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    first_name text NOT NULL,
    middle_name text,
    last_name text,
    marketing_consent boolean DEFAULT false NOT NULL
);


-- This is where we hold contact details for customers.
CREATE TABLE customer_contact_details (
    id bigint PRIMARY KEY REFERENCES customers(id),
    email text DEFAULT '' NOT NULL,
    street_address text,
    city text,
    state text,
    country text,
    phone_no text
);
CREATE INDEX on customer_contact_details (email);


-- Each invoice for an order group goes in here.
CREATE TABLE invoices (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    amount numeric NOT NULL,
    customer bigint REFERENCES customers(id),
    paid boolean DEFAULT false NOT NULL,
    order_group bigint REFERENCES order_groups(id),
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


-- We represent order status by an enumeration.
CREATE TYPE order_status AS ENUM (
    'Placed',
    'Fulfilled',
    'Cancelled'
);


-- Order groups aggregate large orders for multiple items.
CREATE TABLE order_groups (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    status order_status,
    placed_at timestamp with time zone,
    updated_at timestamp with time zone,
    customer bigint REFERENCES customers(id)
);


-- Table to hold orders for individual items or services.
CREATE TABLE orders (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_group bigint REFERENCES order_groups(id),
    status order_status,
    placed_at timestamp with time zone,
    updated_at timestamp with time zone,
    item integer,
    service integer
);


-- We hold payments for specific invoices in here.
CREATE TABLE payments (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    tstamp timestamp with time zone NOT NULL,
    amount numeric NOT NULL,
    invoice bigint REFERENCES invoices(id)
);
CREATE INDEX ON payments (tstamp);


-- Our list of suppliers and their details.
CREATE TABLE suppliers (
    id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_name text,
    state text,
    country text,
    phone_no text,
    email text
);


-- This table holds customer service ticket details.
CREATE TABLE tickets (
    id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    content text,
    status smallint,
    opened_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamptz
);


-- We represent the type of each email sent by an enumeration.
CREATE TYPE email_type AS ENUM (
    'Invoice reminder',
    'Welcome',
    'Account closed',
    'Happy birthday'
);


-- This table is the history of all emails sent out to customers.
CREATE TABLE sent_emails (
    tstamp timestamp with time zone PRIMARY KEY DEFAULT CURRENT_TIMESTAMP
    NOT NULL,
    customer bigint REFERENCES customers(id),
    type email_type,
    invoice bigint REFERENCES invoices(id)
);


-- This table records energy usage readings for each of the branches.
CREATE TABLE energy_usage (
    branch_id integer NOT NULL,
    reading_time timestamptz DEFAULT CURRENT_TIMESTAMP,
    reading numeric NOT NULL,
    unit varchar DEFAULT 'kWh' NOT NULL
);


-- Logging of user activity for audit purposes.
CREATE TABLE public.audit_log (
    what text,
    who text,
    id bigint,
    tstamp timestamp with time zone
);


-- Data for customers and customer_contact_details tables
-- NOTE: Load data from customers_and_customer_contact_details_dump.sql
-- at https://github.com/vyruss/postgresql-mistakes/


-- Data for suppliers table
INSERT INTO suppliers (company_name, state, country, email) VALUES
('Omni Consumer Products', 'MI', 'United States of America',
     'ocp@example.com'),
('Yoyodyne',null,'Japan','yoyodyne@example.com');


-- Data for orders, order_groups, invoices, payments, sent_emails tables
DO $$
DECLARE _id bigint;
DECLARE _t timestamptz;
BEGIN
SELECT CURRENT_DATE INTO _t;
FOR i IN 1 .. 50000 LOOP
    INSERT INTO order_groups (status, placed_at, updated_at, customer)
    VALUES ('Fulfilled',
        ('2023-10-18 00:01:28.000+1'::timestamptz + (i * INTERVAL '1 s')),
        ('2023-10-18 00:01:28.000+1'::timestamptz + (i * INTERVAL '1 s')),
        TRUNC(RANDOM() * 14000 + 1)) RETURNING id INTO _id;
    INSERT INTO orders (order_group, status, placed_at, updated_at,
        item) VALUES
        (_id, 'Fulfilled',
        ('2023-10-18 00:01:28.000+1'::timestamptz + (i * INTERVAL '1 s')),
        ('2023-10-18 00:01:28.000+1'::timestamptz + (i * INTERVAL '1 s')),
        TRUNC(RANDOM() * 1000 + 1));
    INSERT INTO invoices (amount, customer, paid, order_group,
        created_at, updated_at) VALUES
        (59.95, (SELECT customer FROM order_groups WHERE id=_id), 't', _id,
        ('2023-10-18 00:01:28.000+1'::timestamptz + (i * INTERVAL '1 s')),
        ('2023-10-18 00:01:28.000+1'::timestamptz + (i * INTERVAL '1 s')
        + INTERVAL '30 s')) RETURNING id INTO _id;
    INSERT INTO payments (tstamp, amount, invoice)
    VALUES (('2023-10-18 00:01:28.000+1'::timestamptz + (i * INTERVAL '1 s')
        + INTERVAL '30 s'), 59.95, _id);
END LOOP;
FOR i IN 1 .. 200000 LOOP
    INSERT INTO order_groups (status, placed_at, updated_at, customer)
    VALUES ('Placed', _t - INTERVAL '2 d' + (i * INTERVAL '1 s'),
        _t - INTERVAL '2 d' + (i * INTERVAL '1 s'),
        TRUNC(RANDOM() * 14000 + 1)) RETURNING id INTO _id;
    INSERT INTO orders (order_group, status, placed_at, updated_at,
        item) VALUES
        (_id, 'Placed', _t - INTERVAL '2 d' + (i * INTERVAL '1 s'),
        _t - INTERVAL '2 d' + (i * INTERVAL '1 s'),
        TRUNC(RANDOM() * 1000 + 1));
    INSERT INTO invoices (amount, customer, paid, order_group,
        created_at, updated_at) VALUES
        (59.95, (SELECT customer FROM order_groups WHERE id=_id), 't', _id,
        _t - INTERVAL '2 d' + (i * INTERVAL '1 s'),
        _t - INTERVAL '2 d' + (i * INTERVAL '1 s') + INTERVAL '30 s')
        RETURNING id INTO _id;
    INSERT INTO payments (tstamp, amount, invoice)
    VALUES (_t - INTERVAL '2 d' + (i * INTERVAL '1 s') + INTERVAL '30 s',
        59.95, _id);
END LOOP;
WITH o AS (SELECT id FROM orders ORDER BY RANDOM() LIMIT 1350 FOR UPDATE)
    UPDATE orders SET item = NULL, service = 21 FROM o WHERE orders.id=o.id;
WITH i AS (SELECT id FROM invoices ORDER BY RANDOM() LIMIT 1350 FOR UPDATE)
    UPDATE invoices SET paid='f' FROM i WHERE invoices.id=i.id;
WITH i AS (SELECT id, created_at, customer FROM invoices
       WHERE paid='f')
    INSERT INTO sent_emails (tstamp, customer, type, invoice)
        SELECT i.created_at + INTERVAL '1 d', i.customer,
            'Invoice reminder', i.id FROM i;
END $$ LANGUAGE plpgsql;


-- Data for tickets table
INSERT into tickets (status, content, opened_at, closed_at)
    SELECT 20, 'issue text',
    '2023-05-01'::timestamptz + n * (INTERVAL '1 m'),
    '2023-05-01'::timestamptz + n * (INTERVAL '1 m') + INTERVAL '1 d'
    FROM generate_series(1,1000000) n;
INSERT into tickets (status, content, opened_at)
    SELECT 10, 'issue text',
    '2024-05-01'::timestamptz + n * (INTERVAL '1 m')
    FROM generate_series(1,500) n;
