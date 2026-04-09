class EventPublisher
  def self.publish_payment_succeeded(order_id, amount)
    publish("payment-succeeded", {
      event_type: "PaymentSucceeded",
      order_id: order_id,
      amount: amount.to_f
    }, order_id)
  end

  def self.publish_payment_failed(order_id)
    publish("payment-failed", {
      event_type: "PaymentFailed",
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
