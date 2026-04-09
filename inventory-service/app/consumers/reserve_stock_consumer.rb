# Consumes ReserveStockRequested commands from orders-service
class ReserveStockConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload
      order_id = payload["order_id"]
      items = payload["items"]

      Rails.logger.info "[ReserveStockConsumer] Processing ReserveStockRequested for order #{order_id}"

      ReserveStock.new.call(order_id, items)
      EventPublisher.publish_stock_reserved(order_id)
      Rails.logger.info "[ReserveStockConsumer] Stock reserved for order #{order_id}"
    rescue InsufficientStockError => e
      Rails.logger.warn "[ReserveStockConsumer] Reservation failed for order #{order_id}: #{e.message}"
      EventPublisher.publish_stock_reservation_failed(order_id, e.message)
    rescue => e
      Rails.logger.error "[ReserveStockConsumer] Unexpected error for order #{order_id}: #{e.message}"
      raise
    end
  end
end
