class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { "bootstrap.servers": ENV.fetch("KAFKA_BROKERS", "localhost:9092") }
    config.client_id = "payments-service"
    config.logger = Rails.logger
    config.initial_offset = "earliest"
  end

  routes.draw do
    # Commands from orders-service
    topic "process-payment-requested" do
      consumer PaymentCommandsConsumer
    end
  end
end
