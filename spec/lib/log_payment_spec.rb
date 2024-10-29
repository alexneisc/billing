require 'pg'

RSpec.describe LogPayment do
  it 'creates record in payment_logs' do
    Timecop.freeze

    payment_logs_queue = PG_CONN.exec("SELECT id FROM payment_logs;").values

    expect(payment_logs_queue).to be_empty

    described_class.new(123, 100, 50, 3, Time.now, :insufficient_funds).call

    subscription_id, full_payment_amount, payment_amount, attempt, time, status = PG_CONN.exec('
      SELECT subscription_id, full_payment_amount, payment_amount, attempt, time, status
        FROM payment_logs;
    ').values.first

    expect(subscription_id).to eq(123)
    expect(full_payment_amount).to eq(100)
    expect(payment_amount).to eq(50)
    expect(attempt).to eq(3)
    expect(time.to_s).to eq(Time.now.to_s)
    expect(status).to eq('insufficient_funds')
  end
end
