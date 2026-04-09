class KarafkaApp < Karafka::App
  setup do |config|
    config.kafka = { "bootstrap.servers": ENV.fetch("KAFKA_BROKERS", "localhost:9092") }
    config.client_id = "inventory-service"
    config.logger = Rails.logger
    config.initial_offset = "earliest"
  end

  routes.draw do
    # Commands from orders-service
    topic "reserve-stock-requested" do
      consumer ReserveStockConsumer
    end

    topic "release-reservation-requested" do
      consumer ReleaseReservationConsumer
    end
  end
end
