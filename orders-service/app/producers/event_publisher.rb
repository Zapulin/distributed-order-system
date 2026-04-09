class EventPublisher
  def self.publish_reserve_stock_requested(order)
    publish("reserve-stock-requested", {
      event_type: "ReserveStockRequested",
      order_id: order.id,
      items: order.order_items.map { |item| { product_id: item.product_id, quantity: item.quantity } }
    }, order.id)
  end

  def self.publish_process_payment_requested(order)
    publish("process-payment-requested", {
      event_type: "ProcessPaymentRequested",
      order_id: order.id,
      amount: order.total_amount.to_f
    }, order.id)
  end

  def self.publish_release_reservation_requested(order)
    publish("release-reservation-requested", {
      event_type: "ReleaseReservationRequested",
      order_id: order.id
    }, order.id)
  end

  def self.publish_order_confirmed(order)
    publish("order-confirmed", {
      event_type: "OrderConfirmed",
      order_id: order.id
    }, order.id)
  end

  def self.publish_order_cancelled(order)
    publish("order-cancelled", {
      event_type: "OrderCancelled",
      order_id: order.id
    }, order.id)
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
