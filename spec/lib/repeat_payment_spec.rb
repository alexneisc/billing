require 'pg'

RSpec.describe RepeatPayment do
  context 'attempt is 1' do
    it 'creates record in transaction_queue' do
      transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

      expect(transaction_queue).to be_empty

      described_class.new(123, 100, 1).call

      subscription_id, full_payment_amount, payment_amount, attempt, payment_date = PG_CONN.exec('
        SELECT subscription_id, full_payment_amount, payment_amount, attempt, payment_date
          FROM transaction_queue;
      ').values.first

      expect(subscription_id).to eq(123)
      expect(full_payment_amount).to eq(100)
      expect(payment_amount).to eq(75)
      expect(attempt).to eq(2)
      expect(payment_date.to_s).to eq(Time.now.strftime("%Y-%m-%d"))
    end
  end

  context 'attempt is 2' do
    it 'creates record in transaction_queue' do
      transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

      expect(transaction_queue).to be_empty

      described_class.new(123, 100, 2).call

      subscription_id, full_payment_amount, payment_amount, attempt, payment_date = PG_CONN.exec('
        SELECT subscription_id, full_payment_amount, payment_amount, attempt, payment_date
          FROM transaction_queue;
      ').values.first

      expect(subscription_id).to eq(123)
      expect(full_payment_amount).to eq(100)
      expect(payment_amount).to eq(50)
      expect(attempt).to eq(3)
      expect(payment_date.to_s).to eq(Time.now.strftime("%Y-%m-%d"))
    end
  end

  context 'attempt is 3' do
    it 'creates record in transaction_queue' do
      transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

      expect(transaction_queue).to be_empty

      described_class.new(123, 100, 3).call

      subscription_id, full_payment_amount, payment_amount, attempt, payment_date = PG_CONN.exec('
        SELECT subscription_id, full_payment_amount, payment_amount, attempt, payment_date
          FROM transaction_queue;
      ').values.first

      expect(subscription_id).to eq(123)
      expect(full_payment_amount).to eq(100)
      expect(payment_amount).to eq(25)
      expect(attempt).to eq(4)
      expect(payment_date.to_s).to eq(Time.now.strftime("%Y-%m-%d"))
    end
  end

  context 'attempt is 4' do
    it 'creates record in transaction_queue' do
      transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

      expect(transaction_queue).to be_empty

      described_class.new(123, 100, 4).call

      transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

      expect(transaction_queue).to be_empty
    end
  end
end
