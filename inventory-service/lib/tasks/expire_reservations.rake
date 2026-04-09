namespace :reservations do
  desc "Expire pending reservations that have passed their expiry time and publish ReservationExpired events"
  task expire: :environment do
    expired = StockReservation.expired_pending

    if expired.empty?
      Rails.logger.info "[ExpireReservations] No expired reservations found"
      next
    end

    expired.each do |reservation|
      ActiveRecord::Base.transaction do
        stock = ProductStock.lock.find_by!(product_id: reservation.product_id)
        stock.update!(quantity: stock.quantity + reservation.quantity)
        reservation.update!(status: "expired")
      end

      EventPublisher.publish_reservation_expired(reservation.order_id)
      Rails.logger.info "[ExpireReservations] Expired reservation for order #{reservation.order_id} (product: #{reservation.product_id})"
    rescue => e
      Rails.logger.error "[ExpireReservations] Failed to expire reservation #{reservation.id}: #{e.message}"
    end

    Rails.logger.info "[ExpireReservations] Processed #{expired.count} expired reservations"
  end
end
