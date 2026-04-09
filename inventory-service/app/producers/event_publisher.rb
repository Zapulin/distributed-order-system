class EventPublisher
  def self.publish_stock_reserved(order_id)
    publish("stock-reserved", {
      event_type: "StockReserved",
      order_id: order_id
    }, order_id)
  end

  def self.publish_stock_reservation_failed(order_id, reason = nil)
    publish("stock-reservation-failed", {
      event_type: "StockReservationFailed",
      order_id: order_id,
      reason: reason
    }, order_id)
  end

  def self.publish_reservation_released(order_id)
    publish("reservation-released", {
      event_type: "ReservationReleased",
      order_id: order_id
    }, order_id)
  end

  def self.publish_reservation_expired(order_id)
    publish("reservation-expired", {
      event_type: "ReservationExpired",
      order_id: order_id
    }, order_id)
  end

  def self.publish(topic, payload, key)
    Karafka.producer.produce_sync(
      topic: topic,
      payload: payload.merge(timestamp: Time.current.iso8601).to_json,
      key: key.to_s
    )
  end
  private_class_method :publish
end
