# Consumes ProcessPaymentRequested commands from orders-service
class PaymentCommandsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload
      order_id = payload["order_id"]
      amount = payload["amount"]

      Rails.logger.info "[PaymentCommandsConsumer] Processing ProcessPaymentRequested for order #{order_id}"

      ProcessPayment.new.call(order_id, amount)
    rescue => e
      Rails.logger.error "[PaymentCommandsConsumer] Error for order #{order_id}: #{e.message}"
      raise
    end
  end
end
