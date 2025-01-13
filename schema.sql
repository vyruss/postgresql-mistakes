CREATE SCHEMA erp;
CREATE SCHEMA audit;
CREATE SCHEMA support;
CREATE SCHEMA test;


-- Customers go in this table.
CREATE TABLE erp.customers (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    first_name text NOT NULL,
    middle_name text,
    last_name text,
    marketing_consent boolean DEFAULT false NOT NULL
);


-- This is where we hold contact details for customers.
CREATE TABLE erp.customer_contact_details (
    id bigint PRIMARY KEY REFERENCES erp.customers(id),
    email text DEFAULT '' NOT NULL,
    street_address text,
    city text,
    state text,
    country text,
    phone_no text
);
CREATE INDEX ON erp.customer_contact_details (email);


-- We represent order status by an enumeration.
CREATE TYPE erp.order_status AS ENUM (
    'Placed',
    'Fulfilled',
    'Cancelled'
);


-- Order groups aggregate large orders for multiple items.
CREATE TABLE erp.order_groups (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    status erp.order_status,
    placed_at timestamp with time zone,
    updated_at timestamp with time zone,
    customer bigint REFERENCES erp.customers(id)
);


-- Table to hold orders for individual items or services.
CREATE TABLE erp.orders (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    order_group bigint REFERENCES erp.order_groups(id),
    status erp.order_status,
    placed_at timestamp with time zone,
    updated_at timestamp with time zone,
    item integer,
    service integer
);


-- Each invoice for an order group goes in here.
CREATE TABLE erp.invoices (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    amount numeric NOT NULL,
    customer bigint REFERENCES erp.customers(id),
    paid boolean DEFAULT false NOT NULL,
    order_group bigint REFERENCES erp.order_groups(id),
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


-- We hold payments for specific invoices in here.
CREATE TABLE erp.payments (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    tstamp timestamp with time zone NOT NULL,
    amount numeric NOT NULL,
    invoice bigint REFERENCES erp.invoices(id)
);
CREATE INDEX ON erp.payments (tstamp);


-- Our list of suppliers and their details.
CREATE TABLE erp.suppliers (
    id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_name text,
    state text,
    country text,
    phone_no text,
    email text
);


-- We represent the type of each email sent by an enumeration.
CREATE TYPE erp.email_type AS ENUM (
    'Invoice reminder',
    'Welcome',
    'Account closed',
    'Happy birthday'
);


-- This table is the history of all emails sent out to customers.
CREATE TABLE erp.sent_emails (
    tstamp timestamp with time zone PRIMARY KEY DEFAULT CURRENT_TIMESTAMP
    NOT NULL,
    customer bigint REFERENCES erp.customers(id),
    type erp.email_type,
    invoice bigint REFERENCES erp.invoices(id)
);


-- This table records energy usage readings for each of the branches.
CREATE TABLE erp.energy_usage (
    branch_id integer NOT NULL,
    reading_time timestamptz DEFAULT CURRENT_TIMESTAMP,
    reading numeric NOT NULL,
    unit varchar DEFAULT 'kWh' NOT NULL
);


-- This table holds customer service ticket details.
CREATE TABLE support.tickets (
    id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    content text,
    status smallint,
    opened_at timestamptz DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamptz
);


-- Logging of user activity for audit purposes.
CREATE TABLE audit.audit_log (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    what text,
    who text,
    tstamp timestamp with time zone
);
