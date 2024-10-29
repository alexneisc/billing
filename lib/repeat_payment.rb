class RepeatPayment
  def initialize(subscription_id, full_payment_amount, attempt)
    @subscription_id = subscription_id
    @full_payment_amount = full_payment_amount
    @attempt = attempt
  end

  def call
    new_attempt = @attempt + 1

    return if new_attempt > 4

    new_payment_amount = @full_payment_amount + (@full_payment_amount * 0.25) - (25 * new_attempt)

    PG_CONN.exec("
      INSERT INTO transaction_queue (subscription_id, full_payment_amount, payment_amount, attempt, payment_date)
        VALUES (#{@subscription_id}, #{@full_payment_amount}, #{new_payment_amount}, #{new_attempt}, '#{Time.now}');
    ")
  end
end
