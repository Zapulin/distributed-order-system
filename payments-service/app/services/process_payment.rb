# Processes a payment for the given order.
# Simulates success/failure probabilistically for prototype purposes.
class ProcessPayment
  SUCCESS_RATE = 0.8

  def call(order_id, amount)
    # Idempotency: if already processed, re-publish the stored result
    existing = Payment.find_by(order_id: order_id)
    if existing
      Rails.logger.info "[ProcessPayment] Payment already exists for order #{order_id} (status: #{existing.status}), re-publishing result"
      republish_result(existing)
      return existing
    end

    payment = Payment.create!(order_id: order_id, amount: amount, status: "pending")

    if rand < SUCCESS_RATE
      payment.update!(status: "succeeded")
      EventPublisher.publish_payment_succeeded(order_id, amount)
      Rails.logger.info "[ProcessPayment] Payment succeeded for order #{order_id}"
    else
      payment.update!(status: "failed")
      EventPublisher.publish_payment_failed(order_id)
      Rails.logger.info "[ProcessPayment] Payment failed for order #{order_id}"
    end

    payment
  end

  private

  def republish_result(payment)
    if payment.status == "succeeded"
      EventPublisher.publish_payment_succeeded(payment.order_id, payment.amount)
    else
      EventPublisher.publish_payment_failed(payment.order_id)
    end
  end
end
