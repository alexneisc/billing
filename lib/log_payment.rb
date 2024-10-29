class LogPayment
  def initialize(subscription_id, full_payment_amount, payment_amount, attempt, time, status)
    @subscription_id = subscription_id
    @full_payment_amount = full_payment_amount
    @payment_amount = payment_amount
    @attempt = attempt
    @time = time
    @status = status
  end

  def call
    PG_CONN.exec("
      INSERT INTO payment_logs (subscription_id, full_payment_amount, payment_amount, attempt, time, status)
        VALUES (
          #{@subscription_id}, #{@full_payment_amount}, #{@payment_amount}, #{@attempt}, '#{@time}', '#{@status}'
        );
    ")
  end
end
