# Orchestrates the order Saga by reacting to events from inventory and payment services.
# Decides the next step and applies compensating actions when needed.
class SagaOrchestrator
  def handle_stock_reserved(order_id)
    order = Order.find(order_id)
    return unless order.status == "CREATED"

    order.update!(status: "RESERVED")
    EventPublisher.publish_process_payment_requested(order)
    Rails.logger.info "[Saga] Order #{order_id}: CREATED -> RESERVED, ProcessPaymentRequested published"
  end

  def handle_stock_reservation_failed(order_id)
    order = Order.find(order_id)
    return unless order.status == "CREATED"

    order.update!(status: "CANCELLED")
    EventPublisher.publish_order_cancelled(order)
    Rails.logger.info "[Saga] Order #{order_id}: CREATED -> CANCELLED (stock reservation failed)"
  end

  def handle_payment_succeeded(order_id)
    order = Order.find(order_id)
    return unless order.status == "RESERVED"

    order.update!(status: "CONFIRMED")
    EventPublisher.publish_order_confirmed(order)
    Rails.logger.info "[Saga] Order #{order_id}: RESERVED -> CONFIRMED"
  end

  def handle_payment_failed(order_id)
    order = Order.find(order_id)
    return unless order.status == "RESERVED"

    order.update!(status: "CANCELLED")
    EventPublisher.publish_release_reservation_requested(order)
    EventPublisher.publish_order_cancelled(order)
    Rails.logger.info "[Saga] Order #{order_id}: RESERVED -> CANCELLED (payment failed), ReleaseReservationRequested published"
  end

  def handle_reservation_expired(order_id)
    order = Order.find(order_id)
    return if %w[CONFIRMED CANCELLED].include?(order.status)

    order.update!(status: "CANCELLED")
    EventPublisher.publish_order_cancelled(order)
    Rails.logger.info "[Saga] Order #{order_id}: #{order.status} -> CANCELLED (reservation expired)"
  end
end
