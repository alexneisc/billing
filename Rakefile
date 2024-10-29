ENV['DB_NAME'] = 'billing'
Dir['./lib/*.rb'].each {|file| require file }

namespace :transaction_queue do
  task :create do
    CreateTransactionQueue.new.call
  end

  task :process do
    ProcessTransactionQueue.new.call
  end
end
