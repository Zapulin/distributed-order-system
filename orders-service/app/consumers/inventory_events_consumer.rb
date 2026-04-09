# Consumes events from inventory-service: StockReserved, StockReservationFailed, ReservationExpired, ReservationReleased
class InventoryEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload
      event_type = payload["event_type"]
      order_id = payload["order_id"]

      Rails.logger.info "[InventoryEventsConsumer] Received #{event_type} for order #{order_id}"

      orchestrator = SagaOrchestrator.new

      case event_type
      when "StockReserved"
        orchestrator.handle_stock_reserved(order_id)
      when "StockReservationFailed"
        orchestrator.handle_stock_reservation_failed(order_id)
      when "ReservationExpired"
        orchestrator.handle_reservation_expired(order_id)
      when "ReservationReleased"
        Rails.logger.info "[InventoryEventsConsumer] ReservationReleased for order #{order_id} acknowledged"
      else
        Rails.logger.warn "[InventoryEventsConsumer] Unknown event type: #{event_type}"
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "[InventoryEventsConsumer] Order not found: #{e.message}"
    end
  end
end
