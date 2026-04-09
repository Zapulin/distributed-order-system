# Consumes ReleaseReservationRequested commands from orders-service
class ReleaseReservationConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload
      order_id = payload["order_id"]

      Rails.logger.info "[ReleaseReservationConsumer] Processing ReleaseReservationRequested for order #{order_id}"

      ReleaseReservation.new.call(order_id)
      EventPublisher.publish_reservation_released(order_id)
      Rails.logger.info "[ReleaseReservationConsumer] Reservation released for order #{order_id}"
    rescue => e
      Rails.logger.error "[ReleaseReservationConsumer] Error for order #{order_id}: #{e.message}"
      raise
    end
  end
end
