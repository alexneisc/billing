require 'pg'

RSpec.describe ScheduleSuccessfulPayment do
  it 'creates record in transaction_queue' do
    transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

    expect(transaction_queue).to be_empty

    described_class.new(123, 100, 25).call

    subscription_id, full_payment_amount, payment_amount, attempt, payment_date = PG_CONN.exec('
      SELECT subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        FROM transaction_queue;
    ').values.first

    expect(subscription_id).to eq(123)
    expect(full_payment_amount).to eq(100)
    expect(payment_amount).to eq(75)
    expect(attempt).to eq(4)
    expect(payment_date.to_s).to eq((Time.now + (7 * 60 * 60 * 24)).strftime("%Y-%m-%d"))
  end
end
