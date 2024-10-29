require 'pg'

RSpec.describe CreateTransactionQueue do
  it 'creates record in transaction_queue' do
    PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
    id = PG_CONN.exec("SELECT id FROM subscriptions;").values.first.first
    transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

    expect(transaction_queue).to be_empty

    described_class.new.call

    subscription_id, full_payment_amount, payment_amount, attempt, payment_date = PG_CONN.exec('
      SELECT subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        FROM transaction_queue;
    ').values.first

    expect(subscription_id).to eq(id)
    expect(full_payment_amount).to eq(100)
    expect(payment_amount).to eq(100)
    expect(attempt).to eq(1)
    expect(payment_date.to_s).to eq(Time.now.strftime("%Y-%m-%d"))
  end
end
