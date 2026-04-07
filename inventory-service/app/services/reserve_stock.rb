class ReserveStock
  RESERVATION_DURATION = 15.minutes

  def call(order_id, items)
    # Idempotency: if we already have reservations for this order, skip
    if StockReservation.exists?(order_id: order_id)
      Rails.logger.info "[ReserveStock] Reservation already exists for order #{order_id}, skipping"
      return
    end

    ActiveRecord::Base.transaction do
      items.each do |item|
        product_id = item["product_id"]
        quantity = item["quantity"].to_i

        stock = ProductStock.lock.find_by!(product_id: product_id)

        if stock.quantity < quantity
          raise InsufficientStockError, "Insufficient stock for product #{product_id} (available: #{stock.quantity}, requested: #{quantity})"
        end

        stock.update!(quantity: stock.quantity - quantity)

        StockReservation.create!(
          order_id: order_id,
          product_id: product_id,
          quantity: quantity,
          status: "pending",
          expires_at: RESERVATION_DURATION.from_now
        )
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    raise InsufficientStockError, "Product not found: #{e.message}"
  end
end
