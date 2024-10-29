Before starting, you need to create the `billing` and `billing_test` databases with tables. The structure of the tables in the `db.sql` file.

List of tables:
1. `subscriptions` - this table stores all subscriptions. It has fields `id` and `payment_amount`
2. `transaction_queue` - this is a table for a payment queue. The data in this table is temporary and is deleted when an attempt is made to withdraw a payment
3. `payment_logs` - this table stores all payments that have not been withdrawn. Including if there was a script error or something like that

Rake tasks:
1. `transaction_queue:create` - this script takes data from the `subscriptions` table and creates a payment queue in the `transaction_queue` table. It should be run once a month, or at the required interval of payment withdrawals
2. `transaction_queue:process` - this script sends payment requests. If the payment fails, it is added to the queue again, but with a smaller amount. This script also creates records in the `payment_logs` table
