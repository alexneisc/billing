require 'pg'
require 'timecop'

RSpec.describe ProcessTransactionQueue do
  it 'calls SendPayment' do
    PG_CONN.exec("INSERT INTO subscriptions (payment_amount) VALUES (100);")
    id = PG_CONN.exec("SELECT id FROM subscriptions;").values.first.first

    PG_CONN.exec("
      INSERT INTO transaction_queue (
        subscription_id, full_payment_amount, payment_amount, attempt, payment_date
      ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
    ")

    send_payment = double(SendPayment)
    allow(SendPayment).to receive(:new).and_return(send_payment)
    allow(send_payment).to receive(:call)

    described_class.new.call

    expect(SendPayment).to have_received(:new).with(id, 100).once
    expect(send_payment).to have_received(:call).once
  end

  it 'removes record from transaction_queue' do
    PG_CONN.exec("INSERT INTO subscriptions (payment_amount) VALUES (100);")
    id = PG_CONN.exec("SELECT id FROM subscriptions;").values.first.first

    PG_CONN.exec("
      INSERT INTO transaction_queue (
        subscription_id, full_payment_amount, payment_amount, attempt, payment_date
      ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
    ")

    send_payment = double(SendPayment)
    allow(SendPayment).to receive(:new).and_return(send_payment)
    allow(send_payment).to receive(:call)

    described_class.new.call

    transaction_queue = PG_CONN.exec("SELECT id FROM transaction_queue;").values

    expect(transaction_queue).to be_empty
  end

  context 'attempt > 1' do
    it 'calls ScheduleSuccessfulPayment' do
      PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
      id = PG_CONN.exec('SELECT id FROM subscriptions;').values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 75, 2, '#{Time.now}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_return(send_payment)
      allow(send_payment).to receive(:call)

      schedule_successful_payment = double(ScheduleSuccessfulPayment)
      allow(ScheduleSuccessfulPayment).to receive(:new).and_return(schedule_successful_payment)
      allow(schedule_successful_payment).to receive(:call)

      described_class.new.call

      expect(ScheduleSuccessfulPayment).to have_received(:new).with(id, 100, 75).once
      expect(schedule_successful_payment).to have_received(:call).once
    end
  end

  context 'attempt == 1' do
    it 'does not calls ScheduleSuccessfulPayment' do
      PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
      id = PG_CONN.exec('SELECT id FROM subscriptions;').values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_return(send_payment)
      allow(send_payment).to receive(:call)

      schedule_successful_payment = double(ScheduleSuccessfulPayment)
      allow(ScheduleSuccessfulPayment).to receive(:new).and_return(schedule_successful_payment)
      allow(schedule_successful_payment).to receive(:call)

      described_class.new.call

      expect(ScheduleSuccessfulPayment).not_to have_received(:new)
      expect(schedule_successful_payment).not_to have_received(:call)
    end
  end

  context 'payment date in the future' do
    it 'does not calls SendPayment' do
      PG_CONN.exec("INSERT INTO subscriptions (payment_amount) VALUES (100);")
      id = PG_CONN.exec("SELECT id FROM subscriptions;").values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 100, 1, '#{Time.parse('2050-06-20')}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_return(send_payment)
      allow(send_payment).to receive(:call)

      described_class.new.call

      expect(SendPayment).not_to have_received(:new)
      expect(send_payment).not_to have_received(:call)
    end
  end

  context 'SendPayment raise FailedPayment' do
    it 'calls LogPayment' do
      Timecop.freeze

      PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
      id = PG_CONN.exec('SELECT id FROM subscriptions;').values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_raise(SendPayment::FailedPayment)
      allow(send_payment).to receive(:call)

      log_payment = double(LogPayment)
      allow(LogPayment).to receive(:new).and_return(log_payment)
      allow(log_payment).to receive(:call)

      described_class.new.call

      expect(LogPayment).to have_received(:new).with(id, 100, 100, 1, Time.now, :failed_payment).once
      expect(log_payment).to have_received(:call).once
    end
  end

  context 'SendPayment raise InsufficientFunds' do
    it 'calls LogPayment' do
      Timecop.freeze

      PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
      id = PG_CONN.exec('SELECT id FROM subscriptions;').values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_raise(SendPayment::InsufficientFunds)
      allow(send_payment).to receive(:call)

      log_payment = double(LogPayment)
      allow(LogPayment).to receive(:new).and_return(log_payment)
      allow(log_payment).to receive(:call)

      described_class.new.call

      expect(LogPayment).to have_received(:new).with(id, 100, 100, 1, Time.now, :insufficient_funds).once
      expect(log_payment).to have_received(:call).once
    end

    it 'calls RepeatPayment' do
      PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
      id = PG_CONN.exec('SELECT id FROM subscriptions;').values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_raise(SendPayment::InsufficientFunds)
      allow(send_payment).to receive(:call)

      repeat_payment = double(RepeatPayment)
      allow(RepeatPayment).to receive(:new).and_return(repeat_payment)
      allow(repeat_payment).to receive(:call)

      described_class.new.call

      expect(RepeatPayment).to have_received(:new).with(id, 100, 1).once
      expect(repeat_payment).to have_received(:call).once
    end
  end

  context 'SendPayment raise FailedRequest' do
    it 'calls LogPayment' do
      Timecop.freeze

      PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
      id = PG_CONN.exec('SELECT id FROM subscriptions;').values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_raise(SendPayment::FailedRequest)
      allow(send_payment).to receive(:call)

      log_payment = double(LogPayment)
      allow(LogPayment).to receive(:new).and_return(log_payment)
      allow(log_payment).to receive(:call)

      described_class.new.call

      expect(LogPayment).to have_received(:new).with(id, 100, 100, 1, Time.now, :failed_request).once
      expect(log_payment).to have_received(:call).once
    end
  end

  context 'SendPayment raise any other error' do
    it 'calls LogPayment' do
      Timecop.freeze

      PG_CONN.exec('INSERT INTO subscriptions (payment_amount) VALUES (100);')
      id = PG_CONN.exec('SELECT id FROM subscriptions;').values.first.first

      PG_CONN.exec("
        INSERT INTO transaction_queue (
          subscription_id, full_payment_amount, payment_amount, attempt, payment_date
        ) VALUES (#{id}, 100, 100, 1, '#{Time.now}');
      ")

      send_payment = double(SendPayment)
      allow(SendPayment).to receive(:new).and_raise(StandardError)
      allow(send_payment).to receive(:call)

      log_payment = double(LogPayment)
      allow(LogPayment).to receive(:new).and_return(log_payment)
      allow(log_payment).to receive(:call)

      described_class.new.call

      expect(LogPayment).to have_received(:new).with(id, 100, 100, 1, Time.now, :error).once
      expect(log_payment).to have_received(:call).once
    end
  end
end
