Dir['./lib/*.rb'].each {|file| require file }

class CreateTransactionQueue
  def call
    PG_CONN.exec('SELECT * FROM subscriptions') do |result|
      result.each do |row|
        subscription_id, payment_amount = row.values_at('id', 'payment_amount')

        PG_CONN.exec("
          INSERT INTO transaction_queue (subscription_id, full_payment_amount, payment_amount, attempt, payment_date)
            VALUES (#{subscription_id}, #{payment_amount}, #{payment_amount}, 1, '#{Time.now}');
        ")
      end
    end
  end
end
