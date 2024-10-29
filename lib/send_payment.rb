require 'uri'
require 'net/http'

class SendPayment
  class FailedPayment < StandardError; end
  class InsufficientFunds < StandardError; end
  class FailedRequest < StandardError; end

  def initialize(subscription_id, payment_amount)
    @subscription_id = subscription_id
    @payment_amount = payment_amount
  end

  def call
    uri = URI('https://ilikegoodcode.com/paymentIntents/create')
    res = Net::HTTP.post_form(uri, 'amount' => @payment_amount, 'subscription_id' => @subscription_id)

    raise FailedRequest unless res.is_a?(Net::HTTPSuccess)

    status = JSON.parse(res.body)['status']

    raise FailedPayment if status == 'failed'
    raise InsufficientFunds if status == 'insufficient_funds'
  end
end
