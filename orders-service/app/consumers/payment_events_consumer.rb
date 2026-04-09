# Consumes events from payments-service: PaymentSucceeded, PaymentFailed
class PaymentEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload
      event_type = payload["event_type"]
      order_id = payload["order_id"]

      Rails.logger.info "[PaymentEventsConsumer] Received #{event_type} for order #{order_id}"

      orchestrator = SagaOrchestrator.new

      case event_type
      when "PaymentSucceeded"
        orchestrator.handle_payment_succeeded(order_id)
      when "PaymentFailed"
        orchestrator.handle_payment_failed(order_id)
      else
        Rails.logger.warn "[PaymentEventsConsumer] Unknown event type: #{event_type}"
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "[PaymentEventsConsumer] Order not found: #{e.message}"
    end
  end
end
