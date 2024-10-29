require 'pg'

RSpec.describe SendPayment do
  it 'sends request to external API' do
    stub_request(:post, 'https://ilikegoodcode.com/paymentIntents/create')
      .to_return_json(status: 200, body: {status: 'success'})

    described_class.new(123, 50).call

    expect(
      a_request(:post, 'https://ilikegoodcode.com/paymentIntents/create')
        .with(body: {amount: 50, subscription_id: 123})
    ).to have_been_made.once
  end

  context 'API returns status: :failed' do
    it 'raise FailedPayment' do
      stub_request(:post, 'https://ilikegoodcode.com/paymentIntents/create')
        .to_return_json(status: 200, body: {status: "failed"})

      expect do
        described_class.new(123, 50).call
      end.to raise_error SendPayment::FailedPayment
    end
  end

  context 'API returns status: :insufficient_funds' do
    it 'raise FailedPayment' do
      stub_request(:post, 'https://ilikegoodcode.com/paymentIntents/create')
        .to_return_json(status: 404)

      expect do
        described_class.new(123, 50).call
      end.to raise_error SendPayment::FailedRequest
    end
  end
end
