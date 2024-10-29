Dir["./lib/*.rb"].each {|file| require file }

class ProcessTransactionQueue
  def call
    query = "
      SELECT id, subscription_id, full_payment_amount, payment_amount, attempt
      FROM transaction_queue
      WHERE payment_date <= '#{Time.now}'
    "

    PG_CONN.exec(query) do |result|
      result.each do |row|
        id, subscription_id, full_payment_amount, payment_amount, attempt =
          row.values_at('id', 'subscription_id', 'full_payment_amount', 'payment_amount', 'attempt')

        begin
          SendPayment.new(subscription_id, payment_amount).call
          ScheduleSuccessfulPayment.new(subscription_id, full_payment_amount, payment_amount).call if attempt > 1
        rescue SendPayment::FailedPayment
          LogPayment.new(
            subscription_id, full_payment_amount, payment_amount, attempt, Time.now, :failed_payment
          ).call
        rescue SendPayment::InsufficientFunds
          LogPayment.new(
            subscription_id, full_payment_amount, payment_amount, attempt, Time.now, :insufficient_funds
          ).call

          RepeatPayment.new(subscription_id, full_payment_amount, attempt).call
        rescue SendPayment::FailedRequest
          LogPayment.new(
            subscription_id, full_payment_amount, payment_amount, attempt, Time.now, :failed_request
          ).call
        rescue
          LogPayment.new(
            subscription_id, full_payment_amount, payment_amount, attempt, Time.now, :error
          ).call
        ensure
          PG_CONN.exec("DELETE FROM transaction_queue WHERE id = #{id};")
        end
      end
    end
  end
end
