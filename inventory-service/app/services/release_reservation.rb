class ReleaseReservation
  def call(order_id)
    reservations = StockReservation.where(order_id: order_id, status: "pending")

    return if reservations.empty?

    ActiveRecord::Base.transaction do
      reservations.each do |reservation|
        stock = ProductStock.lock.find_by!(product_id: reservation.product_id)
        stock.update!(quantity: stock.quantity + reservation.quantity)
        reservation.update!(status: "released")
      end
    end
  end
end
