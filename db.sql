create table subscriptions
(
    id             bigint default nextval('billing_id_seq'::regclass) not null
        constraint subscriptions_pk
            primary key,
    payment_amount numeric(10, 2)                                     not null
);

create table transaction_queue
(
    id                  bigserial
        constraint transaction_queue_pk
            primary key,
    subscription_id     integer,
    full_payment_amount numeric(10, 2),
    payment_amount      numeric(10, 2),
    attempt             integer,
    payment_date        date not null
);

create index transaction_queue_payment_date_index
    on transaction_queue (payment_date);

create table payment_logs
(
    id                  serial
        constraint payment_logs_pk
            primary key,
    subscription_id     integer,
    full_payment_amount numeric(10, 2),
    payment_amount      numeric(10, 2),
    attempt             integer,
    time                timestamp,
    status              varchar
);
