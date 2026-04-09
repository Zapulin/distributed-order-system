class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { "bootstrap.servers": ENV.fetch("KAFKA_BROKERS", "localhost:9092") }
    config.client_id = "orders-service"
    config.logger = Rails.logger
    config.initial_offset = "earliest"
  end

  routes.draw do
    # Events from inventory-service
    topic "stock-reserved" do
      consumer InventoryEventsConsumer
    end

    topic "stock-reservation-failed" do
      consumer InventoryEventsConsumer
    end

    topic "reservation-released" do
      consumer InventoryEventsConsumer
    end

    topic "reservation-expired" do
      consumer InventoryEventsConsumer
    end

    # Events from payments-service
    topic "payment-succeeded" do
      consumer PaymentEventsConsumer
    end

    topic "payment-failed" do
      consumer PaymentEventsConsumer
    end
  end
end
