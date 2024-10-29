require 'date'

class ScheduleSuccessfulPayment
  def initialize(subscription_id, full_payment_amount, payment_amount)
    @subscription_id = subscription_id
    @full_payment_amount = full_payment_amount
    @payment_amount = payment_amount
  end

  def call
    new_payment_amount = @full_payment_amount - @payment_amount
    time = Time.now + (7 * 60 * 60 * 24)

    PG_CONN.exec("
      INSERT INTO transaction_queue (subscription_id, full_payment_amount, payment_amount, attempt, payment_date)
        VALUES (#{@subscription_id}, #{@full_payment_amount}, #{new_payment_amount}, 4, '#{time}');
    ")
  end
end
